import Foundation

/// Every nutrient Forge tracks, keyed by a stable raw value so vectors serialize as
/// clean JSON and new nutrients can be added without a model change. Energy in kcal,
/// macros in grams, micros in their standard unit (see `unit`).
enum Nutrient: String, CaseIterable, Codable, Sendable {
    // Energy + macros
    case calories, protein, carbs, fat, fiber, sugar, addedSugar
    case saturatedFat, transFat, monounsaturatedFat, polyunsaturatedFat, cholesterol
    // Priority micronutrients
    case sodium, potassium, calcium, iron, magnesium, zinc, phosphorus
    case vitaminA, vitaminC, vitaminD, vitaminE, vitaminK
    case vitaminB6, vitaminB12, folate, thiamin, riboflavin, niacin

    enum Unit: String, Sendable { case kcal, gram = "g", milligram = "mg", microgram = "µg" }

    var unit: Unit {
        switch self {
        case .calories: return .kcal
        case .protein, .carbs, .fat, .fiber, .sugar, .addedSugar,
             .saturatedFat, .transFat, .monounsaturatedFat, .polyunsaturatedFat:
            return .gram
        case .cholesterol, .sodium, .potassium, .calcium, .iron, .magnesium,
             .zinc, .phosphorus, .vitaminC, .vitaminE, .niacin,
             .vitaminB6, .thiamin, .riboflavin:
            return .milligram
        case .vitaminA, .vitaminD, .vitaminK, .vitaminB12, .folate:
            return .microgram
        }
    }

    /// The core four every loggable food should carry.
    static let macros: [Nutrient] = [.calories, .protein, .carbs, .fat]
}

/// Nutrient amounts for a specific quantity of food. A missing key means **unknown**
/// (never fabricate a value or assume zero) — distinct from a key present with value
/// 0.0 (a real measured zero). Scaling and summation preserve that distinction.
struct NutrientVector: Codable, Equatable, Sendable {
    private(set) var values: [String: Double]

    init(_ values: [Nutrient: Double] = [:]) {
        self.values = Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) })
    }
    private init(raw: [String: Double]) { self.values = raw }
    /// Reconstruct from raw nutrient-key → amount pairs (used by dedup/merge).
    init(rawValues: [String: Double]) { self.values = rawValues }

    // MARK: Access

    subscript(_ n: Nutrient) -> Double? { values[n.rawValue] }
    func has(_ n: Nutrient) -> Bool { values[n.rawValue] != nil }

    var calories: Double? { self[.calories] }
    var protein: Double? { self[.protein] }
    var carbs: Double? { self[.carbs] }
    var fat: Double? { self[.fat] }
    var fiber: Double? { self[.fiber] }

    /// The macros that are actually known — drives the completeness/honesty UI.
    var knownMacros: Set<Nutrient> { Set(Nutrient.macros.filter { has($0) }) }
    var hasAllMacros: Bool { knownMacros.count == Nutrient.macros.count }

    /// Data completeness (0–1) over the priority nutrient set — macros weighted
    /// heavily, priority micros lightly. Feeds confidence + the "incomplete" flag.
    func completenessScore() -> Double {
        let macroKnown = Double(Nutrient.macros.filter { has($0) }.count) / Double(Nutrient.macros.count)
        let microSet: [Nutrient] = [.fiber, .sugar, .sodium, .potassium, .calcium, .iron]
        let microKnown = Double(microSet.filter { has($0) }.count) / Double(microSet.count)
        return macroKnown * 0.8 + microKnown * 0.2
    }

    // MARK: Math (linear; preserves unknown-ness)

    /// Scale every known nutrient by `factor` (e.g. grams/100 for per-100 g facts).
    /// Unknown nutrients stay unknown — never invented.
    func scaled(by factor: Double) -> NutrientVector {
        NutrientVector(raw: values.mapValues { $0 * factor })
    }

    /// Sum two vectors (meal/day totals). A nutrient known in either side is summed;
    /// a nutrient unknown in both stays unknown. (Unknown treated as 0 for the sum
    /// but the day is flagged incomplete elsewhere via `has(_:)`.)
    static func + (lhs: NutrientVector, rhs: NutrientVector) -> NutrientVector {
        var out = lhs.values
        for (k, v) in rhs.values { out[k, default: 0] += v }
        return NutrientVector(raw: out)
    }

    static let empty = NutrientVector()

    /// Sum a sequence of vectors.
    static func total<S: Sequence>(_ vectors: S) -> NutrientVector where S.Element == NutrientVector {
        vectors.reduce(.empty, +)
    }
}
