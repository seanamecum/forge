import Foundation

/// A food in Forge's canonical, grams-first representation — the model the quantity
/// editor, diary, and (Phase 2) federated search all use. Nutrition is stored **per
/// 100 g**; portions carry their own gram weights so any unit logs correctly.
///
/// Deliberately separate from the legacy `Food`/`FoodEntry` (per-serving scalars),
/// which this supersedes via migration in a later Phase-1 milestone. Source/
/// attribution fields are minimal here and expand in Phase 2 without a reshape.
struct CanonicalFood: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    var brand: String?
    /// Nutrients per 100 g (canonical basis).
    var per100g: NutrientVector
    /// Named portions beyond the standard mass units — "1 egg", "1 slice",
    /// "1 serving", "1 cup (if density known)". Each carries its gram weight + source.
    var portions: [ServingUnit]
    /// The unit id the editor should default to (usually a natural portion).
    var defaultUnitID: String

    init(id: String, name: String, brand: String? = nil, per100g: NutrientVector,
         portions: [ServingUnit] = [], defaultUnitID: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.per100g = per100g
        self.portions = portions
        self.defaultUnitID = defaultUnitID ?? portions.first?.id ?? ServingUnit.gram.id
    }

    /// Every unit this food can be logged in: its own portions first (natural), then
    /// the always-available mass units. Deduplicated by id.
    var availableUnits: [ServingUnit] {
        var seen = Set<String>()
        return (portions + ServingUnit.standardMass).filter { seen.insert($0.id).inserted }
    }

    func unit(id: String) -> ServingUnit? { availableUnits.first { $0.id == id } }

    var defaultUnit: ServingUnit { unit(id: defaultUnitID) ?? .gram }

    /// Data-completeness (0–1) over the priority nutrient set — drives the
    /// "incomplete entry" flag. Macros are weighted heavily.
    var completeness: Double {
        let macroKnown = Double(per100g.knownMacros.count) / Double(Nutrient.macros.count)
        let microSet: [Nutrient] = [.fiber, .sugar, .sodium, .potassium, .calcium, .iron]
        let microKnown = Double(microSet.filter { per100g.has($0) }.count) / Double(microSet.count)
        return macroKnown * 0.8 + microKnown * 0.2
    }
}

/// A user's chosen amount + unit for a food. The canonical grams and the resolution
/// (how those grams were derived, and whether estimated) are computed on demand and
/// stored on the diary entry for audit + offline stability.
struct FoodQuantity: Codable, Equatable, Sendable {
    var amount: Double
    var unitID: String

    init(amount: Double, unitID: String) {
        self.amount = amount
        self.unitID = unitID
    }
}

extension CanonicalFood {
    /// Resolve a quantity of this food to grams (never fabricated).
    func grams(for quantity: FoodQuantity) -> GramResolution {
        guard let unit = unit(id: quantity.unitID) else { return .unknown }
        return ServingConversion.grams(amount: quantity.amount, unit: unit)
    }

    /// The consumed nutrients for a quantity, plus how grams were resolved. The
    /// nutrient vector is nil when the chosen unit isn't convertible to grams.
    func nutrients(for quantity: FoodQuantity) -> (nutrients: NutrientVector?, resolution: GramResolution) {
        let res = grams(for: quantity)
        guard let g = res.grams else { return (nil, res) }
        return (ServingConversion.nutrients(per100g: per100g, grams: g), res)
    }
}
