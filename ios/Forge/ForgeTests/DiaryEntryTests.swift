import XCTest
import SwiftData
@testable import Forge

/// Phase 1.2: the grams-aware, syncable `DiaryEntry` + its migration from the legacy
/// per-serving `NutritionEntryRecord`. Additive — the app's read/write path still
/// uses the legacy record until Phase 1.3, so nothing regresses.
final class DiaryEntryTests: XCTestCase {

    @MainActor private func store() throws -> ModelContext {
        let c = try ModelContainer(
            for: DiaryEntry.self, NutritionEntryRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(c)
    }

    private func egg() -> CanonicalFood {
        CanonicalFood(
            id: "usda-egg", name: "Egg, whole, raw",
            per100g: NutrientVector([.calories: 155, .protein: 13, .carbs: 1.1, .fat: 11, .iron: 1.75]),
            portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
            defaultUnitID: "egg")
    }

    // MARK: - Logging from the canonical model

    func testLogFromCanonicalFoodComputesConsumedAndBasis() {
        let e = egg()
        let at = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = DiaryEntry.log(food: e, quantity: FoodQuantity(amount: 5, unitID: "egg"),
                                   meal: .breakfast, at: at)!
        // 5 eggs = 250 g → ×2.5
        XCTAssertEqual(entry.consumed[.calories]!, 155 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(entry.consumed[.iron]!, 1.75 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(entry.grams!, 250, accuracy: 1e-9)
        XCTAssertEqual(entry.gramSource, ConversionSource.usda.rawValue)
        XCTAssertFalse(entry.isEstimatedConversion)
        XCTAssertEqual(entry.meal, MealType.breakfast.rawValue)
        XCTAssertEqual(entry.loggedAt, at)                    // precise timestamp preserved
        XCTAssertEqual(entry.foodID, "usda-egg")
        // The per-100 g basis is retained for editing/re-scale.
        XCTAssertEqual(entry.per100g?[.calories] ?? 0, 155, accuracy: 1e-9)
    }

    func testLogRejectsUnconvertibleUnitRatherThanFabricate() {
        let soup = CanonicalFood(
            id: "soup", name: "Soup",
            per100g: NutrientVector([.calories: 40]),
            portions: [ServingUnit(id: "cup", label: "cup", kind: .volume, gramsPerUnit: nil, source: .estimated)],
            defaultUnitID: "cup")
        XCTAssertNil(DiaryEntry.log(food: soup, quantity: FoodQuantity(amount: 1, unitID: "cup"),
                                    meal: .lunch, at: .now),
                     "no gram conversion → no fabricated log")
    }

    // MARK: - Persistence + sync payload round-trip

    @MainActor
    func testDiaryEntryPersistsAndSyncPayloadRoundTrips() throws {
        let ctx = try store()
        let entry = DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: 2, unitID: "egg"),
                                   meal: .breakfast, at: .now)!
        ctx.insert(entry); try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<DiaryEntry>()).count, 1)
        XCTAssertTrue(entry.syncPending)                     // new entries upload
        XCTAssertEqual(DiaryEntry.syncKind, "diary")

        // Round-trip the sync payload (what crosses the wire).
        let payload = try entry.syncPayload()
        let restored = try DiaryEntry.instantiate(payload: payload)
        XCTAssertEqual(restored.foodName, "Egg, whole, raw")
        XCTAssertEqual(restored.amount, 2)
        XCTAssertEqual(restored.consumed[.calories]!, entry.consumed[.calories]!, accuracy: 1e-6)
        XCTAssertEqual(restored.grams!, entry.grams!, accuracy: 1e-9)
    }

    @MainActor
    func testDiaryIsRegisteredForSync() {
        XCTAssertNotNil(SyncRegistry.byKind["diary"])
        XCTAssertTrue(SyncRegistry.handlers.map(\.kind).contains("diary"))
    }

    // MARK: - Legacy migration (no fabrication, totals preserved)

    func testLegacyMigrationPreservesTotalsAndMarksBasisUnknown() {
        // Legacy stores per-entry TOTALS + a servings multiplier, no gram basis.
        let date = Date(timeIntervalSince1970: 1_690_000_000)
        let entry = DiaryMigration.makeEntry(
            entryID: "abc", date: date, meal: "Lunch", name: "Chicken bowl",
            totalCalories: 640, protein: 55, carbs: 60, fat: 18, servings: 2)
        XCTAssertEqual(entry.consumed[.calories]!, 640, accuracy: 1e-9)   // totals kept exactly
        XCTAssertEqual(entry.consumed[.protein]!, 55, accuracy: 1e-9)
        XCTAssertNil(entry.grams, "legacy has no gram basis — not fabricated")
        XCTAssertEqual(entry.gramSource, DiaryMigration.legacySource)
        XCTAssertEqual(entry.foodSource, DiaryMigration.legacySource)
        XCTAssertEqual(entry.unitID, "serving")
        XCTAssertEqual(entry.amount, 2)
        XCTAssertNil(entry.per100g, "no per-100 g basis for a legacy entry")
        XCTAssertEqual(entry.foodID, "legacy-abc")
        XCTAssertEqual(Calendar.current.startOfDay(for: date), entry.day)
    }

    @MainActor
    func testMigrationFromLegacyRecord() throws {
        let ctx = try store()
        let legacy = NutritionEntryRecord(entryID: "e1", date: .now, meal: "Dinner",
                                          name: "Salmon", calories: 400, protein: 40, carbs: 0, fat: 26, servings: 1)
        ctx.insert(legacy); try ctx.save()

        let migrated = DiaryMigration.entry(from: legacy)
        XCTAssertEqual(migrated.foodName, "Salmon")
        XCTAssertEqual(migrated.consumed[.fat]!, 26, accuracy: 1e-9)
        XCTAssertEqual(migrated.foodID, "legacy-e1")
        // Migration is a pure mapping — it doesn't mutate the legacy row.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<NutritionEntryRecord>()).count, 1)
    }

    func testMigrationHandlesEmptyIDAndZeroServings() {
        let entry = DiaryMigration.makeEntry(
            entryID: "", date: .now, meal: "Snacks", name: "Apple",
            totalCalories: 95, protein: 0.5, carbs: 25, fat: 0.3, servings: 0)
        XCTAssertFalse(entry.entryID.isEmpty)     // a fresh id is generated
        XCTAssertEqual(entry.amount, 1)           // zero servings → 1, never a divide-by-zero later
    }
}
