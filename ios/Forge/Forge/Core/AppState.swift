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
    var user: UserProfile = MockData.sean

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
        // Returning users skip straight to the dashboard.
        if UserDefaults.standard.bool(forKey: "forge.hasOnboarded") {
            phase = .main
        }
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

    /// Today's single most important instruction — synthesized by DirectiveEngine.
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
            workoutName: workouts.todaysPlan.name
        )
    }
}

struct ScoreComponent: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let weight: Double
}
