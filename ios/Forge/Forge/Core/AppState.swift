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

        // Today's food + water: real log only. A fresh day starts honestly empty.
        nutrition.entries = PersistenceService.loadTodayEntries()
        nutrition.waterOz = PersistenceService.loadTodayWater()

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
        }

        // Real training load from logged sessions → strain → Forge Score + Directive.
        applyTrainingLoad()

        // Morning check-in done earlier today survives relaunch.
        checkIn = PersistenceService.loadTodayCheckIn()

        // Real weigh-in history → Body screen + adaptive nutrition (demo uses the
        // demo trend via `weightTrend`).
        if !isDemoAccount { weightSamples = PersistenceService.loadWeights().map(\.weightLb) }

        refreshFuelPlan()
    }
    private var rehydrated = false

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

    func completeAuth(demo: Bool) {
        isDemoAccount = demo
        if demo {
            workouts.restoreDemoSeed()   // in case a prior real session cleared it
            user = MockData.sean
            finishOnboarding()
        } else {
            workouts.clearDemoSeed()     // a real account starts with a clean slate
            weightSamples = []
            phase = .onboarding
        }
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
        weightSamples = []
        user = Self.onboardingProfile(from: profile)
        injuries.setActive(from: selected)
        finishOnboarding()
    }

    func logout() {
        auth.signOut()
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
        switch recovery.provenance {
        case .demo:
            missing.append("Live Apple Health signals (sleep, HRV, activity)")
        case .partial:
            if !recovery.recoveryFromLiveSignals { missing.append("Live recovery (currently estimated)") }
            missing.append("Live strain & readiness (currently estimated)")
        case .live:
            break
        }
        if checkIn == nil { missing.append("Today's morning check-in") }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A fresh HRV reading (last sample ~\(Int(hrvAge))h old)")
        }

        let fallback = recovery.provenance == .live ? nil
            : "Using demo/estimated values where live data isn't connected — connect Apple Health to personalize."
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
        if recovery.provenance == .demo { missing.append("Live recovery & sleep from Apple Health") }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A fresh HRV reading (last sample ~\(Int(hrvAge))h old)")
        }

        let fallback: String?
        if checkIn == nil {
            fallback = "No check-in yet — log soreness and energy to sharpen today's call."
        } else if recovery.provenance == .demo {
            fallback = "Recovery is demo data until Apple Health is connected."
        } else {
            fallback = nil
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
            missing.append("Live HRV, resting HR & sleep from Apple Health")
        } else if !recovery.recoveryFromLiveSignals {
            missing.append("A fresh HRV reading to derive recovery from your own data")
        }
        if let hrvAge = recovery.liveAgeHours(.hrv), hrvAge >= RecoveryService.staleThresholdHours {
            missing.append("A current HRV sample (last one ~\(Int(hrvAge))h old)")
        }
        let fallback = recovery.recoveryFromLiveSignals ? nil
            : "Recovery is a demo/estimated value until fresh Apple Health signals are connected."
        let summary = recovery.recoveryFromLiveSignals
            ? "Recovery \(d.recovery), derived from your HRV vs baseline, resting HR, and sleep."
            : "Recovery \(d.recovery) (estimate) — connect Apple Health to base it on your own signals."
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
        PersistenceService.saveWeight(pounds, context: context)
        weightSamples.append(pounds)
        user.weightLb = pounds
        refreshFuelPlan()
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
    func ingestHealthKitSignals() {
        guard healthKit.authState == .authorized, !healthKit.usingMockData else { return }
        // Pass each sample's real age so a stale HRV/HR no longer reads as current.
        // Steps & energy are same-day sums (inherently fresh → age 0).
        func age(_ kind: MetricKind) -> Double { healthKit.ageHours(for: kind) ?? 0 }
        recovery.updateReading(.sleep, value: healthKit.sleepHoursLastNight, unit: "h", source: .appleWatch, ageHours: age(.sleep))
        recovery.updateReading(.hrv, value: Double(healthKit.hrvMs), unit: "ms", source: .appleWatch, ageHours: age(.hrv))
        recovery.updateReading(.restingHR, value: Double(healthKit.restingHeartRate), unit: "bpm", source: .appleWatch, ageHours: age(.restingHR))
        recovery.updateReading(.heartRate, value: Double(healthKit.heartRate), unit: "bpm", source: .appleWatch, ageHours: age(.heartRate))
        recovery.updateReading(.steps, value: Double(healthKit.steps), unit: "", source: .appleWatch)
        recovery.updateReading(.calories, value: Double(healthKit.activeEnergy), unit: "kcal", source: .appleWatch)
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
            } ?? "")
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
