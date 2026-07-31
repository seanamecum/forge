import Foundation

/// Remembers the last amount + unit the user logged for a *specific* food, so the
/// editor pre-fills their usual serving next time (log "2 eggs" once → it opens at
/// "2 eggs"). A UX convenience keyed by food id — not health data and not synced.
/// Injectable `UserDefaults` so it's testable in isolation.
struct FoodQuantityMemory {
    var defaults: UserDefaults = .standard

    private func key(_ foodID: String) -> String { "forge.qty.\(foodID)" }

    func remember(foodID: String, amount: Double, unitID: String) {
        guard !foodID.isEmpty, amount > 0 else { return }
        defaults.set(["a": amount, "u": unitID], forKey: key(foodID))
    }

    func last(foodID: String) -> (amount: Double, unitID: String)? {
        guard let d = defaults.dictionary(forKey: key(foodID)),
              let a = d["a"] as? Double, let u = d["u"] as? String, a > 0 else { return nil }
        return (a, u)
    }
}

extension CanonicalFood {
    /// Rebuild an *editable* canonical food from a logged diary entry: its per-100 g
    /// basis, the portion it was logged in (gram weight = grams ÷ amount), and the
    /// standard mass units — so the editor can switch units and re-scale accurately.
    /// Returns nil when the entry has no gram basis (manual/legacy) — the editor then
    /// falls back to serving-multiplier editing, never fabricating a conversion.
    init?(editableFrom d: DiaryEntry) {
        guard let per = d.per100g, let g = d.grams, d.amount > 0 else { return nil }
        let source = ConversionSource(rawValue: d.gramSource) ?? .database
        let portion = ServingUnit.portion(id: d.unitID, label: d.unitLabel,
                                           grams: g / d.amount, source: source)
        self.init(id: d.foodID, name: d.foodName, brand: d.foodBrand, per100g: per,
                  portions: [portion], defaultUnitID: d.unitID)
    }
}
