import Foundation

/// Where a gram conversion came from — surfaced so the UI can flag estimates and so
/// the log stores an audit trail. Ordered loosely by trust.
enum ConversionSource: String, Codable, Sendable {
    case exact         // mass↔mass, mathematically exact
    case manufacturer  // label serving weight
    case usda          // USDA portion gram weight
    case off           // Open Food Facts serving size
    case database      // other provider portion
    case user          // user-defined ("1 homemade scoop = 38 g")
    case estimated     // a generic/assumed conversion — must be flagged in the UI

    /// True when the conversion is an approximation the user should see labeled.
    var isEstimated: Bool { self == .estimated }
}

enum MeasureKind: String, Codable, Sendable {
    case mass        // g, oz, lb — always inter-convertible
    case volume      // ml, cup, tbsp, tsp — needs density to reach grams
    case portion     // egg, slice, scoop, package, "serving" — carries its own gram weight
}

/// A way to measure a food. `gramsPerUnit` is the weight of ONE unit in grams, or
/// nil when unknown (e.g. a volume unit with no density) — in which case the amount
/// is NOT convertible to grams and we never fabricate one.
struct ServingUnit: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String            // "g", "oz", "cup", "egg", "slice", "serving"
    let label: String         // display: "g", "oz", "cup", "egg"
    let plural: String        // "eggs", "slices" (label used for count > 1)
    let kind: MeasureKind
    let gramsPerUnit: Double?
    let source: ConversionSource

    init(id: String, label: String, plural: String? = nil, kind: MeasureKind,
         gramsPerUnit: Double?, source: ConversionSource) {
        self.id = id
        self.label = label
        self.plural = plural ?? label
        self.kind = kind
        self.gramsPerUnit = gramsPerUnit
        self.source = source
    }

    var isConvertibleToGrams: Bool { gramsPerUnit != nil }

    func displayLabel(for amount: Double) -> String { amount == 1 ? label : plural }

    // MARK: - Standard mass/volume units (exact where physics allows)

    /// Grams — the canonical unit.
    static let gram = ServingUnit(id: "g", label: "g", kind: .mass, gramsPerUnit: 1, source: .exact)
    /// Ounce (avoirdupois) — exact mass conversion.
    static let ounce = ServingUnit(id: "oz", label: "oz", kind: .mass, gramsPerUnit: 28.349523125, source: .exact)
    /// Pound — exact mass conversion.
    static let pound = ServingUnit(id: "lb", label: "lb", kind: .mass, gramsPerUnit: 453.59237, source: .exact)
    /// Milliliter — needs density; only exact→grams for water-like foods, so gram
    /// weight is left to the food's own portion data. As a bare unit it's non-convertible.
    static let milliliter = ServingUnit(id: "ml", label: "ml", kind: .volume, gramsPerUnit: nil, source: .estimated)

    /// The always-available mass units for any food (grams canonical).
    static let standardMass: [ServingUnit] = [.gram, .ounce, .pound]

    // MARK: - Portion helpers

    /// A named household/serving portion with a known gram weight.
    static func portion(id: String, label: String, plural: String? = nil,
                        grams: Double, source: ConversionSource) -> ServingUnit {
        ServingUnit(id: id, label: label, plural: plural, kind: .portion,
                    gramsPerUnit: grams, source: source)
    }
}
