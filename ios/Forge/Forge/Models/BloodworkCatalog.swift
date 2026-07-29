import Foundation

/// Reference marker definitions (names, units, normal/optimal ranges) the user
/// picks from when entering their own lab results. This is medical reference data
/// — NOT demo user data. The value the user enters is theirs.
struct BloodworkCatalogEntry: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let category: BloodworkMarker.Category
    let unit: String
    let normalLow: Double
    let normalHigh: Double
    let optimalLow: Double
    let optimalHigh: Double

    /// Build a real marker from the user's entered value.
    func marker(value: Double, takenAt: String) -> BloodworkMarker {
        BloodworkMarker(name: name, category: category, value: value, unit: unit,
                        normalLow: normalLow, normalHigh: normalHigh,
                        optimalLow: optimalLow, optimalHigh: optimalHigh,
                        takenAt: takenAt, aiNote: "")
    }
}

enum BloodworkCatalog {
    static let markers: [BloodworkCatalogEntry] = [
        .init(name: "Vitamin D (25-OH)", category: .vitamins, unit: "ng/mL", normalLow: 30, normalHigh: 100, optimalLow: 50, optimalHigh: 80),
        .init(name: "Vitamin B12", category: .vitamins, unit: "pg/mL", normalLow: 200, normalHigh: 900, optimalLow: 500, optimalHigh: 900),
        .init(name: "Ferritin", category: .vitamins, unit: "ng/mL", normalLow: 30, normalHigh: 400, optimalLow: 50, optimalHigh: 200),
        .init(name: "Magnesium (RBC)", category: .vitamins, unit: "mg/dL", normalLow: 4.0, normalHigh: 6.4, optimalLow: 5.0, optimalHigh: 6.4),
        .init(name: "Testosterone (total)", category: .hormones, unit: "ng/dL", normalLow: 300, normalHigh: 1000, optimalLow: 600, optimalHigh: 1000),
        .init(name: "TSH", category: .thyroid, unit: "mIU/L", normalLow: 0.4, normalHigh: 4.0, optimalLow: 1.0, optimalHigh: 2.5),
        .init(name: "HbA1c", category: .metabolic, unit: "%", normalLow: 4.0, normalHigh: 5.6, optimalLow: 4.5, optimalHigh: 5.2),
        .init(name: "hs-CRP", category: .inflammation, unit: "mg/L", normalLow: 0, normalHigh: 3.0, optimalLow: 0, optimalHigh: 1.0),
        .init(name: "HDL", category: .lipids, unit: "mg/dL", normalLow: 40, normalHigh: 100, optimalLow: 55, optimalHigh: 90),
        .init(name: "LDL", category: .lipids, unit: "mg/dL", normalLow: 0, normalHigh: 130, optimalLow: 0, optimalHigh: 100),
    ]
}
