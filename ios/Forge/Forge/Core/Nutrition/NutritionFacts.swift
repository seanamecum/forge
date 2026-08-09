import Foundation

/// Formats a `NutrientVector` into a full, grouped nutrition-facts panel — the
/// Cronometer-grade detail view. Honest by construction: a nutrient appears only
/// when the food actually carries a value for it (unknown ≠ zero), so an incomplete
/// label never masquerades as a measured zero. %DV is shown where a reference Daily
/// Value exists.
enum NutritionFacts {

    struct Row: Identifiable {
        let id = UUID()
        let name: String
        let amount: String
        let percentDV: Int?
    }

    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let rows: [Row]
    }

    /// Reference Daily Values (FDA) — micros from `MicronutrientEngine` plus the
    /// macro/fat DVs, each in its `Nutrient.unit`.
    static let dailyValue: [Nutrient: Double] = {
        var m = MicronutrientEngine.dailyValue
        m[.protein] = 50
        m[.carbs] = 275
        m[.fat] = 78
        m[.saturatedFat] = 20
        m[.cholesterol] = 300
        m[.addedSugar] = 50
        return m
    }()

    static func name(_ n: Nutrient) -> String {
        switch n {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbohydrate"
        case .fat: return "Total Fat"
        case .fiber: return "Fiber"
        case .sugar: return "Sugars"
        case .addedSugar: return "Added Sugars"
        case .saturatedFat: return "Saturated Fat"
        case .transFat: return "Trans Fat"
        case .monounsaturatedFat: return "Monounsaturated"
        case .polyunsaturatedFat: return "Polyunsaturated"
        case .cholesterol: return "Cholesterol"
        default: return MicronutrientEngine.displayName(n)
        }
    }

    static func amountText(_ v: Double, unit: Nutrient.Unit) -> String {
        switch unit {
        case .kcal:
            return "\(Int(v.rounded())) kcal"
        case .gram:
            let r = (v * 10).rounded() / 10
            return r == r.rounded() ? "\(Int(r)) g" : String(format: "%.1f g", r)
        case .milligram:
            return "\(Int(v.rounded())) mg"
        case .microgram:
            return "\(Int(v.rounded())) µg"
        }
    }

    /// The grouped facts for a consumed vector — Energy, Macros, Carb detail, Fat
    /// detail, Minerals, Vitamins. Empty sections (no known nutrients) are dropped.
    static func sections(_ v: NutrientVector) -> [Section] {
        func rows(_ ns: [Nutrient]) -> [Row] {
            ns.compactMap { n in
                guard let val = v[n] else { return nil }   // only what's actually known
                let pct: Int? = {
                    guard let dv = dailyValue[n], dv > 0 else { return nil }
                    return Int((val / dv * 100).rounded())
                }()
                return Row(name: name(n), amount: amountText(val, unit: n.unit), percentDV: pct)
            }
        }

        var out: [Section] = []
        func add(_ title: String, _ ns: [Nutrient]) {
            let r = rows(ns)
            if !r.isEmpty { out.append(Section(title: title, rows: r)) }
        }

        add("Energy", [.calories])
        add("Macronutrients", [.protein, .carbs, .fat])
        add("Carbohydrate", [.fiber, .sugar, .addedSugar])
        add("Fats", [.saturatedFat, .transFat, .monounsaturatedFat, .polyunsaturatedFat, .cholesterol])
        add("Minerals", MicronutrientEngine.minerals)
        add("Vitamins", MicronutrientEngine.vitamins)
        return out
    }
}
