import Foundation

/// Derives daily fuel targets from the athlete's body, activity, and goal — so
/// nutrition reflects the actual user instead of a hardcoded demo number.
///
/// Calibrated so the demo athlete (Sean: 200 lb, very active, building muscle)
/// lands on his established targets — 3,200 kcal / 200 g protein / 120 oz water —
/// keeping the demo coherent while every real profile gets its own numbers.
enum TargetEngine {

    static func calories(_ p: UserProfile) -> Int {
        let maintenance = p.weightLb * calPerLb(p.activityLevel)
        return roundStep(maintenance * goalFactor(p.primaryGoal), to: 50)
    }

    static func protein(_ p: UserProfile) -> Int {
        roundStep(p.weightLb * proteinPerLb(p.primaryGoal), to: 5)
    }

    static func water(_ p: UserProfile) -> Int {
        roundStep(p.weightLb * 0.6, to: 5)
    }

    static func fat(_ p: UserProfile) -> Int {
        roundStep(Double(calories(p)) * 0.27 / 9.0, to: 5)
    }

    /// Daily step goal scaled to how active the athlete already is — a labeled
    /// default, not a universal 10,000. Real HealthKit/Watch move goals, when
    /// available, should override this.
    static func steps(_ p: UserProfile) -> Int {
        switch p.activityLevel {
        case .sedentary:  return 6_000
        case .light:      return 7_000
        case .moderate:   return 8_000
        case .active:     return 10_000
        case .veryActive: return 12_000
        }
    }

    /// Daily active-energy goal (kcal) from body mass + activity — not a flat
    /// 1,000 for everyone. A safe default until a real move goal is connected.
    static func activeEnergy(_ p: UserProfile) -> Int {
        roundStep(p.weightLb * activeKcalPerLb(p.activityLevel), to: 50)
    }

    private static func activeKcalPerLb(_ a: ActivityLevel) -> Double {
        switch a {
        case .sedentary:  return 1.5
        case .light:      return 2.2
        case .moderate:   return 3.0
        case .active:     return 3.8
        case .veryActive: return 4.6
        }
    }

    static func carbs(_ p: UserProfile) -> Int {
        let remaining = Double(calories(p) - protein(p) * 4 - fat(p) * 9)
        return max(0, roundStep(remaining / 4.0, to: 5))
    }

    // MARK: - Coefficients

    private static func calPerLb(_ a: ActivityLevel) -> Double {
        switch a {
        case .sedentary:  return 11
        case .light:      return 12.5
        case .moderate:   return 13.5
        case .active:     return 14.5
        case .veryActive: return 15
        }
    }

    private static func goalFactor(_ g: Goal) -> Double {
        switch g {
        case .loseFat:                            return 0.80
        case .buildMuscle:                        return 1.07
        case .strength:                           return 1.05
        case .athletic:                           return 1.02
        case .endurance, .health, .injuryRecovery: return 1.00
        }
    }

    private static func proteinPerLb(_ g: Goal) -> Double {
        switch g {
        case .buildMuscle, .strength: return 1.0
        case .loseFat:                return 1.1
        case .athletic, .injuryRecovery: return 0.9
        case .endurance:              return 0.75
        case .health:                 return 0.7
        }
    }

    private static func roundStep(_ value: Double, to step: Int) -> Int {
        Int((value / Double(step)).rounded()) * step
    }
}
