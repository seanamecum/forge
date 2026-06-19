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
            workoutName: workouts.todaysPlan.name,
            soreness: checkIn?.soreness,
            calorieTarget: user.calorieTarget,
            proteinTarget: user.proteinTarget,
            mobilityMinutes: injury != nil ? 20 : 12,
            keySupplement: keySupplementTonight,
            sleepTargetHours: 8.0 + min(d.sleepDebtHours * 0.08, 1.0)
        )
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
