import Foundation

/// The result of resolving an (amount, unit) to grams. `grams == nil` means the
/// conversion is unknown and Forge will NOT fabricate one — the caller must handle
/// the missing conversion honestly (disallow, or ask the user for a gram weight).
struct GramResolution: Equatable, Sendable {
    let grams: Double?
    let source: ConversionSource
    var isEstimated: Bool { source.isEstimated }
    var isKnown: Bool { grams != nil }

    static let unknown = GramResolution(grams: nil, source: .estimated)
}

/// Pure serving-size math: resolve any amount+unit to canonical grams, convert
/// between units when a reliable factor exists, and scale nutrition facts to the
/// consumed amount. Never invents a gram weight it doesn't have.
enum ServingConversion {

    /// Resolve `amount` of `unit` to grams. Mass units are exact; portion/volume
    /// units use their own `gramsPerUnit`; an unknown factor yields `.unknown`.
    static func grams(amount: Double, unit: ServingUnit) -> GramResolution {
        guard let per = unit.gramsPerUnit else { return .unknown }
        return GramResolution(grams: amount * per, source: unit.source)
    }

    /// Convert an amount from one unit to another **only when both are reliably
    /// convertible to grams** (returns nil otherwise — never a fabricated number).
    static func convert(amount: Double, from: ServingUnit, to: ServingUnit) -> Double? {
        guard let fromPer = from.gramsPerUnit, let toPer = to.gramsPerUnit, toPer != 0
        else { return nil }
        return amount * fromPer / toPer
    }

    /// Nutrients for `grams` of a food whose facts are given per 100 g. All known
    /// nutrients (macros + micros) scale linearly; unknowns stay unknown.
    static func nutrients(per100g: NutrientVector, grams: Double) -> NutrientVector {
        per100g.scaled(by: grams / 100.0)
    }

    /// Nutrients for an amount+unit of a per-100 g food. Returns the scaled vector
    /// plus how the grams were resolved (nil vector when the unit isn't convertible).
    static func nutrients(per100g: NutrientVector, amount: Double, unit: ServingUnit)
        -> (nutrients: NutrientVector?, resolution: GramResolution) {
        let res = grams(amount: amount, unit: unit)
        guard let g = res.grams else { return (nil, res) }
        return (nutrients(per100g: per100g, grams: g), res)
    }
}
