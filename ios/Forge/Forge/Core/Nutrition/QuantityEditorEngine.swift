import Foundation

/// The per-unit "natural step" for +/- fast adjustments — 1 egg at a time, 5 g at a
/// time, ¼ cup at a time. Keeps quick tuning feeling right for each kind of unit.
enum QuantityStep {
    static func step(for unit: ServingUnit) -> Double {
        switch unit.kind {
        case .portion: return 1
        case .mass:
            switch unit.id {
            case ServingUnit.gram.id: return 5
            case ServingUnit.pound.id: return 0.25
            default: return 1        // oz
            }
        case .volume:
            switch unit.id {
            case "ml": return 10
            case "cup": return 0.25
            default: return 1        // tbsp / tsp
            }
        }
    }
}

/// The live, fully-testable state behind the quantity editor. Holds a canonical food
/// plus the current amount + unit and derives everything the UI renders — nutrients,
/// grams, whether the conversion is estimated — so the SwiftUI view stays thin and
/// the behavior is verified in isolation. Never fabricates a gram conversion.
struct QuantityEditorEngine: Equatable {
    let food: CanonicalFood
    private(set) var amount: Double
    private(set) var unitID: String

    init(food: CanonicalFood, amount: Double, unitID: String) {
        self.food = food
        self.amount = max(0, amount)
        self.unitID = food.unit(id: unitID) != nil ? unitID : food.defaultUnitID
    }

    /// Start from a food's default portion (or a remembered amount+unit).
    init(food: CanonicalFood, remembering memory: (amount: Double, unitID: String)? = nil) {
        if let m = memory, food.unit(id: m.unitID) != nil {
            self.init(food: food, amount: m.amount, unitID: m.unitID)
        } else {
            self.init(food: food, amount: 1, unitID: food.defaultUnitID)
        }
    }

    // MARK: Derived (what the UI shows)

    var unit: ServingUnit { food.unit(id: unitID) ?? .gram }
    var availableUnits: [ServingUnit] { food.availableUnits }
    var quantity: FoodQuantity { FoodQuantity(amount: amount, unitID: unitID) }
    var resolution: GramResolution { food.grams(for: quantity) }
    var grams: Double? { resolution.grams }
    /// Live consumed nutrients (nil when the unit isn't convertible to grams).
    var nutrients: NutrientVector? { food.nutrients(for: quantity).nutrients }
    var calories: Int? { nutrients?[.calories].map { Int($0.rounded()) } }
    var isEstimatedConversion: Bool { resolution.isEstimated }
    var isConvertible: Bool { unit.isConvertibleToGrams }
    var isValid: Bool { amount > 0 }

    // MARK: Mutations (fast adjustments)

    mutating func setAmount(_ v: Double) { amount = max(0, round6(v)) }

    /// Set from typed text ("1 1/2", "0.5", "200"); ignored if unparseable.
    @discardableResult
    mutating func setAmount(text: String) -> Bool {
        guard let v = QuantityParser.parse(text) else { return false }
        setAmount(v); return true
    }

    mutating func increment() { setAmount(amount + QuantityStep.step(for: unit)) }
    mutating func decrement() { setAmount(max(0, amount - QuantityStep.step(for: unit))) }
    mutating func scale(by factor: Double) { setAmount(amount * factor) }   // ×2, ÷2

    /// Switch units, preserving the actual food amount: if the current grams are
    /// known and the new unit converts, the displayed amount is recomputed so the
    /// food doesn't jump (2 eggs → 100 g, not 2 g). Otherwise the amount is kept.
    mutating func switchUnit(to newID: String) {
        guard let newUnit = food.unit(id: newID) else { return }
        if let g = grams, let per = newUnit.gramsPerUnit, per > 0 {
            amount = round6(g / per)
        }
        unitID = newID
    }

    private func round6(_ v: Double) -> Double { (v * 1e6).rounded() / 1e6 }
}
