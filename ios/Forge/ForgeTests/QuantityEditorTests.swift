import XCTest
import SwiftData
@testable import Forge

/// Phase 1.4a: the production quantity-editor engine — instant recalculation, unit
/// switching that preserves the food, fast +/-/×/÷ adjustments, fraction typing,
/// per-food memory, and diary operations (duplicate / move / edit). Pure + tested;
/// the SwiftUI sheet (1.4b) is a thin shell over this.
final class QuantityEditorTests: XCTestCase {

    private func egg() -> CanonicalFood {
        CanonicalFood(
            id: "usda-egg", name: "Egg",
            per100g: NutrientVector([.calories: 155, .protein: 13, .fat: 11, .iron: 1.75]),
            portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
            defaultUnitID: "egg")
    }

    // MARK: - Parser

    func testParserHandlesDecimalsFractionsAndMixed() {
        XCTAssertEqual(QuantityParser.parse("2")!, 2, accuracy: 1e-9)
        XCTAssertEqual(QuantityParser.parse("0.5")!, 0.5, accuracy: 1e-9)
        XCTAssertEqual(QuantityParser.parse(".5")!, 0.5, accuracy: 1e-9)
        XCTAssertEqual(QuantityParser.parse("1/2")!, 0.5, accuracy: 1e-9)
        XCTAssertEqual(QuantityParser.parse("3/4")!, 0.75, accuracy: 1e-9)
        XCTAssertEqual(QuantityParser.parse("1 1/2")!, 1.5, accuracy: 1e-9)
        XCTAssertNil(QuantityParser.parse(""))
        XCTAssertNil(QuantityParser.parse("abc"))
        XCTAssertNil(QuantityParser.parse("1/0"))
    }

    // MARK: - Live recalculation

    func testInstantRecalcOnAmount() {
        var e = QuantityEditorEngine(food: egg(), amount: 1, unitID: "egg")
        XCTAssertEqual(e.calories, 78)                       // 50 g → 77.5 → 78
        e.setAmount(5)                                       // 5 eggs = 250 g
        XCTAssertEqual(e.nutrients?[.calories] ?? 0, 155 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(e.nutrients?[.iron] ?? 0, 1.75 * 2.5, accuracy: 1e-6)   // micros too
        XCTAssertEqual(e.grams!, 250, accuracy: 1e-9)
    }

    func testTypedFractionUpdatesNutrition() {
        var e = QuantityEditorEngine(food: egg(), amount: 1, unitID: "egg")
        XCTAssertTrue(e.setAmount(text: "1 1/2"))
        XCTAssertEqual(e.amount, 1.5, accuracy: 1e-9)
        XCTAssertEqual(e.nutrients?[.calories] ?? 0, 155 * 0.75, accuracy: 1e-6)  // 75 g
        XCTAssertFalse(e.setAmount(text: "nope"))            // rejected, amount unchanged
        XCTAssertEqual(e.amount, 1.5, accuracy: 1e-9)
    }

    // MARK: - Fast adjustments (+/- per-unit step, ×/÷)

    func testStepAdjustmentsPerUnit() {
        var e = QuantityEditorEngine(food: egg(), amount: 2, unitID: "egg")
        e.increment(); XCTAssertEqual(e.amount, 3, accuracy: 1e-9)     // +1 egg
        e.decrement(); XCTAssertEqual(e.amount, 2, accuracy: 1e-9)
        e.scale(by: 2); XCTAssertEqual(e.amount, 4, accuracy: 1e-9)    // double
        e.scale(by: 0.5); XCTAssertEqual(e.amount, 2, accuracy: 1e-9)  // halve
        e.decrement(); e.decrement(); e.decrement()                    // can't go below 0
        XCTAssertGreaterThanOrEqual(e.amount, 0)

        var g = QuantityEditorEngine(food: egg(), amount: 100, unitID: "g")
        g.increment(); XCTAssertEqual(g.amount, 105, accuracy: 1e-9)   // grams step by 5
    }

    // MARK: - Unit switching preserves the food (no jump)

    func testSwitchingUnitKeepsGrams() {
        var e = QuantityEditorEngine(food: egg(), amount: 2, unitID: "egg")  // 100 g
        e.switchUnit(to: "g")
        XCTAssertEqual(e.unitID, "g")
        XCTAssertEqual(e.amount, 100, accuracy: 1e-6)                   // 2 eggs → 100 g, not 2 g
        XCTAssertEqual(e.nutrients?[.calories] ?? 0, 155, accuracy: 1e-6)   // unchanged food
        e.switchUnit(to: "oz")
        XCTAssertEqual(e.amount, 100 / 28.349523125, accuracy: 1e-6)    // → oz
        e.switchUnit(to: "egg")
        XCTAssertEqual(e.amount, 2, accuracy: 1e-6)                     // back to 2 eggs
    }

    func testAvailableUnitsIncludePortionThenMass() {
        let e = QuantityEditorEngine(food: egg(), amount: 1, unitID: "egg")
        XCTAssertEqual(e.availableUnits.map(\.id), ["egg", "g", "oz", "lb"])
    }

    // MARK: - Never fabricate; flag estimates

    func testUnconvertibleUnitYieldsNilNutrientsNotZero() {
        let soup = CanonicalFood(
            id: "soup", name: "Soup", per100g: NutrientVector([.calories: 40]),
            portions: [ServingUnit(id: "cup", label: "cup", kind: .volume, gramsPerUnit: nil, source: .estimated)],
            defaultUnitID: "cup")
        let e = QuantityEditorEngine(food: soup, amount: 1, unitID: "cup")
        XCTAssertNil(e.nutrients)
        XCTAssertFalse(e.isConvertible)
        // Grams still work.
        var g = e; g.switchUnit(to: "g"); g.setAmount(240)
        XCTAssertEqual(g.nutrients?[.calories] ?? 0, 96, accuracy: 1e-6)
    }

    func testEstimatedConversionIsFlagged() {
        let food = CanonicalFood(
            id: "f", name: "Trail mix", per100g: NutrientVector([.calories: 500]),
            portions: [.portion(id: "handful", label: "handful", grams: 30, source: .estimated)],
            defaultUnitID: "handful")
        let e = QuantityEditorEngine(food: food, amount: 1, unitID: "handful")
        XCTAssertTrue(e.isEstimatedConversion)
        XCTAssertEqual(e.nutrients?[.calories] ?? 0, 150, accuracy: 1e-6)   // still computes, just flagged
    }

    // MARK: - Editable reconstruction from a logged entry

    func testEditableReconstructionFromDiaryEntry() {
        let logged = DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: 3, unitID: "egg"),
                                    meal: .breakfast, at: .now)!   // 150 g
        let food = CanonicalFood(editableFrom: logged)!
        var e = QuantityEditorEngine(food: food, amount: logged.amount, unitID: logged.unitID)
        XCTAssertEqual(e.calories, Int((155 * 1.5).rounded()))
        // Full unit switching is available on the reconstructed food.
        e.switchUnit(to: "g")
        XCTAssertEqual(e.amount, 150, accuracy: 1e-6)
        XCTAssertEqual(e.availableUnits.map(\.id), ["egg", "g", "oz", "lb"])
    }

    func testReconstructionNilForBasislessEntry() {
        let fe = FoodEntry(meal: .lunch,
                           food: Food(id: "f", name: "Leftovers", serving: "1 plate", calories: 600, protein: 30, carbs: 60, fat: 20),
                           servings: 1)
        let diary = DiaryBridge.diaryEntry(from: fe)          // no gram basis
        XCTAssertNil(CanonicalFood(editableFrom: diary))      // editor falls back to multiplier
    }

    // MARK: - Per-food memory

    func testMemoryRemembersLastAmountAndUnitPerFood() {
        let mem = FoodQuantityMemory(defaults: UserDefaults(suiteName: "qty-test-\(UUID())")!)
        XCTAssertNil(mem.last(foodID: "usda-egg"))
        mem.remember(foodID: "usda-egg", amount: 3, unitID: "egg")
        let last = mem.last(foodID: "usda-egg")
        XCTAssertEqual(last?.amount, 3)
        XCTAssertEqual(last?.unitID, "egg")
        // A different food is independent.
        XCTAssertNil(mem.last(foodID: "usda-oats"))
    }

    func testEngineStartsFromRememberedQuantity() {
        let e = QuantityEditorEngine(food: egg(), remembering: (amount: 4, unitID: "egg"))
        XCTAssertEqual(e.amount, 4)
        XCTAssertEqual(e.unitID, "egg")
        // A remembered unit the food no longer offers falls back to its default.
        let e2 = QuantityEditorEngine(food: egg(), remembering: (amount: 2, unitID: "bogus"))
        XCTAssertEqual(e2.unitID, "egg")
    }

    // MARK: - Diary operations (duplicate / move)

    @MainActor private func store() throws -> ModelContext {
        let c = try ModelContainer(for: DiaryEntry.self, SyncTombstone.self,
                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(c)
    }

    @MainActor
    func testDuplicateAndMoveDiaryEntry() throws {
        let ctx = try store()
        let src = DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: 2, unitID: "egg"),
                                 meal: .breakfast, at: .now)!
        ctx.insert(src); try ctx.save()

        let newID = PersistenceService.duplicateDiaryEntry(entryID: src.entryID, toMeal: "Lunch", context: ctx)!
        let all = try ctx.fetch(FetchDescriptor<DiaryEntry>())
        XCTAssertEqual(all.count, 2)
        let copy = all.first { $0.entryID == newID }!
        XCTAssertNotEqual(copy.entryID, src.entryID)                   // fresh identity
        XCTAssertEqual(copy.meal, "Lunch")
        XCTAssertEqual(copy.consumed[.calories]!, src.consumed[.calories]!, accuracy: 1e-6)

        PersistenceService.moveDiaryEntry(entryID: src.entryID, toMeal: "Dinner", context: ctx)
        let moved = try ctx.fetch(FetchDescriptor<DiaryEntry>()).first { $0.entryID == src.entryID }!
        XCTAssertEqual(moved.meal, "Dinner")
        XCTAssertTrue(moved.syncPending)                               // re-marked for sync
    }

    @MainActor
    func testEditorWriteBackUpdatesEntry() throws {
        let ctx = try store()
        let src = DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: 1, unitID: "egg"),
                                 meal: .breakfast, at: .now)!
        ctx.insert(src); try ctx.save()

        // Simulate the editor changing 1 egg → 200 g and writing back.
        var e = QuantityEditorEngine(food: CanonicalFood(editableFrom: src)!, amount: 1, unitID: "egg")
        e.switchUnit(to: "g"); e.setAmount(200)
        PersistenceService.updateDiaryQuantity(
            entryID: src.entryID, amount: e.amount, unitID: e.unitID, unitLabel: e.unit.label,
            grams: e.grams, gramSource: e.unit.source.rawValue, consumed: e.nutrients!, context: ctx)

        let updated = try ctx.fetch(FetchDescriptor<DiaryEntry>()).first!
        XCTAssertEqual(updated.amount, 200, accuracy: 1e-9)
        XCTAssertEqual(updated.unitID, "g")
        XCTAssertEqual(updated.consumed[.calories]!, 310, accuracy: 1e-6)   // 200 g of egg
    }
}
