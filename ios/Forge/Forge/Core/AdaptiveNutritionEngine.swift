import Foundation

/// One coached change to today's fuel targets — always paired with its reason.
/// "The app changed my numbers" is a bug; "the app changed my numbers and told
/// me why" is coaching.
struct NutritionAdjustment: Equatable, Identifiable {
    let id: String              // stable rule key
    let label: String           // "Calories +150"
    let reason: String          // the why, in plain language
    let deltaCalories: Int
    let deltaProtein: Int
    let deltaWaterOz: Int
}

/// Today's coached fuel plan: base targets from the athlete's body and goal
/// (TargetEngine), adjusted by what's actually happening — training load,
/// weight trend, recovery, and injuries.
struct FuelPlan: Equatable {
    let baseCalories: Int
    let baseProtein: Int
    let baseWaterOz: Int
    let baseFat: Int
    let adjustments: [NutritionAdjustment]

    var calories: Int { baseCalories + adjustments.reduce(0) { $0 + $1.deltaCalories } }
    var protein: Int { baseProtein + adjustments.reduce(0) { $0 + $1.deltaProtein } }
    var waterOz: Int { baseWaterOz + adjustments.reduce(0) { $0 + $1.deltaWaterOz } }

    /// Fat holds the base allocation; carbohydrates absorb every coached
    /// calorie change — that's where training fuel does its work.
    var fat: Int { baseFat }
    var carbs: Int {
        max(0, ((calories - protein * 4 - fat * 9) / 4 / 5) * 5)
    }

    var isAdjusted: Bool { !adjustments.isEmpty }

    /// One-line summary for the Fuel header.
    var headline: String {
        guard isAdjusted else { return "Targets on plan — no adjustments needed today." }
        let cal = calories - baseCalories
        let pro = protein - baseProtein
        var parts: [String] = []
        if cal != 0 { parts.append("\(cal > 0 ? "+" : "")\(cal) kcal") }
        if pro != 0 { parts.append("\(pro > 0 ? "+" : "")\(pro)g protein") }
        if waterOz != baseWaterOz { parts.append("\(waterOz - baseWaterOz > 0 ? "+" : "")\(waterOz - baseWaterOz) oz water") }
        return "Coached today: " + parts.joined(separator: " · ")
    }
}

/// Adaptive nutrition — MacroFactor-style intelligence, Forge-style integration.
/// Pure rules over the athlete's live signals; every branch is unit-tested and
/// every output carries its reason.
enum AdaptiveNutritionEngine {

    struct Inputs {
        var baseCalories: Int
        var baseProtein: Int
        var baseWaterOz: Int
        var baseFat: Int = 0
        var goal: Goal
        /// Daily weight samples, oldest → newest (~14 days).
        var weightTrend: [Double]
        /// Average strain over the last 7 days (0–21).
        var strainAvg7: Double
        var recoveryToday: Int
        var injuryActive: Bool
        /// Tomorrow's session is endurance-focused (carb-load signal).
        var enduranceTomorrow: Bool
    }

    static func plan(_ i: Inputs) -> FuelPlan {
        var adjustments: [NutritionAdjustment] = []

        // 1. Heavy training week → fuel the work.
        if i.strainAvg7 >= 14 {
            adjustments.append(NutritionAdjustment(
                id: "training-load", label: "Calories +150",
                reason: String(format: "Training load is high this week (avg strain %.1f/21). Under-fueling hard weeks costs recovery and next week's sessions.", i.strainAvg7),
                deltaCalories: 150, deltaProtein: 0, deltaWaterOz: 0))
        }

        // 2. Weight-trend check-in (needs ~2 weeks of data to judge).
        if i.weightTrend.count >= 10, let first = i.weightTrend.first, let last = i.weightTrend.last {
            let weeklyChange = (last - first) / Double(i.weightTrend.count) * 7.0
            switch i.goal {
            case .loseFat where abs(weeklyChange) < 0.25:
                adjustments.append(NutritionAdjustment(
                    id: "plateau-cut", label: "Calories −100",
                    reason: String(format: "Weight has been flat for two weeks (%.1f lb/wk). A small cut restarts progress without wrecking training.", weeklyChange),
                    deltaCalories: -100, deltaProtein: 0, deltaWaterOz: 0))
            case .buildMuscle where weeklyChange < 0.2:
                adjustments.append(NutritionAdjustment(
                    id: "stalled-gain", label: "Calories +100",
                    reason: String(format: "Gain rate is %.1f lb/wk against a lean-bulk target of ~0.5. Nudging the surplus up.", weeklyChange),
                    deltaCalories: 100, deltaProtein: 0, deltaWaterOz: 0))
            default:
                break   // on pace — say so via the headline, change nothing
            }
        }

        // 3. Active injury → tissue repair runs on protein.
        if i.injuryActive {
            adjustments.append(NutritionAdjustment(
                id: "injury-protein", label: "Protein +15g",
                reason: "Rehab week: tendon and muscle repair raise protein needs. Holding this until the injury clears.",
                deltaCalories: 0, deltaProtein: 15, deltaWaterOz: 0))
        }

        // 4. Low recovery → carbs and fluids do the heavy lifting today.
        if i.recoveryToday < 60 {
            adjustments.append(NutritionAdjustment(
                id: "low-recovery", label: "Water +16 oz",
                reason: "Recovery is \(i.recoveryToday)% — prioritize carbohydrates around training and extra fluids today.",
                deltaCalories: 0, deltaProtein: 0, deltaWaterOz: 16))
        }

        // 5. Endurance session tomorrow → carb up tonight.
        if i.enduranceTomorrow {
            adjustments.append(NutritionAdjustment(
                id: "carb-load", label: "Calories +200",
                reason: "Tomorrow is an endurance session — shift extra carbohydrates to tonight so you start topped off.",
                deltaCalories: 200, deltaProtein: 0, deltaWaterOz: 0))
        }

        return FuelPlan(baseCalories: i.baseCalories, baseProtein: i.baseProtein,
                        baseWaterOz: i.baseWaterOz, baseFat: i.baseFat,
                        adjustments: adjustments)
    }
}
