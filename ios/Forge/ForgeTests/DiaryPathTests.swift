import XCTest
import SwiftData
@testable import Forge

/// Phase 1.3: the app's diary read/write path now runs on the grams-aware
/// `DiaryEntry` (migrating legacy records), with demo/real isolation and sync
/// compatibility preserved.
final class DiaryPathTests: XCTestCase {

    @MainActor private func store() throws -> ModelContext {
        let c = try ModelContainer(
            for: DiaryEntry.self, NutritionEntryRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(c)
    }

    // MARK: - Bridge (pure)

    func testBridgeRoundTripPreservesTotals() {
        let food = Food(id: "off-1", name: "Greek Yogurt", brand: "Fage", serving: "170 g",
                        calories: 100, protein: 18, carbs: 6, fat: 0, fiber: 0, sugar: 4)
        let fe = FoodEntry(meal: .breakfast, food: food, servings: 2)   // 2 servings
        let diary = DiaryBridge.diaryEntry(from: fe)
        // Consumed totals = per-serving × servings.
        XCTAssertEqual(diary.consumed[.calories]!, 200, accuracy: 1e-6)
        XCTAssertEqual(diary.consumed[.protein]!, 36, accuracy: 1e-6)
        XCTAssertEqual(diary.consumed[.sugar]!, 8, accuracy: 1e-6)
        XCTAssertEqual(diary.foodName, "Greek Yogurt")
        XCTAssertEqual(diary.entryID, fe.id.uuidString)

        // Back to a display entry: totals carried, id embedded for deletion.
        let back = DiaryBridge.foodEntry(from: diary)!
        XCTAssertEqual(back.calories, 200)
        XCTAssertEqual(back.meal, .breakfast)
        XCTAssertEqual(back.food.id, "diary-\(diary.entryID)")
        XCTAssertEqual(DiaryBridge.diaryID(for: back), diary.entryID)
    }

    // MARK: - Persist / load / delete (context-injected)

    @MainActor
    func testInsertLoadDeleteRoundTrip() throws {
        let ctx = try store()
        let food = Food(id: "f", name: "Oats", serving: "40 g", calories: 150, protein: 5, carbs: 27, fat: 3)
        let fe = FoodEntry(meal: .breakfast, food: food, servings: 1)
        let diary = DiaryBridge.diaryEntry(from: fe)
        diary.syncID = "diary-oats"           // simulate an already-synced entry
        PersistenceService.insertDiaryEntry(diary, context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<DiaryEntry>()).count, 1)

        PersistenceService.deleteDiaryEntry(entryID: diary.entryID, context: ctx)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<DiaryEntry>()).isEmpty)
        // A synced entry leaves a tombstone so the deletion propagates to other devices.
        let tombstones = try ctx.fetch(FetchDescriptor<SyncTombstone>())
        XCTAssertTrue(tombstones.contains { $0.kind == "diary" && $0.recordID == "diary-oats" })
    }

    @MainActor
    func testDeletingNeverSyncedEntryLeavesNoTombstone() throws {
        let ctx = try store()
        let fe = FoodEntry(meal: .lunch,
                           food: Food(id: "f", name: "Apple", serving: "1", calories: 95, protein: 0, carbs: 25, fat: 0),
                           servings: 1)
        let diary = DiaryBridge.diaryEntry(from: fe)   // syncID "" — never reached the server
        PersistenceService.insertDiaryEntry(diary, context: ctx)
        PersistenceService.deleteDiaryEntry(entryID: diary.entryID, context: ctx)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<SyncTombstone>()).isEmpty, "nothing remote to tombstone")
    }

    // MARK: - Quantity editing (re-scale)

    @MainActor
    func testUpdateQuantityRatioBasedForLegacyStyleEntry() throws {
        let ctx = try store()
        let fe = FoodEntry(meal: .lunch,
                           food: Food(id: "f", name: "Rice", serving: "1 cup", calories: 200, protein: 4, carbs: 45, fat: 0),
                           servings: 1)
        let diary = DiaryBridge.diaryEntry(from: fe)   // no gram basis → ratio scaling
        PersistenceService.insertDiaryEntry(diary, context: ctx)
        PersistenceService.updateDiaryQuantity(entryID: diary.entryID, newAmount: 2.5, context: ctx)
        let e = try ctx.fetch(FetchDescriptor<DiaryEntry>()).first!
        XCTAssertEqual(e.amount, 2.5, accuracy: 1e-9)
        XCTAssertEqual(e.consumed[.calories]!, 200 * 2.5, accuracy: 1e-6)   // ×2.5 from 1
        XCTAssertTrue(e.syncPending)                                        // re-marked for sync
    }

    @MainActor
    func testUpdateQuantityGramsAccurateForCanonicalEntry() throws {
        let ctx = try store()
        let egg = CanonicalFood(
            id: "egg", name: "Egg",
            per100g: NutrientVector([.calories: 155, .protein: 13]),
            portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
            defaultUnitID: "egg")
        let diary = DiaryEntry.log(food: egg, quantity: FoodQuantity(amount: 2, unitID: "egg"),
                                   meal: .breakfast, at: .now)!   // 100 g → 155 kcal
        PersistenceService.insertDiaryEntry(diary, context: ctx)
        PersistenceService.updateDiaryQuantity(entryID: diary.entryID, newAmount: 5, context: ctx)  // 5 eggs
        let e = try ctx.fetch(FetchDescriptor<DiaryEntry>()).first!
        XCTAssertEqual(e.grams!, 250, accuracy: 1e-6)                        // grams re-derived
        XCTAssertEqual(e.consumed[.calories]!, 155 * 2.5, accuracy: 1e-6)
    }

    // MARK: - Legacy migration (idempotent, cross-device-safe, tombstoned)

    @MainActor
    func testMigrationConvertsAndRemovesLegacyIdempotently() throws {
        let ctx = try store()
        ctx.insert(NutritionEntryRecord(entryID: "a", date: .now, meal: "Lunch", name: "Bowl",
                                        calories: 500, protein: 40, carbs: 50, fat: 15, servings: 1))
        ctx.insert(NutritionEntryRecord(entryID: "b", date: .now, meal: "Dinner", name: "Steak",
                                        calories: 600, protein: 50, carbs: 0, fat: 40, servings: 1))
        try ctx.save()

        let migrated = PersistenceService.migrateLegacyNutrition(context: ctx)
        XCTAssertEqual(migrated, 2)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<DiaryEntry>()).count, 2)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<NutritionEntryRecord>()).isEmpty)  // legacy removed
        // Deterministic ids.
        let ids = Set(try ctx.fetch(FetchDescriptor<DiaryEntry>()).map(\.entryID))
        XCTAssertEqual(ids, ["legacy-a", "legacy-b"])

        // Re-running (or a second device migrating the same synced rows) makes NO dupes.
        ctx.insert(NutritionEntryRecord(entryID: "a", date: .now, meal: "Lunch", name: "Bowl",
                                        calories: 500, protein: 40, carbs: 50, fat: 15, servings: 1))
        try ctx.save()
        _ = PersistenceService.migrateLegacyNutrition(context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<DiaryEntry>()).count, 2, "deterministic id dedups")
    }

    @MainActor
    func testMigrationPreservesTotals() throws {
        let ctx = try store()
        ctx.insert(NutritionEntryRecord(entryID: "x", date: .now, meal: "Snacks", name: "Bar",
                                        calories: 220, protein: 20, carbs: 24, fat: 7, servings: 2))
        try ctx.save()
        _ = PersistenceService.migrateLegacyNutrition(context: ctx)
        let e = try ctx.fetch(FetchDescriptor<DiaryEntry>()).first!
        XCTAssertEqual(e.consumed[.calories]!, 220, accuracy: 1e-9)   // stored totals kept exactly
        XCTAssertNil(e.grams)                                          // no fabricated gram basis
    }

    // MARK: - Demo isolation (never persists)

    @MainActor
    func testDemoAddDoesNotPersist() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: DiaryEntry.self); try? ctx.save()

        let n = NutritionService()
        n.isDemo = true
        let before = n.entries.count
        n.add(food: Food(id: "p", name: "Probe", serving: "1", calories: 100, protein: 5, carbs: 5, fat: 2), to: .snack)
        XCTAssertEqual(n.entries.count, before + 1)                    // shown in the demo view
        // Demo returns before scheduling any persistence — nothing in the store.
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<DiaryEntry>()).isEmpty)
    }

    @MainActor
    func testDemoSeedResetsEntriesForIsolation() {
        let n = NutritionService()
        n.clearDemoSeed()
        XCTAssertTrue(n.entries.isEmpty)               // real account starts empty
        n.restoreDemoSeed()
        XCTAssertEqual(n.entries.count, MockData.todaysEntries.count)   // demo shows demo food
    }

    // MARK: - Sync compatibility

    @MainActor
    func testDiaryEntriesCollectForSync() throws {
        let ctx = try store()
        let fe = FoodEntry(meal: .breakfast,
                           food: Food(id: "f", name: "Toast", serving: "1 slice", calories: 80, protein: 3, carbs: 15, fat: 1),
                           servings: 1)
        PersistenceService.insertDiaryEntry(DiaryBridge.diaryEntry(from: fe), context: ctx)
        let pending = SyncEngine.collectPending(context: ctx)
        XCTAssertTrue(pending.contains { $0.kind == "diary" })
    }
}
