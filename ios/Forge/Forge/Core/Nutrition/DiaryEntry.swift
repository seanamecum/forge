import Foundation
import SwiftData

/// One logged food in the diary — the grams-aware, syncable successor to
/// `NutritionEntryRecord`. Stores everything three layers need:
///  • **totals** (`consumedJSON`) — authoritative for the day's numbers;
///  • **editing basis** (`per100gJSON` + `amount`/`unit`/`grams`/`gramSource`) — so
///    quantity is editable and re-scalable without a fresh lookup;
///  • **prediction signals** (`loggedAt`, food identity + source, `meal`, `day`) —
///    so recents / frequency / time-of-day / next-food are derivable from the log
///    itself (no backfill when Phase 4.5 lands).
///
/// `consumed` is the source of truth for totals: a legacy or quick-add entry has no
/// gram basis (`per100gJSON == ""`, `grams == nil`) and still counts correctly.
@Model
final class DiaryEntry {
    var entryID: String        // stable id (mirrors syncID)
    var day: Date              // start-of-day bucket for the diary
    var loggedAt: Date         // precise timestamp — meal timeline + prediction
    var meal: String           // MealType raw value

    // Food identity (eat-again + prediction)
    var foodID: String
    var foodName: String
    var foodBrand: String?
    var foodSource: String     // provider/source tag ("usda","off","user","legacy",…)

    // Quantity + resolution (editing/re-scale)
    var amount: Double
    var unitID: String
    var unitLabel: String
    var grams: Double?         // canonical grams, nil when unknown (never fabricated)
    var gramSource: String     // ConversionSource raw value

    // Nutrition
    var consumedJSON: String   // NutrientVector actually consumed (authoritative)
    var per100gJSON: String    // per-100 g basis for re-scale; "" when none

    var syncID: String = ""
    var syncUpdatedAt: Date = Date.now
    var syncPending: Bool = true

    init(entryID: String, day: Date, loggedAt: Date, meal: String,
         foodID: String, foodName: String, foodBrand: String? = nil, foodSource: String,
         amount: Double, unitID: String, unitLabel: String,
         grams: Double?, gramSource: String,
         consumedJSON: String, per100gJSON: String = "") {
        self.entryID = entryID
        self.day = day
        self.loggedAt = loggedAt
        self.meal = meal
        self.foodID = foodID
        self.foodName = foodName
        self.foodBrand = foodBrand
        self.foodSource = foodSource
        self.amount = amount
        self.unitID = unitID
        self.unitLabel = unitLabel
        self.grams = grams
        self.gramSource = gramSource
        self.consumedJSON = consumedJSON
        self.per100gJSON = per100gJSON
    }

    /// The consumed nutrient vector (decoded); empty if unreadable.
    var consumed: NutrientVector {
        guard let data = consumedJSON.data(using: .utf8),
              let v = try? JSONDecoder().decode(NutrientVector.self, from: data) else { return .empty }
        return v
    }

    /// The per-100 g basis for re-scaling on edit, if this entry was logged from a
    /// canonical food (nil for legacy/quick-add).
    var per100g: NutrientVector? {
        guard !per100gJSON.isEmpty, let data = per100gJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NutrientVector.self, from: data)
    }

    /// A conversion is "estimated" when its source says so — drives the UI flag.
    var isEstimatedConversion: Bool { ConversionSource(rawValue: gramSource)?.isEstimated ?? false }

    /// Change the logged amount, recomputing consumed nutrition. Uses the per-100 g
    /// basis + grams when available (accurate re-scale); otherwise scales the stored
    /// consumed totals by the amount ratio (quick-add / legacy). Never fabricates a
    /// gram weight. No-op for a non-positive amount.
    func rescale(toAmount newAmount: Double) {
        guard newAmount > 0, amount > 0 else { return }
        if let per = per100g, let g = grams {
            let newGrams = g / amount * newAmount
            consumedJSON = DiaryEntry.encode(ServingConversion.nutrients(per100g: per, grams: newGrams))
            grams = newGrams
        } else {
            let ratio = newAmount / amount
            consumedJSON = DiaryEntry.encode(consumed.scaled(by: ratio))
            grams = grams.map { $0 / amount * newAmount }
        }
        amount = newAmount
    }
}

// MARK: - Construction from the canonical model (the real logging path, used in 1.3)

extension DiaryEntry {
    /// Build a diary entry by logging `quantity` of `food` into `meal` at `at`.
    /// Consumed nutrients come from the canonical facts; the per-100 g basis and the
    /// resolved grams are stored so the amount stays editable. Returns nil only if the
    /// quantity's unit isn't convertible to grams (no fabricated log).
    static func log(food: CanonicalFood, quantity: FoodQuantity, meal: MealType,
                    at: Date, calendar: Calendar = .current) -> DiaryEntry? {
        let (consumed, resolution) = food.nutrients(for: quantity)
        guard let consumed, let grams = resolution.grams,
              let unit = food.unit(id: quantity.unitID) else { return nil }
        let id = UUID().uuidString
        return DiaryEntry(
            entryID: id, day: calendar.startOfDay(for: at), loggedAt: at, meal: meal.rawValue,
            foodID: food.id, foodName: food.name, foodBrand: food.brand, foodSource: unit.source.rawValue,
            amount: quantity.amount, unitID: unit.id, unitLabel: unit.label,
            grams: grams, gramSource: resolution.source.rawValue,
            consumedJSON: encode(consumed), per100gJSON: encode(food.per100g))
    }

    static func encode(_ v: NutrientVector) -> String {
        (try? JSONEncoder().encode(v)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

// MARK: - Migration from the legacy per-serving record

/// Pure mapping from the legacy `NutritionEntryRecord` (which stores per-entry
/// *totals* + a serving multiplier, no gram basis) to a `DiaryEntry`. Legacy entries
/// keep their exact totals; the gram basis is honestly marked unknown (`legacy`), so
/// nothing is fabricated and existing logs stay valid across the migration.
enum DiaryMigration {
    static let legacySource = "legacy"

    static func makeEntry(entryID: String, date: Date, meal: String, name: String,
                          totalCalories: Int, protein: Double, carbs: Double, fat: Double,
                          servings: Double, calendar: Calendar = .current) -> DiaryEntry {
        let consumed = NutrientVector([
            .calories: Double(totalCalories), .protein: protein, .carbs: carbs, .fat: fat,
        ])
        // Deterministic id ("legacy-<entryID>") so re-running the migration — or two
        // devices migrating the same synced legacy row — produces the SAME diary
        // record and dedups under last-write-wins instead of duplicating.
        let base = entryID.isEmpty ? UUID().uuidString : entryID
        let id = "legacy-\(base)"
        let entry = DiaryEntry(
            entryID: id, day: calendar.startOfDay(for: date), loggedAt: date, meal: meal,
            foodID: id, foodName: name, foodBrand: nil, foodSource: legacySource,
            amount: servings <= 0 ? 1 : servings, unitID: "serving", unitLabel: "serving",
            grams: nil, gramSource: legacySource,
            consumedJSON: DiaryEntry.encode(consumed), per100gJSON: "")
        entry.syncID = id     // deterministic sync id → cross-device dedup
        return entry
    }

    static func entry(from legacy: NutritionEntryRecord) -> DiaryEntry {
        makeEntry(entryID: legacy.entryID, date: legacy.date, meal: legacy.meal, name: legacy.name,
                  totalCalories: legacy.calories, protein: legacy.protein,
                  carbs: legacy.carbs, fat: legacy.fat, servings: legacy.servings)
    }
}
