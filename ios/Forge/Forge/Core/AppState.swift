import Foundation
import Observation

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

    /// Today's morning check-in, if completed (in-memory; SwiftData holds history).
    var checkIn: CheckInSnapshot?

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
        // Restore the saved profile so a returning user never reverts to the demo athlete.
        if let saved = Self.loadUser() { user = saved }
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

    // MARK: - Profile persistence

    private static let userKey = "forge.user.v1"

    private static func persistUser(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private static func loadUser() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func completeAuth(demo: Bool) {
        if demo {
            user = MockData.sean
            finishOnboarding()
        } else {
            phase = .onboarding
        }
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "forge.hasOnboarded")
        phase = .main
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "forge.hasOnboarded")
        user = MockData.sean
        selectedTab = .home
        phase = .welcome
    }

    /// Forge Score 0–100 — weighted blend of the nine signal inputs.
    var forgeScore: Int {
        let b = forgeScoreBreakdown
        let total = b.reduce(0.0) { $0 + Double($1.value) * $1.weight }
        return Int(total.rounded())
    }

    var forgeScoreBreakdown: [ScoreComponent] {
        let d = recovery.today
        let n = nutrition
        return [
            ScoreComponent(label: "Sleep", value: d.sleepScore, weight: 0.18),
            ScoreComponent(label: "Recovery (HRV)", value: d.recovery, weight: 0.18),
            ScoreComponent(label: "Nutrition", value: n.nutritionScore, weight: 0.14),
            ScoreComponent(label: "Hydration", value: n.hydrationScore, weight: 0.08),
            ScoreComponent(label: "Training Load", value: d.trainingLoadScore, weight: 0.14),
            ScoreComponent(label: "Activity", value: d.activityScore, weight: 0.08),
            ScoreComponent(label: "Stress", value: d.stressScore, weight: 0.10),
            ScoreComponent(label: "Injury Status", value: injuries.injuryStatusScore, weight: 0.10),
        ]
    }

    /// Plain-language explanation of what's raising and lowering the score today.
    var forgeScoreNarrative: String {
        let sorted = forgeScoreBreakdown.sorted { $0.value < $1.value }
        guard let lowest = sorted.first, let highest = sorted.last else { return "" }
        let second = sorted.dropFirst().first
        let drags: String
        if let second, second.value < 75 {
            drags = "\(lowest.label) (\(lowest.value)) and \(second.label) (\(second.value))"
        } else {
            drags = "\(lowest.label) (\(lowest.value))"
        }
        return "Held back by \(drags). Lifted by \(highest.label) (\(highest.value))."
    }

    /// Why the score moved — signed contributors, so the number feels alive.
    /// Positives blend day-over-day trend movement with today's strong components;
    /// negatives surface the components actively dragging the score down.
    var forgeScoreChanges: [ScoreChange] {
        var out: [ScoreChange] = []

        func dayMove(_ name: String) -> Double? {
            guard let s = recovery.trends.first(where: { $0.name == name }), s.values.count >= 2
            else { return nil }
            return s.values[s.values.count - 1] - s.values[s.values.count - 2]
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
    var forgeScoreLever: String {
        guard let c = forgeScoreBreakdown.max(by: {
            Double(100 - $0.value) * $0.weight < Double(100 - $1.value) * $1.weight
        }) else { return "" }
        let gain = Int((Double(100 - c.value) * c.weight).rounded())
        guard gain > 0 else { return "Every input is dialed — hold the line." }
        return "\(c.label) is your biggest lever — up to +\(gain) points on the table."
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
            level: user.fitnessLevel)
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
            workoutName: todaysPlan.name,
            soreness: checkIn?.soreness,
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
        let strain = recovery.trends.first { $0.name == "Strain" }?.values ?? []
        let strainAvg7 = strain.suffix(7).isEmpty ? 0
            : strain.suffix(7).reduce(0, +) / Double(strain.suffix(7).count)
        nutrition.activePlan = AdaptiveNutritionEngine.plan(.init(
            baseCalories: user.calorieTarget,
            baseProtein: user.proteinTarget,
            baseWaterOz: user.waterTargetOz,
            baseFat: user.fatTarget,
            goal: user.primaryGoal,
            weightTrend: MockData.weightTrend,
            strainAvg7: strainAvg7,
            recoveryToday: recovery.today.recovery,
            injuryActive: !injuries.active.isEmpty,
            enduranceTomorrow: user.primaryGoal == .endurance))
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
        recovery.updateReading(.sleep, value: healthKit.sleepHoursLastNight, unit: "h", source: .appleWatch)
        recovery.updateReading(.hrv, value: Double(healthKit.hrvMs), unit: "ms", source: .appleWatch)
        recovery.updateReading(.restingHR, value: Double(healthKit.restingHeartRate), unit: "bpm", source: .appleWatch)
        recovery.updateReading(.heartRate, value: Double(healthKit.heartRate), unit: "bpm", source: .appleWatch)
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
        func series(_ name: String) -> [Double] {
            recovery.trends.first { $0.name == name }?.values ?? []
        }
        return WeeklyReportEngine.make(
            recovery: series("Recovery"),
            sleep: series("Sleep"),
            strain: series("Strain"),
            hrv: series("HRV"),
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
