import Foundation

/// Turns real logged intake into the Micronutrients screen — 7-day average
/// coverage vs. reference Daily Values. Honest by construction: a nutrient is
/// shown only when logged foods actually carry a value for it (unknown ≠ zero),
/// so we never imply a deficiency that's really just missing label data.
enum MicronutrientEngine {

    /// FDA adult Daily Values (2020), each in its `Nutrient.unit`. Reference data,
    /// not a fabricated target.
    static let dailyValue: [Nutrient: Double] = [
        .fiber: 28,            // g
        .sodium: 2300,         // mg
        .potassium: 4700,      // mg
        .calcium: 1300,        // mg
        .iron: 18,             // mg
        .magnesium: 420,       // mg
        .zinc: 11,             // mg
        .phosphorus: 1250,     // mg
        .vitaminA: 900,        // µg RAE
        .vitaminC: 90,         // mg
        .vitaminD: 20,         // µg
        .vitaminE: 15,         // mg
        .vitaminK: 120,        // µg
        .vitaminB6: 1.7,       // mg
        .vitaminB12: 2.4,      // µg
        .folate: 400,          // µg
        .thiamin: 1.2,         // mg
        .riboflavin: 1.3,      // mg
        .niacin: 16,           // mg
    ]

    static let minerals: [Nutrient] = [.sodium, .potassium, .calcium, .iron, .magnesium, .zinc, .phosphorus]
    static let vitamins: [Nutrient] = [.vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK,
                                       .vitaminB6, .vitaminB12, .folate, .thiamin, .riboflavin, .niacin]

    static func displayName(_ n: Nutrient) -> String {
        switch n {
        case .sodium: return "Sodium"
        case .potassium: return "Potassium"
        case .calcium: return "Calcium"
        case .iron: return "Iron"
        case .magnesium: return "Magnesium"
        case .zinc: return "Zinc"
        case .phosphorus: return "Phosphorus"
        case .vitaminA: return "Vitamin A"
        case .vitaminC: return "Vitamin C"
        case .vitaminD: return "Vitamin D"
        case .vitaminE: return "Vitamin E"
        case .vitaminK: return "Vitamin K"
        case .vitaminB6: return "Vitamin B6"
        case .vitaminB12: return "Vitamin B12"
        case .folate: return "Folate"
        case .thiamin: return "Thiamin (B1)"
        case .riboflavin: return "Riboflavin (B2)"
        case .niacin: return "Niacin (B3)"
        case .fiber: return "Fiber"
        default: return n.rawValue.capitalized
        }
    }

    /// Build the grouped 7-day-average coverage from the summed intake over
    /// `daysLogged` distinct logged days. Nutrients with no logged data are omitted.
    static func groups(totalConsumed: NutrientVector, daysLogged: Int) -> [NutrientGroup] {
        guard daysLogged > 0 else { return [] }
        let avg = totalConsumed.scaled(by: 1.0 / Double(daysLogged))

        func statuses(_ set: [Nutrient]) -> [NutrientStatus] {
            set.compactMap { n in
                guard avg.has(n), let dv = dailyValue[n], dv > 0, let v = avg[n] else { return nil }
                return NutrientStatus(name: displayName(n),
                                      percentOfTarget: Int((v / dv * 100).rounded()))
            }
        }

        var out: [NutrientGroup] = []
        let m = statuses(minerals);  if !m.isEmpty  { out.append(NutrientGroup(name: "Minerals", items: m)) }
        let v = statuses(vitamins);  if !v.isEmpty  { out.append(NutrientGroup(name: "Vitamins", items: v)) }
        return out
    }

    /// The under-target nutrients — the honest coaching gaps, most-deficient first.
    static func gaps(in groups: [NutrientGroup], below: Int = 60) -> [NutrientStatus] {
        groups.flatMap(\.items)
            .filter { $0.percentOfTarget < below }
            .sorted { $0.percentOfTarget < $1.percentOfTarget }
    }
}
