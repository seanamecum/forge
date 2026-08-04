import Foundation
import Observation
import SwiftData

enum AppPhase {
    case welcome
    case onboarding
    case main
}

enum MainTab: String, CaseIterable {
    case home, train, coach, fuel, recover

    var label: String {
        switch self {
        case .home: return "Home"
        case .train: return "Train"
        case .coach: return "Coach"
        case .fuel: return "Fuel"
        case .recover: return "Recover"
        }
    }

    var icon: String {
        switch self {
        case .home: return "square.grid.2x2.fill"
        case .train: return "dumbbell.fill"
        case .coach: return "sparkles"
        case .fuel: return "fork.knife"
        case .recover: return "moon.stars.fill"
        }
    }
}

/// App-wide state container. Owns the user, navigation phase, and all services.
@Observable
final class AppState {
    var phase: AppPhase = .welcome
    var selectedTab: MainTab = .home
    var user: UserProfile = MockData.sean {
        didSet { Self.persistUser(user) }
    }

    /// True in demo mode (exploring Sean's world), false for a real account. Drives
    /// whether the demo athlete's seeded training/health data is shown. Persisted;
    /// restored in `init`. Hermetic in tests.
    var isDemoAccount = false {
        didSet {
            nutrition.isDemo = isDemoAccount   // demo interactions must never persist
            guard !PersistenceService.isTestRun else { return }
            UserDefaults.standard.set(isDemoAccount, forKey: Self.demoKey)
        }
    }
    private static let demoKey = "forge.isDemoAccount"

    /// Today's morning check-in, if completed (in-memory; SwiftData holds history).
    /// Applying it lets the check-in drive recovery + the Forge Score when there's
    /// no live wearable data.
    var checkIn: CheckInSnapshot? {
        didSet { recovery.applyCheckIn(checkIn) }
    }

    /// The real account's logged weigh-ins, oldest → newest (empty for a new user).
    /// Demo mode reads the demo athlete's trend instead — see `weightTrend`.
    private(set) var weightSamples: [Double] = []

    /// Weight samples that drive the Body screen + adaptive nutrition. Never mixes
    /// real and demo: the demo athlete's trend in demo mode, the user's own weigh-ins
    /// otherwise.
    var weightTrend: [Double] { isDemoAccount ? MockData.weightTrend : weightSamples }

    /// Most recent weight, or nil when a real user hasn't logged one yet.
    var latestWeight: Double? { weightTrend.last }

    // Services — mock-backed now, swap for networked implementations later.
    let auth = AuthService()
    let healthKit = HealthKitService()
    let workouts = WorkoutService()
    let nutrition = NutritionService()
    let recovery = RecoveryService()
    let injuries = InjuryService()
    let social = SocialService()
    let marketplace = MarketplaceService()
    let notifications = NotificationService()
    let sync = SyncService()

    init() {
        // Restore demo/real mode (skipped in tests for hermeticity).
        if !PersistenceService.isTestRun {
            isDemoAccount = UserDefaults.standard.bool(forKey: Self.demoKey)
        }
        // Restore the saved profile so a returning user never reverts to the demo athlete.
        if let saved = Self.loadUser() { user = saved }
        // Forge speaks imperial — migrate any previously saved metric preference.
        user.usesImperial = true
        // Returning users skip straight to the dashboard.
        if UserDefaults.standard.bool(forKey: "forge.hasOnboarded") {
            phase = .main
        }
        // Demo/screenshot hook (no effect in normal use): FORGE_TAB selects the
        // initial tab; -demoAutoLogin skips straight to the dashboard.
        if CommandLine.arguments.contains("-demoAutoLogin") { phase = .main }
        if let raw = ProcessInfo.processInfo.environment["FORGE_TAB"],
           let tab = MainTab(rawValue: raw) {
            selectedTab = tab
        }
        refreshFuelPlan()
    }

    /// Restore everything the user has actually done from disk — called once
    /// from RootView. Real data replaces demo data; logging then relaunching
    /// must never lose anything.
    @MainActor
    func rehydrate() {
        guard !rehydrated else { return }
        rehydrated = true

        // Wire profile/settings sync to live app state (read + apply).
        sync.profileSnapshot = { [weak self] in self?.profileSnapshotJSON() }
        sync.applyProfileSnapshot = { [weak self] json in self?.applyProfileSnapshot(json) }
        // After a pull restores records (reinstall / second device), rebuild the
        // derived UI so the data shows without an app restart.
        sync.onDidApplyRemoteChanges = { [weak self] in
            guard let self, !self.isDemoAccount else { return }
            self.loadHealthData()
            self.refreshTrends()
        }

        // Today's food + water: real log only. A fresh day starts honestly empty.
        // Migrate any legacy per-serving entries to the grams-aware diary first, then
        // load from it. Demo keeps its seeded entries (never persisted).
        nutrition.waterOz = PersistenceService.loadTodayWater()
        if !isDemoAccount {
            PersistenceService.migrateLegacyNutritionIfNeeded(context: PersistenceService.context)
            nutrition.reloadDiary()
        }

        // Workout history: a real account sees only its own logged sessions; demo
        // mode keeps the demo athlete's baseline (with any saved layered on top).
        let saved = PersistenceService.loadWorkouts()
        if isDemoAccount {
            if !saved.isEmpty {
                workouts.history = (saved + workouts.history).sorted { $0.date > $1.date }
            }
        } else {
            workouts.clearDemoSeed()
            workouts.history = saved.sorted { $0.date > $1.date }
            refreshTrainingBoards()   // PRs + weekly muscle volume from the real log
        }

        // Real training load from logged sessions → strain → Forge Score + Directive.
        applyTrainingLoad()

        // Morning check-in done earlier today survives relaunch.
        checkIn = PersistenceService.loadTodayCheckIn()

        // Real weigh-in history → Body screen + adaptive nutrition (demo uses the
        // demo trend via `weightTrend`).
        if !isDemoAccount { weightSamples = PersistenceService.loadWeights().map(\.weightLb) }

        // Real supplement stack + bloodwork → derived deficiencies (demo keeps Sean's).
        // Injuries: a real account keeps only its own logged/managed set — clear the
        // demo knee, its risk read, and rehab checklist.
        if !isDemoAccount {
            loadHealthData()
            injuries.clearDemoSeed()
            refreshTrends()          // real trend charts from this account's own history
            // On launch, reconcile with the cloud (pull remote edits from other
            // devices, push anything logged offline). No-op without a live session.
            sync.syncNow()
        }

        refreshFuelPlan()
    }
    private var rehydrated = false

    /// Rebuild the recovery/HRV/sleep/strain/Forge-Score trend charts from THIS
    /// account's persisted daily history — so a real user never sees the demo
    /// athlete's trends. Demo mode keeps the seeded trends. Empty history → empty
    /// (honest "building" state), never fabricated.
    @MainActor
    func refreshTrends() {
        guard !isDemoAccount else { recovery.clearLiveTrends(); return }
        let recoveries = PersistenceService.loadRecoveryHistory()
        let sleeps = PersistenceService.loadSleepHistory()
        let scores = PersistenceService.loadScoreHistory()
        recovery.setLiveTrends(TrendBuilder.make(
            recovery: recoveries.map(\.recovery),
            hrv: recoveries.map(\.hrv),
            sleepHours: sleeps.map(\.hours),
            strain: recoveries.map(\.strain),
            scores: scores.map(\.score)))
    }

    // MARK: - Training load → intelligence layer

    /// Push real training strain into today's recovery snapshot so a completed
    /// workout actually moves the Forge Score (Training Load component) and the
    /// Directive — not just the history list. Injectable for tests; the demo/empty
    /// case leaves the seeded values untouched so the demo story stays coherent.
    ///
    /// Residual model: today's sessions set `strainToday` now and become tomorrow's
    /// `strainYesterday` (which drives the score), mirroring how training load flows
    /// into next-day recovery.
    func applyTrainingLoad(sessions: [TrainingSession],
                           calendar: Calendar = .current, now: Date = .now) {
        guard !sessions.isEmpty else { return }
        let today = sessions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now).map { ref in
            sessions.filter { calendar.isDate($0.date, inSameDayAs: ref) }
        } ?? []
        if !today.isEmpty { recovery.today.strainToday = TrainingLoadEngine.dayStrain(today) }
        if !yesterday.isEmpty { recovery.today.strainYesterday = TrainingLoadEngine.dayStrain(yesterday) }
    }

    /// Convenience: pull real logged sessions from persistence and apply.
    @MainActor
    func applyTrainingLoad() {
        let sessions = PersistenceService.loadWorkouts().map {
            TrainingSession(date: $0.date, durationMin: $0.durationMin, avgRPE: $0.avgRPE)
        }
        applyTrainingLoad(sessions: sessions)
    }

    // MARK: - Profile persistence

    private static let userKey = "forge.user.v1"

    private static func persistUser(_ profile: UserProfile) {
        guard !PersistenceService.isTestRun else { return }   // hermetic tests
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private static func loadUser() -> UserProfile? {
        guard !PersistenceService.isTestRun,
              let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    @MainActor
    func completeAuth(demo: Bool) {
        isDemoAccount = demo
        if demo {
            workouts.restoreDemoSeed()   // in case a prior real session cleared it
            nutrition.restoreDemoSeed()
            injuries.restoreDemoSeed()
            recovery.clearLiveTrends()   // demo shows the seeded trends
            user = MockData.sean
            sync.reset()                 // demo mode never syncs to the cloud
            finishOnboarding()
        } else {
            workouts.clearDemoSeed()     // a real account starts with a clean slate
            nutrition.clearDemoSeed()
            injuries.clearDemoSeed()
            weightSamples = []
            refreshTrends()              // this account's own (initially empty) trends
            phase = .onboarding
            // Pull this account's cloud data (restores a reinstall / new device) and
            // push anything logged locally before sign-in.
            sync.syncNow()
        }
    }

    /// Views call this after a local edit to nudge a (debounced) cloud sync.
    nonisolated func requestSync() { sync.requestSync() }

    /// The account's profile + app settings as one syncable document. Nil in demo
    /// mode (nothing leaves the phone).
    @MainActor
    func profileSnapshotJSON() -> String? {
        guard !isDemoAccount else { return nil }
        let snap = ProfileSnapshot(
            profile: user,
            morningDirectiveOn: notifications.morningDirectiveOn,
            smartNudgesOn: notifications.smartNudgesOn,
            directiveHour: notifications.directiveHour,
            directiveMinute: notifications.directiveMinute)
        return ProfileSnapshotCoder.encode(snap)
    }

    /// Apply a profile+settings snapshot pulled from another device.
    @MainActor
    func applyProfileSnapshot(_ json: String) {
        guard let snap = ProfileSnapshotCoder.decode(json) else { return }
        user = snap.profile
        notifications.morningDirectiveOn = snap.morningDirectiveOn
        notifications.smartNudgesOn = snap.smartNudgesOn
        notifications.directiveHour = snap.directiveHour
        notifications.directiveMinute = snap.directiveMinute
    }

    func finishOnboarding() {
        if !PersistenceService.isTestRun { UserDefaults.standard.set(true, forKey: "forge.hasOnboarded") }
        phase = .main
    }

    /// A real athlete starts fresh — strip the demo seed's identity/gamification
    /// so a new user never inherits Sean's streak, level, XP, or sport. Pure.
    static func onboardingProfile(from draft: UserProfile) -> UserProfile {
        var p = draft
        p.streakDays = 0
        p.level = 1
        p.xp = 0
        if p.sport == MockData.sean.sport { p.sport = "" }   // don't inherit "Hockey"
        return p
    }

    /// Commit onboarding: the user's real profile AND their declared injuries
    /// (previously dropped, leaving every new user with the demo knee). Empty
    /// injuries → healthy.
    func commitOnboarding(profile: UserProfile, injuries selected: Set<InjuryType>) {
        isDemoAccount = false
        workouts.clearDemoSeed()          // idempotent — a real user builds their own history
        nutrition.clearDemoSeed()
        weightSamples = []
        user = Self.onboardingProfile(from: profile)
        injuries.setActive(from: selected)
        // A freshly-onboarded real account: push its starting state and pull any
        // data already in the cloud for this user.
        sync.syncNow()
        finishOnboarding()
    }

    func logout() {
        auth.signOut()
        sync.reset()
        UserDefaults.standard.set(false, forKey: "forge.hasOnboarded")
        user = MockData.sean
        selectedTab = .home
        phase = .welcome
    }

    /// Forge Score 0–100 — the weighted blend, delegated to the pure ForgeScoreEngine.
    var forgeScore: Int { ForgeScoreEngine.score(forgeScoreBreakdown) }

    var forgeScoreBreakdown: [ScoreComponent] {
        let d = recovery.today
        let n = nutrition
        return ForgeScoreEngine.breakdown(
            sleep: d.sleepScore, recovery: d.recovery,
            nutrition: n.nutritionScore, hydration: n.hydrationScore,
            trainingLoad: d.trainingLoadScore, activity: d.activityScore,
            stress: d.stressScore, injury: injuries.injuryStatusScore)
    }

    /// Plain-language explanation of what's raising and lowering the score today.
    var forgeScoreNarrative: String { ForgeScoreEngine.narrative(forgeScoreBreakdown) }

    /// Why the score moved — signed contributors, so the number feels alive.
    /// Positives blend day-over-day trend movement with today's strong components;
    /// negatives surface the components actively dragging the score down.
    var forgeScoreChanges: [ScoreChange] {
        var out: [ScoreChange] = []

        func dayMove(_ name: String) -> Double? {
            let s = recovery.series(name)
            guard s.count >= 2 else { return nil }
            return s[s.count - 1] - s[s.count - 2]
        }
        if let r = dayMove("Recovery") {
            if r >= 1.5 { out.append(ScoreChange(text: "Recovery improved", positive: true)) }
            else if r <= -1.5 { out.append(ScoreChange(text: "Recovery dipped", positive: false)) }
        }
        if let s = dayMove("Sleep") {
            if s >= 0.2 { out.append(ScoreChange(text: "Better sleep last night", positive: true)) }
            else if s <= -0.2 { out.append(ScoreChange(text: "Shorter sleep last night", positive: false)) }
        }

        // Components actively dragging the score (lowest two under 65).
        for c in forgeScoreBreakdown.sorted(by: { $0.value < $1.value }).prefix(2) where c.value < 65 {
            out.append(ScoreChange(text: "\(c.label) low (\(c.value))", positive: false))
        }
        // Guarantee at least one positive anchor — the strongest component.
        if !out.contains(where: { $0.positive }),
           let top = forgeScoreBreakdown.max(by: { $0.value < $1.value }) {
            out.append(ScoreChange(text: "\(top.label) strong (\(top.value))", positive: true))
        }
        return out
    }

    /// The single component where the most points are recoverable — what to fix first.
    var forgeScoreLever: String { ForgeScoreEngine.lever(forgeScoreBreakdown) }

    /// The transparency contract behind today's Forge Score — inputs used, what's
    /// missing, confidence, freshness, and the safe fallback. Surfaced in the UI so
    /// the number is never opaque.
    var forgeScoreBasis: RecommendationBasis {
        let used = forgeScoreBreakdown.map { "\($0.label) \($0.value)" }
        var missing: [String] = []
        // Forge works fully without a wearable — the morning check-in is the primary
        // way to personalize the score, so it leads; a wearable is an optional
        // enhancement that adds automatic HRV/sleep/activity.
        if checkIn == nil { missing.append("Your morning check-in (no wearable needed)") }
        switch recovery.provenance {
        case .demo:
            missing.append("Automatic HRV, sleep & activity from a wearable (optional)")
        case .partial:
            if !recovery.recoveryFromLiveSignals { missing.append("Automatic HRV recovery from a wearable (optional)") }
        case .live:
            break
        }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A fresh HRV reading (last sample ~\(Int(hrvAge))h old)")
        }

        let fallback: String?
        switch recovery.provenance {
        case .live:
            fallback = nil
        case .partial:
            fallback = recovery.recoveryFromLiveSignals ? nil
                : "Running on your morning check-in and logged training, nutrition, and weight. Add a wearable for automatic HRV & sleep."
        case .demo:
            fallback = "Do your morning check-in to personalize your score — no wearable needed. A wearable later adds automatic HRV, sleep, and activity."
        }
        return RecommendationBasis(
            summary: forgeScoreNarrative, inputsUsed: used, inputsMissing: missing,
            confidence: RecommendationBasis.confidence(provenance: recovery.provenance, hasCheckIn: checkIn != nil),
            asOf: .now, safeFallback: fallback)
    }

    /// The transparency contract behind today's Directive.
    var directiveBasis: RecommendationBasis {
        let d = recovery.today
        var used: [String] = ["Recovery \(d.recovery)"]
        if d.sleepDebtHours > 0 { used.append("Sleep debt \(String(format: "%.1f", d.sleepDebtHours))h") }
        if nutrition.proteinRemaining > 0 { used.append("Protein \(nutrition.proteinRemaining)g to go") }
        used.append("Hydration \(nutrition.hydrationPct)%")
        if d.strainYesterday > 0 { used.append("Training load \(Int(d.strainYesterday.rounded()))/21") }
        if let injury = injuries.active.first {
            used.append("\(injury.type.rawValue) injury (pain \(injury.painToday)/10)")
        }
        if let soreness = checkIn?.soreness { used.append("Soreness \(soreness)/10") }

        var missing: [String] = []
        if checkIn == nil { missing.append("Morning check-in (soreness, energy, stress)") }
        if recovery.provenance == .demo { missing.append("Automatic recovery & sleep from a wearable (optional)") }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A fresh HRV reading (last sample ~\(Int(hrvAge))h old)")
        }

        let fallback: String?
        if checkIn == nil {
            fallback = "Do your morning check-in — log soreness and energy to sharpen today's call. No wearable needed."
        } else {
            fallback = nil   // a check-in personalizes the directive; a wearable only adds automation
        }
        return RecommendationBasis(
            summary: dailyDirective.rationale, inputsUsed: used, inputsMissing: missing,
            confidence: RecommendationBasis.confidence(provenance: recovery.provenance, hasCheckIn: checkIn != nil),
            asOf: .now, safeFallback: fallback)
    }

    /// The transparency contract behind today's recovery estimate.
    var recoveryBasis: RecommendationBasis {
        let d = recovery.today
        let used = [
            "HRV \(d.hrv) ms (baseline \(d.hrvBaseline))",
            "Resting HR \(d.restingHR) bpm",
            "Sleep \(String(format: "%.1f", d.sleep.hours)) h",
            "Sleep debt \(String(format: "%.1f", d.sleepDebtHours)) h",
        ]
        var missing: [String] = []
        if recovery.provenance == .demo {
            missing.append("Your morning check-in (no wearable needed)")
            missing.append("Automatic HRV, resting HR & sleep from a wearable (optional)")
        } else if !recovery.recoveryFromLiveSignals {
            missing.append("Automatic HRV recovery from a wearable (optional)")
        }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A current HRV sample (last one ~\(Int(hrvAge))h old)")
        }
        // Two paths: HRV from a wearable, OR the morning check-in. Only the truly
        // no-input state is unpersonalized — and even then the fix is the check-in.
        let summary: String
        let fallback: String?
        if recovery.recoveryFromLiveSignals {
            summary = "Recovery \(d.recovery), derived from your HRV vs baseline, resting HR, and sleep."
            fallback = nil
        } else if recovery.recoveryFromCheckIn {
            summary = "Recovery \(d.recovery), from your morning check-in. Add a wearable for automatic HRV-based recovery."
            fallback = nil
        } else {
            summary = "Recovery \(d.recovery) is a starting estimate — do your morning check-in to personalize it. No wearable needed."
            fallback = "Recovery isn't personalized yet. Your morning check-in sets it from your own sleep, soreness, energy, and stress; a wearable later makes it automatic."
        }
        return RecommendationBasis(
            summary: summary, inputsUsed: used, inputsMissing: missing,
            confidence: RecommendationBasis.confidence(provenance: recovery.provenance, hasCheckIn: checkIn != nil),
            asOf: .now, safeFallback: fallback)
    }

    /// The transparency contract behind today's coached fuel targets.
    var nutritionBasis: RecommendationBasis {
        let n = nutrition
        var used = [
            "Bodyweight \(Int(user.weightLb)) lb",
            "Activity \(user.activityLevel.rawValue)",
            "Goal \(user.primaryGoal.rawValue)",
        ]
        if !n.entries.isEmpty { used.append("Logged today: \(n.calories) kcal · \(n.protein) g protein") }
        for adj in (n.activePlan?.adjustments ?? []) { used.append(adj.reason) }

        var missing: [String] = []
        if n.entries.isEmpty { missing.append("Today's logged meals (to track against the target)") }
        // Weight-trend coaching needs ~2 weeks of real weigh-ins. Be honest about
        // whether it's running on the user's data, the demo trend, or not yet enough.
        if isDemoAccount {
            if n.activePlan?.isAdjusted == true { missing.append("Real weigh-in history (demo weight trend)") }
        } else if weightSamples.count < 10 {
            missing.append("A few more weigh-ins to enable weight-trend coaching (\(weightSamples.count)/10)")
        }

        let confidence: RecommendationBasis.Confidence = n.entries.isEmpty ? .moderate : .high
        let fallback = n.entries.isEmpty
            ? "Targets come from your profile; log meals so Forge can coach what's left today."
            : nil
        let summary = n.activePlan?.adjustments.first?.reason
            ?? "Fuel targets derived from your bodyweight, activity, and goal."
        return RecommendationBasis(
            summary: summary, inputsUsed: used, inputsMissing: missing,
            confidence: confidence, asOf: .now, safeFallback: fallback)
    }

    /// Today's generated session — built from THIS athlete's goal, equipment,
    /// live recovery, and active injuries (not a canned demo plan). The workout
    /// generator stays a pure engine; this is where its live inputs come from.
    var todaysPlan: GeneratedWorkout {
        workouts.generate(
            goal: user.primaryGoal,
            minutes: 60,
            equipment: user.equipment.first ?? .fullGym,
            recovery: recovery.today.recovery,
            injuries: injuries.active.map(\.type),
            level: user.fitnessLevel,
            recentStrain: recovery.today.strainYesterday,
            strainBaseline: recovery.strainBaseline)
    }

    /// Today's directive — the full prescribed plan, synthesized by DirectiveEngine
    /// from every live signal. This is the single source the dashboard AND the coach read.
    var dailyDirective: DailyDirective {
        let d = recovery.today
        let injury = injuries.active.first
        return DirectiveEngine.make(
            recovery: d.recovery,
            sleepDebtHours: d.sleepDebtHours,
            proteinRemaining: nutrition.proteinRemaining,
            hydrationPct: nutrition.hydrationPct,
            injuryRiskPercent: injuries.risk.percent,
            injuryRiskBand: injuries.risk.band,
            activeInjuryName: injury?.type.rawValue,
            activeInjuryPain: injury?.painToday,
            // Cheap name lookup — the Directive doesn't need a full generate() here.
            workoutName: workouts.workoutName(goal: user.primaryGoal, injuries: injuries.active.map(\.type)),
            soreness: checkIn?.soreness,
            trainingLoadYesterday: d.strainYesterday,
            trainingLoadAvg: recovery.strainBaseline,
            calorieTarget: nutrition.calorieTarget,
            proteinTarget: nutrition.proteinTarget,
            mobilityMinutes: injury != nil ? 20 : 12,
            rehabPlanSummary: injuryRehabPlan?.summary,
            keySupplement: keySupplementTonight,
            sleepTargetHours: 8.0 + min(d.sleepDebtHours * 0.08, 1.0)
        )
    }

    /// Recompute the coached fuel plan from live cross-module signals.
    /// MacroFactor-style adaptivity, Forge-style integration: training load,
    /// weight trend, recovery, and injuries move the targets — with reasons.
    func refreshFuelPlan() {
        let strain = recovery.series("Strain")
        let strainAvg7 = strain.suffix(7).isEmpty ? 0
            : strain.suffix(7).reduce(0, +) / Double(strain.suffix(7).count)
        nutrition.activePlan = AdaptiveNutritionEngine.plan(.init(
            baseCalories: user.calorieTarget,
            baseProtein: user.proteinTarget,
            baseWaterOz: user.waterTargetOz,
            baseFat: user.fatTarget,
            goal: user.primaryGoal,
            weightTrend: weightTrend,          // the user's own weigh-ins (or demo trend)
            strainAvg7: strainAvg7,
            recoveryToday: recovery.today.recovery,
            injuryActive: !injuries.active.isEmpty,
            enduranceTomorrow: user.primaryGoal == .endurance))
    }

    /// Log a weigh-in: persists it, updates the current weight (so calorie/protein
    /// targets re-scale), and re-runs the adaptive fuel plan against the real trend.
    @MainActor
    func logWeight(_ pounds: Double, context: ModelContext) {
        guard pounds > 0 else { return }
        // Demo mode updates the in-memory profile only — never persists/syncs, so a
        // demo weigh-in can't leak into a real account's cloud data.
        guard !isDemoAccount else {
            user.weightLb = pounds
            refreshFuelPlan()
            return
        }
        PersistenceService.saveWeight(pounds, context: context)
        weightSamples.append(pounds)
        user.weightLb = pounds
        refreshFuelPlan()
        sync.requestSync()
    }

    // MARK: - Supplements + bloodwork (real, persisted; demo keeps Sean's)

    /// Rebuild the in-memory stack + bloodwork from persistence and derive
    /// deficiencies from the user's real labs. Real accounts only.
    @MainActor
    func loadHealthData() {
        nutrition.supplements = PersistenceService.loadSupplements().map { r in
            Supplement(name: r.name, dose: r.dose, timing: r.timing, benefit: r.benefit,
                       streak: r.streak,
                       loggedToday: r.lastLoggedDate.map { Calendar.current.isDateInToday($0) } ?? false)
        }
        nutrition.bloodwork = PersistenceService.loadBloodwork().map { r in
            BloodworkMarker(name: r.name,
                            category: BloodworkMarker.Category(rawValue: r.category) ?? .metabolic,
                            value: r.value, unit: r.unit,
                            normalLow: r.normalLow, normalHigh: r.normalHigh,
                            optimalLow: r.optimalLow, optimalHigh: r.optimalHigh,
                            takenAt: r.date.formatted(date: .abbreviated, time: .omitted), aiNote: "")
        }
        nutrition.deficiencies = DeficiencyEngine.detect(bloodwork: nutrition.bloodwork)
    }

    @MainActor
    func addSupplement(name: String, dose: String, timing: String, benefit: String, context: ModelContext) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        // Demo mode never touches persistence — it mutates Sean's in-memory stack so
        // the demo stays self-contained and a real user's store stays untouched.
        if isDemoAccount {
            nutrition.supplements.append(
                Supplement(name: clean, dose: dose, timing: timing, benefit: benefit, streak: 0, loggedToday: false))
            return
        }
        PersistenceService.insertSupplement(
            SupplementRecord(name: clean, dose: dose, timing: timing, benefit: benefit), context: context)
        loadHealthData()
        sync.requestSync()
    }

    @MainActor
    func removeSupplement(_ supplement: Supplement, context: ModelContext) {
        if isDemoAccount {
            nutrition.supplements.removeAll { $0.id == supplement.id }
            return
        }
        PersistenceService.deleteSupplement(named: supplement.name, context: context)
        loadHealthData()
        sync.requestSync()
    }

    @MainActor
    func toggleSupplement(_ supplement: Supplement, context: ModelContext) {
        guard let idx = nutrition.supplements.firstIndex(where: { $0.id == supplement.id }) else { return }
        let nowLogged = !nutrition.supplements[idx].loggedToday
        nutrition.supplements[idx].loggedToday = nowLogged
        nutrition.supplements[idx].streak = max(0, nutrition.supplements[idx].streak + (nowLogged ? 1 : -1))
        if !isDemoAccount {
            PersistenceService.updateSupplement(named: supplement.name,
                streak: nutrition.supplements[idx].streak,
                lastLogged: nowLogged ? .now : nil, context: context)
            sync.requestSync()
        }
    }

    @MainActor
    func addBloodwork(_ entry: BloodworkCatalogEntry, value: Double, context: ModelContext) {
        guard value > 0 else { return }
        if isDemoAccount {
            nutrition.bloodwork.append(entry.marker(value: value, takenAt: "Today"))
            nutrition.deficiencies = DeficiencyEngine.detect(bloodwork: nutrition.bloodwork)
            return
        }
        PersistenceService.insertBloodwork(
            BloodworkRecord(name: entry.name, category: entry.category.rawValue, value: value, unit: entry.unit,
                            normalLow: entry.normalLow, normalHigh: entry.normalHigh,
                            optimalLow: entry.optimalLow, optimalHigh: entry.optimalHigh),
            context: context)
        loadHealthData()
        sync.requestSync()
    }

    // MARK: - Diary editing (Phase 1.4 — edit / duplicate / move / delete)

    /// The persisted diary entry backing a displayed row (nil for demo/optimistic).
    @MainActor
    func diaryEntry(for fe: FoodEntry) -> DiaryEntry? {
        let id = DiaryBridge.diaryID(for: fe)
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == id })
        return try? PersistenceService.context.fetch(d).first
    }

    /// Build the editor engine for a row: rich (units + grams) when the entry has a
    /// gram basis, else nil so the caller uses honest multiplier editing.
    @MainActor
    func quantityEditor(for fe: FoodEntry) -> QuantityEditorEngine? {
        guard let d = diaryEntry(for: fe), let food = CanonicalFood(editableFrom: d) else { return nil }
        return QuantityEditorEngine(food: food, amount: d.amount, unitID: d.unitID)
    }

    /// Write an editor's quantity back to the diary (real accounts). Remembers the
    /// amount+unit for that food so it pre-fills next time.
    @MainActor
    func applyQuantityEdit(_ fe: FoodEntry, engine: QuantityEditorEngine) {
        guard !isDemoAccount, let consumed = engine.nutrients else { return }
        PersistenceService.updateDiaryQuantity(
            entryID: DiaryBridge.diaryID(for: fe), amount: engine.amount, unitID: engine.unitID,
            unitLabel: engine.unit.label, grams: engine.grams, gramSource: engine.unit.source.rawValue,
            consumed: consumed, context: PersistenceService.context)
        FoodQuantityMemory().remember(foodID: engine.food.id, amount: engine.amount, unitID: engine.unitID)
        nutrition.reloadDiary(); sync.requestSync()
    }

    /// Multiplier edit for a basis-less entry (no gram data): scale by a new amount.
    @MainActor
    func applyMultiplierEdit(_ fe: FoodEntry, newAmount: Double) {
        guard !isDemoAccount, newAmount > 0 else { return }
        PersistenceService.updateDiaryQuantity(entryID: DiaryBridge.diaryID(for: fe),
                                               newAmount: newAmount, context: PersistenceService.context)
        nutrition.reloadDiary(); sync.requestSync()
    }

    @MainActor
    func duplicateDiaryEntry(_ fe: FoodEntry, toMeal meal: MealType? = nil) {
        guard !isDemoAccount else {
            let copy = FoodEntry(meal: meal ?? fe.meal, food: fe.food, servings: fe.servings, time: "Now")
            nutrition.entries.append(copy); return
        }
        PersistenceService.duplicateDiaryEntry(entryID: DiaryBridge.diaryID(for: fe),
                                               toMeal: meal?.rawValue, context: PersistenceService.context)
        nutrition.reloadDiary(); sync.requestSync()
    }

    @MainActor
    func moveDiaryEntry(_ fe: FoodEntry, toMeal meal: MealType) {
        guard fe.meal != meal else { return }
        guard !isDemoAccount else {
            if let i = nutrition.entries.firstIndex(where: { $0.id == fe.id }) {
                nutrition.entries[i] = FoodEntry(meal: meal, food: fe.food, servings: fe.servings, time: fe.time)
            }
            return
        }
        PersistenceService.moveDiaryEntry(entryID: DiaryBridge.diaryID(for: fe), toMeal: meal.rawValue,
                                          context: PersistenceService.context)
        nutrition.reloadDiary(); sync.requestSync()
    }

    // MARK: - Federated food search (Phase 2.2c)

    /// Local-first federated search: the curated common foods (instant/offline) +
    /// Open Food Facts (global). Merged/deduped/ranked by the pipeline, biased toward
    /// the user's own foods via personal signals.
    private var foodProviders: [any FoodSearchProvider] { [LocalFoodProvider(), OpenFoodFactsProvider()] }

    /// Search foods for the unified search UI. Local results stream instantly; OFF
    /// fills gaps. Ranked so the right food is usually first.
    @MainActor
    func searchFoods(_ query: String, limit: Int = 25) async -> [CanonicalFood] {
        let service = FoodSearchService(providers: foodProviders, personal: foodPersonalSignals())
        return await service.search(query, limit: limit)
    }

    /// Instant local-only results (no await on the network) — for the first keystrokes.
    @MainActor
    func localFoodResults(_ query: String, limit: Int = 25) -> [CanonicalFood] {
        let candidates = CommonFoods.all.filter {
            FoodRelevance.norm(query).isEmpty || FoodRelevance.score(query: query, name: $0.name, brand: $0.brand) > 0
        }
        return FoodSearchPipeline.process(candidates, query: query, personal: foodPersonalSignals(), limit: limit)
    }

    /// Barcode → canonical food (global). nil when not found.
    func lookupBarcode(_ barcode: String) async -> CanonicalFood? {
        await FoodSearchService(providers: foodProviders).lookup(barcode: barcode)
    }

    /// A sensible default quantity for one-tap logging — the user's remembered serving
    /// for this food (so it "already knows"), else one natural portion, else 100 g.
    func defaultQuantity(for food: CanonicalFood) -> FoodQuantity {
        if let last = FoodQuantityMemory().last(foodID: food.id), food.unit(id: last.unitID) != nil {
            return FoodQuantity(amount: last.amount, unitID: last.unitID)
        }
        let unit = food.defaultUnit
        return unit.kind == .mass ? FoodQuantity(amount: 100, unitID: "g")
                                  : FoodQuantity(amount: 1, unitID: unit.id)
    }

    /// Log a searched food at a chosen quantity into a meal (the production logging
    /// path — grams-canonical, rich re-editing). Real accounts persist + sync; demo
    /// appends in-memory only. Returns the entry id so a single tap can be undone.
    @discardableResult
    @MainActor
    func logFood(_ food: CanonicalFood, quantity: FoodQuantity, meal: MealType) -> String? {
        guard let entry = DiaryEntry.log(food: food, quantity: quantity, meal: meal, at: .now) else { return nil }
        if isDemoAccount {
            if let fe = DiaryBridge.foodEntry(from: entry) { nutrition.entries.append(fe) }
            return entry.entryID
        }
        PersistenceService.insertDiaryEntry(entry, context: PersistenceService.context)
        FoodQuantityMemory().remember(foodID: food.id, amount: quantity.amount, unitID: quantity.unitID)
        nutrition.reloadDiary()
        sync.requestSync()
        return entry.entryID
    }

    /// Undo a just-logged food (delete the entry). Real accounts remove + sync; demo
    /// removes the in-memory row.
    @MainActor
    func undoFoodLog(entryID: String) {
        guard !isDemoAccount else {
            nutrition.entries.removeAll { DiaryBridge.diaryID(for: $0) == entryID }
            return
        }
        PersistenceService.deleteDiaryEntry(entryID: entryID, context: PersistenceService.context)
        nutrition.reloadDiary()
        sync.requestSync()
    }

    // MARK: - Ambient intelligence (surface the right thing, calmly)

    private let dismissalStore = DismissalStore()

    /// The one or two calm, explainable insights worth surfacing right now — the
    /// visible face of the unified model. Assembled from real current state across
    /// domains, then curated (top-N, confidence-gated, dismissed ones suppressed).
    @MainActor
    func ambientInsights(surface: InsightSurface = .home, now: Date = .now) -> [AmbientInsight] {
        var candidates: [AmbientInsight] = []

        // "Log your usual …" (real accounts only; nutrition's meal memory).
        for s in mealSuggestions(for: nil, now: now).prefix(1) {
            var i = s.asAmbientInsight(); i.surface = surface; candidates.append(i)
        }
        // Protein still to go today (from live targets).
        if let i = InsightGenerators.proteinShort(remaining: nutrition.proteinRemaining, target: nutrition.proteinTarget) {
            candidates.append(i)
        }
        // Recovery below the user's own usual (real accounts with enough history).
        // Prefer the cross-domain *causal* explanation (the brain connecting sleep +
        // training + recovery); fall back to the single-domain note when no real
        // driver is present.
        if !isDemoAccount {
            let usual = usualRecovery()
            let today = recovery.today.recovery
            let sleep = PersistenceService.loadSleepHistory(days: 10).map(\.hours)
            let (thisWeek, priorWeek) = weeklyTrainingVolumes()
            if let i = CrossDomainInsights.recoveryDriver(recoveryToday: today, usual: usual,
                                                          sleepHours: sleep,
                                                          volumeThisWeek: thisWeek, volumePriorWeek: priorWeek) {
                candidates.append(i)
            } else if let i = InsightGenerators.recoveryVsNormal(today: today, usual: usual) {
                candidates.append(i)
            }
        }

        return InsightCurator.curate(candidates, now: now, dismissed: dismissalStore.load(),
                                     policy: .standard(for: surface))
    }

    /// Recompute the PR board and weekly muscle-volume board from real logged
    /// sessions. Real accounts only — demo keeps its seeded boards. Without this a
    /// real user's PR/volume cards sit permanently empty (they were demo-seeded).
    @MainActor
    func refreshTrainingBoards() {
        guard !isDemoAccount else { return }
        workouts.personalRecords = TrainingAnalyticsEngine.personalRecords(from: workouts.history)
        workouts.muscleVolume = TrainingAnalyticsEngine.muscleVolume(from: workouts.history)
    }

    /// Recompute the Micronutrients screen from the last 7 days of real logged
    /// intake (7-day-average coverage vs. reference Daily Values). Real accounts
    /// only — demo keeps its seeded groups. Honest: only nutrients the logged foods
    /// actually carry are shown.
    @MainActor
    func refreshMicronutrients() {
        guard !isDemoAccount else { return }
        let history = PersistenceService.loadDiaryHistory(days: 7)
        let cal = Calendar.current
        let daysLogged = Set(history.map { cal.startOfDay(for: $0.day) }).count
        let total = NutrientVector.total(history.map(\.consumed))
        nutrition.nutrientGroups = MicronutrientEngine.groups(totalConsumed: total, daysLogged: daysLogged)
    }

    /// Total training volume (lb) for the trailing 7 days and the 7 days before that —
    /// the input to cross-domain load-vs-recovery insights. Real logged workouts only.
    @MainActor
    private func weeklyTrainingVolumes(now: Date = .now) -> (thisWeek: Double, priorWeek: Double) {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now) ?? now
        var thisWeek = 0.0, priorWeek = 0.0
        for w in workouts.history {
            if w.date >= weekAgo { thisWeek += w.totalVolumeLb }
            else if w.date >= twoWeeksAgo { priorWeek += w.totalVolumeLb }
        }
        return (thisWeek, priorWeek)
    }

    /// Dismiss an ambient insight — it goes quiet (persisted, so it stays quiet).
    func dismissInsight(id: String) { dismissalStore.recordDismissal(id) }

    /// The account's usual recovery (average of recent history), or 0 when too new.
    @MainActor
    private func usualRecovery() -> Int {
        let recs = PersistenceService.loadRecoveryHistory().map(\.recovery)
        guard recs.count >= 5 else { return 0 }
        return Int((Double(recs.reduce(0, +)) / Double(recs.count)).rounded())
    }

    // MARK: - Smart Meal Memory & personalization (Phase 2.2)

    /// This account's recent diary as personalization signals (real accounts only —
    /// demo never learns real personalization).
    @MainActor
    func diaryHistoryLogs() -> [LoggedFood] {
        guard !isDemoAccount else { return [] }
        return PersistenceService.loadDiaryHistory().map(LoggedFood.init(entry:))
    }

    /// Complete meals Forge has learned this account eats repeatedly.
    @MainActor
    func rememberedMeals(now: Date = .now) -> [RememberedMeal] {
        MealMemory.rememberedMeals(from: diaryHistoryLogs(), now: now)
    }

    /// Proactive "Log your usual …" suggestions for the current moment / meal section,
    /// partial-match aware and suppressing anything already fully logged today.
    @MainActor
    func mealSuggestions(for meal: MealType? = nil, now: Date = .now) -> [MealSuggestion] {
        guard !isDemoAccount else { return [] }
        let today = PersistenceService.loadTodayDiary()
        let logged = Set(today.filter { meal == nil || $0.meal == meal!.rawValue }.map(\.foodID))
        let ctx = SuggestionContext(now: now, meal: meal, alreadyLoggedFoodIDs: logged)
        return MealSuggester.suggestions(remembered: rememberedMeals(now: now), context: ctx)
    }

    /// One tap logs a remembered meal — re-logs each food from the user's most recent
    /// version of it (its nutrition, their usual serving), into today's meal.
    @MainActor
    func logRememberedMeal(_ suggestion: MealSuggestion, into meal: MealType) {
        guard !isDemoAccount else { return }
        for item in suggestion.itemsToLog {
            guard let latest = PersistenceService.latestDiaryEntry(foodID: item.foodID) else { continue }
            PersistenceService.duplicateDiaryEntry(entryID: latest.entryID, toMeal: meal.rawValue,
                                                   context: PersistenceService.context)
        }
        nutrition.reloadDiary()
        sync.requestSync()
    }

    /// Most-recently logged distinct foods (for the search "Recents" row).
    @MainActor
    func recentLoggedFoods(limit: Int = 12) -> [MealMemory.FoodFrequency] {
        guard !isDemoAccount else { return [] }
        return MealMemory.recentFoods(from: diaryHistoryLogs(), limit: limit)
    }

    /// Most-frequently logged foods (the "Frequently eaten" row).
    @MainActor
    func frequentLoggedFoods(limit: Int = 12) -> [MealMemory.FoodFrequency] {
        guard !isDemoAccount else { return [] }
        return Array(MealMemory.frequentFoods(from: diaryHistoryLogs(), now: .now).prefix(limit))
    }

    /// One-tap re-log of a recent/frequent food — clones the user's most recent
    /// version (their usual serving + nutrition) into the meal.
    @MainActor
    func logRecentFood(foodID: String, into meal: MealType) {
        guard !isDemoAccount, let latest = PersistenceService.latestDiaryEntry(foodID: foodID) else { return }
        PersistenceService.duplicateDiaryEntry(entryID: latest.entryID, toMeal: meal.rawValue,
                                               context: PersistenceService.context)
        nutrition.reloadDiary()
        sync.requestSync()
    }

    /// Personalization signals that bias food-search ranking toward the user's own
    /// foods (frequency + recents now; favorites when that entity lands).
    @MainActor
    func foodPersonalSignals(now: Date = .now) -> PersonalSignals {
        guard !isDemoAccount else { return .none }
        let logs = diaryHistoryLogs()
        var signals = PersonalSignals()
        signals.frequency = Dictionary(uniqueKeysWithValues:
            MealMemory.frequentFoods(from: logs, now: now).map { ($0.foodID, $0.count) })
        signals.recentFoodIDs = MealMemory.recentFoods(from: logs).map(\.foodID)
        return signals
    }

    /// Publish today's directive to the home-screen widget's shared container
    /// and push it to the paired Apple Watch.
    func publishWidgetSnapshot() {
        let d = dailyDirective
        let snapshot = WidgetSnapshot(
            forgeScore: forgeScore,
            headline: d.headline,
            priority: d.priorityAction,
            rows: d.actions.prefix(3).map {
                WidgetSnapshot.Row(icon: $0.icon, label: $0.label, value: $0.value)
            },
            generatedAt: .now)
        WidgetBridge.save(snapshot)
        PhoneWatchSync.shared.push(snapshot)
    }

    // MARK: - Connected ecosystem

    /// Which unified data sources currently feed Forge.
    var connectedSources: Set<DataSource> { recovery.connectedSources }

    /// Feed real HealthKit values into the unified stream as Apple Watch readings.
    /// From here the DataHub's priority/preference rules decide whether they win —
    /// live data enters the same pipeline as every other source, never a side door.
    @MainActor
    func ingestHealthKitSignals() {
        guard healthKit.authState == .authorized, !healthKit.usingMockData else { return }
        // Personal baselines first, so the recovery re-derivation inside
        // updateReading uses the athlete's OWN HRV baseline / sleep debt instead of
        // the demo athlete's seeded values. Only overwrite when real history exists.
        if let baseline = healthKit.hrvBaselineLive { recovery.today.hrvBaseline = baseline }
        if let debt = healthKit.sleepDebtLive { recovery.today.sleepDebtHours = debt }

        // Pass each sample's real age so a stale HRV/HR no longer reads as current.
        // Steps & energy are same-day sums (inherently fresh → age 0).
        func age(_ kind: MetricKind) -> Double { healthKit.ageHours(for: kind) ?? 0 }
        recovery.updateReading(.sleep, value: healthKit.sleepHoursLastNight, unit: "h", source: .appleWatch, ageHours: age(.sleep))
        recovery.updateReading(.hrv, value: Double(healthKit.hrvMs), unit: "ms", source: .appleWatch, ageHours: age(.hrv))
        recovery.updateReading(.restingHR, value: Double(healthKit.restingHeartRate), unit: "bpm", source: .appleWatch, ageHours: age(.restingHR))
        recovery.updateReading(.heartRate, value: Double(healthKit.heartRate), unit: "bpm", source: .appleWatch, ageHours: age(.heartRate))
        recovery.updateReading(.steps, value: Double(healthKit.steps), unit: "", source: .appleWatch)
        recovery.updateReading(.calories, value: Double(healthKit.activeEnergy), unit: "kcal", source: .appleWatch)

        // Persist today's real recovery + sleep snapshot so it survives relaunch and
        // syncs across devices (real accounts only; demo never persists Health data).
        if !isDemoAccount { persistTodayHealthSnapshot() }
    }

    /// Upsert today's recovery + sleep record from the live snapshot, then nudge a
    /// sync. Keyed by calendar day so re-ingesting during the day updates one row.
    @MainActor
    private func persistTodayHealthSnapshot() {
        let d = recovery.today
        PersistenceService.upsertRecoveryRecord(
            recovery: d.recovery, hrv: d.hrv, restingHR: d.restingHR, strain: d.strainYesterday,
            context: PersistenceService.context)
        PersistenceService.upsertSleepRecord(
            hours: d.sleep.hours, deepHours: d.sleep.deepHours, remHours: d.sleep.remHours,
            score: d.sleep.score, context: PersistenceService.context)
        refreshTrends()          // today's new snapshot flows into the trend charts
        sync.requestSync()
    }

    /// The cross-device story for today — "WHOOP HRV dropped, sleep was short…" —
    /// shown in the hub and injected into the coach so it reasons across devices.
    var deviceNarrative: String {
        let d = recovery.today
        let hrvDelta = d.hrvBaseline > 0
            ? Int((Double(d.hrv - d.hrvBaseline) / Double(d.hrvBaseline) * 100).rounded())
            : 0
        let strainRatio = d.strainYesterday > 0 ? d.strainYesterday / 12.0 : 1.0
        return DataHub.narrative(
            connected: connectedSources,
            hrvDeltaPct: hrvDelta,
            sleepHours: d.sleep.hours,
            loadRatio: strainRatio,
            volumeAdjustPct: dailyDirective.tone == .ruby ? -25 : (d.recovery < 80 ? -20 : 0))
    }

    /// One line per connected device and what it contributes — for the coach prompt.
    var dataSourceSummary: String {
        let devices = recovery.wearables.filter(\.connected).map { device in
            "\(device.source.displayName) (\(device.source.capabilities.prefix(5).map { $0.label.lowercased() }.joined(separator: ", ")))"
        }
        var summary = devices.joined(separator: " · ")
        let prefs = recovery.preferredSources
            .filter { recovery.connectedSources.contains($0.value) }
            .map { "\($0.key.label.lowercased()) ← \($0.value.displayName)" }
        if !prefs.isEmpty {
            summary += ". Preferred sources: " + prefs.joined(separator: ", ")
        }
        return summary
    }

    /// Live snapshot handed to the AI coach — every number the system prompt cites
    /// comes from current service state, so chat and UI can never disagree.
    var coachContext: CoachContext {
        let d = recovery.today
        let mg = magnesiumStatus
        let injury = injuries.active.first
        return CoachContext(
            name: user.name, age: user.age, sport: user.sport,
            goals: user.goals.map(\.rawValue).joined(separator: ", "),
            level: user.fitnessLevel.rawValue, streakDays: user.streakDays,
            forgeScore: forgeScore, recovery: d.recovery, readiness: d.readiness.rawValue,
            hrv: d.hrv, hrvBaseline: d.hrvBaseline, restingHR: d.restingHR,
            sleepHours: d.sleep.hours, sleepDebtHours: d.sleepDebtHours,
            strainYesterday: d.strainYesterday,
            calorieTarget: nutrition.calorieTarget, proteinTarget: nutrition.proteinTarget,
            waterTargetOz: nutrition.waterTargetOz,
            proteinRemaining: nutrition.proteinRemaining, hydrationPct: nutrition.hydrationPct,
            magnesiumPct: mg.pct, magnesiumDaysLow: mg.days,
            directive: dailyDirective,
            dataSources: dataSourceSummary,
            deviceNarrative: deviceNarrative,
            plateauNote: workouts.plateaus.first.map {
                "\($0.exerciseName) flat \($0.sessions) sessions at e1RM \(Int($0.bestE1RM)) lb (avg top-set RPE \(String(format: "%.1f", $0.avgTopRPE)))."
            } ?? "",
            isDemo: isDemoAccount,
            injuryName: injury?.type.rawValue ?? "",
            injuryPhase: injury?.phase.rawValue ?? "",
            injuryPain: injury?.painToday ?? 0,
            injuryRiskPercent: injuries.risk.percent,
            injuryRiskBand: injuries.risk.band,
            injuryLine: CoachContext.injuryLine(for: injury),
            deficiencyLine: CoachContext.deficiencyLine(from: nutrition.deficiencies),
            bloodworkLine: CoachContext.bloodworkLine(from: nutrition.bloodwork),
            // No performance-forecast engine yet — the demo athlete keeps the mock
            // forecast; a real account shows none rather than a fabricated projection.
            forecastLine: isDemoAccount ? CoachContext.forecastLine(from: MockData.forecasts) : "",
            rehabLine: CoachContext.rehabLine(plan: injuryRehabPlan, readiness: returnReadiness))
    }

    /// The most valuable supplement not yet taken today — bedtime-relevant first.
    /// Feeds the directive's "Supplement" prescription.
    private var keySupplementTonight: String? {
        let pending = nutrition.supplements.filter { !$0.loggedToday }
        let pick = pending.first { $0.timing.lowercased().contains("bed") } ?? pending.first
        guard let s = pick else { return nil }
        let shortName = s.name.split(separator: " ").first.map(String.init) ?? s.name
        return "\(shortName) \(s.dose)"
    }

    // MARK: - Cross-module intelligence

    /// Why today's recovery reads the way it does — decomposed into its causes.
    var recoveryDrivers: [RecoveryDriver] {
        let d = recovery.today
        let mg = magnesiumStatus
        return InsightEngine.recoveryDrivers(
            recovery: d.recovery,
            sleepHours: d.sleep.hours, sleepReference: 8.5,
            hrv: d.hrv, hrvBaseline: d.hrvBaseline,
            strainYesterday: d.strainYesterday, strainAvg: average(MockData.strainTrend),
            restingHR: d.restingHR, restingHRBaseline: 52,
            magnesiumPct: mg.pct, magnesiumDaysLow: mg.days)
    }

    /// The causal chains linking the modules — sleep→recovery→training→injury→fuel.
    /// One brain: the dashboard, the coach, and the directive all read these.
    var forgeInsights: [ForgeInsight] {
        let d = recovery.today
        let injury = injuries.active.first
        let mg = magnesiumStatus
        return InsightEngine.crossModule(
            recovery: d.recovery, sleepDebtHours: d.sleepDebtHours,
            hrv: d.hrv, hrvBaseline: d.hrvBaseline,
            proteinRemaining: nutrition.proteinRemaining, hydrationPct: nutrition.hydrationPct,
            injuryName: injury?.type.rawValue, injuryPhase: injury?.phase.rawValue, injuryPain: injury?.painToday,
            injuryRiskPercent: injuries.risk.percent, injuryRiskBand: injuries.risk.band,
            magnesiumPct: mg.pct, magnesiumDaysLow: mg.days)
    }

    /// Magnesium status pulled from the live nutrient + deficiency data.
    private var magnesiumStatus: (pct: Int, days: Int) {
        let pct = nutrition.nutrientGroups
            .flatMap(\.items)
            .first { $0.name.contains("Magnesium") }?.percentOfTarget ?? 100
        let days = nutrition.deficiencies.first { $0.nutrient.contains("Magnesium") }?.daysLow ?? 0
        return (pct, days)
    }

    /// The weekly recap — trend windows synthesized into wins, watch-outs, and
    /// next week's single focus. The Directive's longer-horizon sibling.
    var weeklyReport: WeeklyReport {
        return WeeklyReportEngine.make(
            recovery: recovery.series("Recovery"),
            sleep: recovery.series("Sleep"),
            strain: recovery.series("Strain"),
            hrv: recovery.series("HRV"),
            streakDays: user.streakDays,
            lever: forgeScoreLever)
    }

    // MARK: - Injury rehab

    /// Today's auto-generated PT plan for the active injury — feeds the Directive.
    var injuryRehabPlan: RehabPlan? {
        guard let injury = injuries.active.first else { return nil }
        return RehabEngine.plan(for: injury, library: injuries.ptLibrary, protocols: injuries.protocols)
    }

    /// Return-to-sport readiness for the active injury.
    var returnReadiness: ReturnReadiness? {
        guard let injury = injuries.active.first else { return nil }
        return RehabEngine.readiness(checklist: injuries.rtsChecklist, injury: injury)
    }

    private func average(_ xs: [Double]) -> Double {
        xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }
}

struct ScoreComponent: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let weight: Double
}

/// A signed driver of today's Forge Score movement — "+ Recovery improved", "− Hydration low".
struct ScoreChange: Identifiable {
    let id = UUID()
    let text: String
    let positive: Bool
}
