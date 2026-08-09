import Foundation

/// Bridges the legacy in-memory `FoodEntry` (per-serving `Food` × a scalar) that the
/// current UI renders, and the grams-aware `DiaryEntry` that now persists + syncs.
/// This keeps Phase 1.3 additive: the diary is the source of truth on disk while the
/// existing views keep working, until the quantity-editor UI replaces them.
///
/// A legacy `Food` has no gram basis (its `serving` is free text), so a manual log is
/// stored quick-add style — consumed totals with `per100g` empty and grams unknown.
/// Phase 2's canonical foods carry a gram basis and log with full re-scale fidelity.
enum DiaryBridge {
    static let manualSource = "manual"

    /// A `DiaryEntry` for a just-logged `FoodEntry`. Its id matches the FoodEntry's,
    /// so an optimistic UI row and its persisted record share identity.
    static func diaryEntry(from fe: FoodEntry, at: Date = .now, calendar: Calendar = .current) -> DiaryEntry {
        var values: [Nutrient: Double] = [
            .calories: Double(fe.calories), .protein: fe.protein, .carbs: fe.carbs, .fat: fe.fat,
        ]
        if fe.food.fiber > 0 { values[.fiber] = fe.food.fiber * fe.servings }
        if fe.food.sugar > 0 { values[.sugar] = fe.food.sugar * fe.servings }
        return DiaryEntry(
            entryID: fe.id.uuidString, day: calendar.startOfDay(for: at), loggedAt: at,
            meal: fe.meal.rawValue, foodID: fe.food.id, foodName: fe.food.name, foodBrand: fe.food.brand,
            foodSource: manualSource, amount: fe.servings, unitID: "serving", unitLabel: "serving",
            grams: nil, gramSource: manualSource,
            consumedJSON: DiaryEntry.encode(NutrientVector(values)), per100gJSON: "")
    }

    /// A display `FoodEntry` for a persisted `DiaryEntry`. Consumed totals are the
    /// truth, so `food` carries the totals and `servings` is 1 (the row shows the
    /// logged amount via `food.serving`). `food.id` embeds the diary id for deletion.
    static func foodEntry(from d: DiaryEntry) -> FoodEntry? {
        guard let meal = MealType(rawValue: d.meal) else { return nil }
        let c = d.consumed
        let amountLabel = d.amount == 1 ? d.unitLabel : "\(trim(d.amount)) \(d.unitLabel)"
        let food = Food(
            id: "diary-\(d.entryID)", name: d.foodName, brand: d.foodBrand,
            serving: amountLabel,
            calories: Int((c[.calories] ?? 0).rounded()),
            protein: c[.protein] ?? 0, carbs: c[.carbs] ?? 0, fat: c[.fat] ?? 0,
            fiber: c[.fiber] ?? 0, sugar: c[.sugar] ?? 0)
        return FoodEntry(id: stableUUID(from: d.entryID), meal: meal, food: food,
                         servings: 1, time: d.loggedAt.formatted(date: .omitted, time: .shortened))
    }

    /// The diary id backing a display entry — from the `food.id` ("diary-<id>") when
    /// present (loaded rows), else the FoodEntry's own uuid (optimistic rows, whose
    /// persisted DiaryEntry shares that id). Lets deletion find the record either way.
    static func diaryID(for fe: FoodEntry) -> String {
        if fe.food.id.hasPrefix("diary-") { return String(fe.food.id.dropFirst("diary-".count)) }
        return fe.id.uuidString
    }

    private static func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v)
    }

    /// A UUID for a diary id: parse it when it's already a uuid (manual logs), else
    /// derive a stable one from the string (migrated "legacy-…" ids) so the display
    /// row keeps a consistent identity across reloads.
    private static func stableUUID(from id: String) -> UUID {
        if let u = UUID(uuidString: id) { return u }
        var hasher = Hasher(); hasher.combine(id)
        let h = UInt64(bitPattern: Int64(hasher.finalize()))
        var bytes = (0..<16).map { UInt8(truncatingIfNeeded: h >> (UInt64($0 % 8) * 8)) }
        bytes[6] = (bytes[6] & 0x0F) | 0x40; bytes[8] = (bytes[8] & 0x3F) | 0x80
        return NSUUID(uuidBytes: bytes) as UUID
    }
}
