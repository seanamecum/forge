import XCTest
import SwiftData
@testable import Forge

/// Phase 1.4b: the AppState operations the editor sheet + diary interactions call —
/// edit quantity, duplicate, move between meals — over the real persisted diary,
/// with demo isolation. The SwiftUI sheet is a thin shell over these + the tested
/// QuantityEditorEngine.
@MainActor
final class DiaryEditOpsTests: XCTestCase {

    private func egg() -> CanonicalFood {
        CanonicalFood(
            id: "usda-egg", name: "Egg",
            per100g: NutrientVector([.calories: 155, .protein: 13, .fat: 11]),
            portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
            defaultUnitID: "egg")
    }

    private func cleanDiary() {
        let ctx = PersistenceService.context
        try? ctx.delete(model: DiaryEntry.self); try? ctx.save()
    }

    /// Insert a real gram-based entry and return its display FoodEntry.
    private func seedEggEntry(amount: Double = 2) -> FoodEntry {
        let d = DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: amount, unitID: "egg"),
                               meal: .breakfast, at: .now)!
        PersistenceService.insertDiaryEntry(d, context: PersistenceService.context)
        return DiaryBridge.foodEntry(from: d)!
    }

    func testQuantityEditorIsRichForGramBasedEntry() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        let fe = seedEggEntry(amount: 2)
        let engine = app.quantityEditor(for: fe)
        XCTAssertNotNil(engine)
        XCTAssertEqual(engine?.availableUnits.map(\.id), ["egg", "g", "oz", "lb"])
    }

    func testQuantityEditorNilForBasislessEntry() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        let fe = FoodEntry(meal: .lunch,
                           food: Food(id: "f", name: "Leftovers", serving: "1 plate", calories: 600, protein: 30, carbs: 60, fat: 20),
                           servings: 1)
        PersistenceService.insertDiaryEntry(DiaryBridge.diaryEntry(from: fe), context: PersistenceService.context)
        let reFe = PersistenceService.loadTodayDiary().compactMap(DiaryBridge.foodEntry).first!
        XCTAssertNil(app.quantityEditor(for: reFe))   // no basis → multiplier fallback
    }

    func testApplyQuantityEditPersistsAndReloads() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        var fe = seedEggEntry(amount: 2)
        app.nutrition.reloadDiary()
        fe = app.nutrition.entries.first!

        var engine = app.quantityEditor(for: fe)!
        engine.switchUnit(to: "g"); engine.setAmount(200)   // 200 g of egg
        app.applyQuantityEdit(fe, engine: engine)

        let stored = PersistenceService.loadTodayDiary().first!
        XCTAssertEqual(stored.amount, 200, accuracy: 1e-9)
        XCTAssertEqual(stored.unitID, "g")
        XCTAssertEqual(stored.consumed[.calories]!, 310, accuracy: 1e-6)
        // In-memory diary reflects it.
        XCTAssertEqual(app.nutrition.entries.first?.calories, 310)
        // The amount+unit is remembered for that food.
        XCTAssertEqual(FoodQuantityMemory().last(foodID: "usda-egg")?.unitID, "g")
    }

    func testApplyMultiplierEditForBasislessEntry() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        let fe0 = FoodEntry(meal: .lunch,
                            food: Food(id: "f", name: "Rice bowl", serving: "1 bowl", calories: 400, protein: 12, carbs: 70, fat: 6),
                            servings: 1)
        PersistenceService.insertDiaryEntry(DiaryBridge.diaryEntry(from: fe0), context: PersistenceService.context)
        app.nutrition.reloadDiary()
        let fe = app.nutrition.entries.first!

        app.applyMultiplierEdit(fe, newAmount: 2)
        XCTAssertEqual(PersistenceService.loadTodayDiary().first?.consumed[.calories] ?? 0, 800, accuracy: 1e-6)
    }

    func testDuplicateAddsACopy() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        _ = seedEggEntry(amount: 2)
        app.nutrition.reloadDiary()
        let fe = app.nutrition.entries.first!

        app.duplicateDiaryEntry(fe, toMeal: .lunch)
        let all = PersistenceService.loadTodayDiary()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.filter { $0.meal == "Lunch" }.count, 1)
    }

    func testMoveChangesMeal() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        _ = seedEggEntry(amount: 2)
        app.nutrition.reloadDiary()
        let fe = app.nutrition.entries.first!

        app.moveDiaryEntry(fe, toMeal: .dinner)
        let all = PersistenceService.loadTodayDiary()
        XCTAssertEqual(all.count, 1)                       // moved, not duplicated
        XCTAssertEqual(all.first?.meal, "Dinner")
    }

    func testDemoDuplicateStaysInMemory() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: true)
        let before = app.nutrition.entries.count
        guard let fe = app.nutrition.entries.first else { return }
        app.duplicateDiaryEntry(fe)
        XCTAssertEqual(app.nutrition.entries.count, before + 1)    // shown
        XCTAssertTrue(PersistenceService.loadTodayDiary().isEmpty) // never persisted
    }
}
