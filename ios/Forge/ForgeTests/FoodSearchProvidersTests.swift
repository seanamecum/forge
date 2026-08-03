import XCTest
import SwiftData
@testable import Forge

/// Phase 2.2c: real federated search providers — the curated instant local set + the
/// Open Food Facts → canonical mapping — and the production log path from a searched
/// food. Network is never hit in tests (OFF mapping is verified with a fixture).
final class FoodSearchProvidersTests: XCTestCase {

    // MARK: - Local common foods

    func testCommonFoodsAreCompleteAndPortioned() {
        XCTAssertGreaterThanOrEqual(CommonFoods.all.count, 20)
        let egg = CommonFoods.all.first { $0.id == "forge-egg" }!
        XCTAssertTrue(egg.per100g.hasAllMacros)
        XCTAssertGreaterThan(egg.confidence, 0.85)                 // USDA-grade → high confidence
        XCTAssertEqual(egg.availableUnits.first?.id, "egg")        // natural portion first
        // Logging a common food yields correct nutrition via the rich path.
        let n = egg.nutrients(for: FoodQuantity(amount: 2, unitID: "egg")).nutrients!
        XCTAssertEqual(n[.calories]!, 155, accuracy: 1e-6)         // 2 eggs = 100 g
    }

    func testLocalProviderSearchesByName() async {
        let p = LocalFoodProvider()
        let chicken = await p.search("chicken", limit: 25)
        XCTAssertTrue(chicken.contains { $0.id == "forge-chicken-breast" })
        XCTAssertFalse(chicken.contains { $0.id == "forge-banana" })
    }

    // MARK: - Open Food Facts → canonical (fixture, no network)

    func testOFFProductMapsToCanonicalFood() {
        let json = """
        { "code": "3017620422003", "product_name": "Nutella", "brands": "Ferrero",
          "serving_quantity": 15,
          "nutriments": { "energy-kcal_100g": 539, "proteins_100g": 6.3, "carbohydrates_100g": 57.5,
                          "fat_100g": 30.9, "sugars_100g": 56.3, "sodium_100g": 0.043 } }
        """.data(using: .utf8)!
        let product = try! JSONDecoder().decode(OpenFoodFacts.Product.self, from: json)
        let food = OpenFoodFacts.canonicalFood(from: product)!
        XCTAssertEqual(food.name, "Nutella")
        XCTAssertEqual(food.brand, "Ferrero")
        XCTAssertEqual(food.source, .openFoodFacts)
        XCTAssertEqual(food.upc, "3017620422003")
        XCTAssertEqual(food.per100g[.calories]!, 539, accuracy: 1e-6)
        XCTAssertEqual(food.per100g[.sodium]!, 43, accuracy: 1e-6)       // 0.043 g → 43 mg
        XCTAssertEqual(food.per100g[.carbs]!, 57.5, accuracy: 1e-6)
        XCTAssertEqual(food.portions.first?.gramsPerUnit, 15)           // serving_quantity → portion
    }

    func testOFFMappingRejectsIncompleteProducts() {
        let json = #"{ "code": "1", "product_name": "", "nutriments": {} }"#.data(using: .utf8)!
        let product = try! JSONDecoder().decode(OpenFoodFacts.Product.self, from: json)
        XCTAssertNil(OpenFoodFacts.canonicalFood(from: product))    // no name/kcal → not loggable
    }

    // MARK: - Pipeline: local + OFF merge/rank via fakes

    func testFederatedSearchMergesAndRanks() async {
        let usda = CanonicalFood(id: "forge-egg", name: "Egg, whole",
                                 per100g: NutrientVector([.calories: 155, .protein: 13, .carbs: 1, .fat: 11]),
                                 source: .usda)
        let off = CanonicalFood(id: "off-egg", name: "Egg, whole",
                                per100g: NutrientVector([.calories: 155, .protein: 13, .carbs: 1, .fat: 11]),
                                source: .openFoodFacts)
        // Same name + macro fingerprint → merged to one, USDA-preferred base.
        let out = FoodSearchPipeline.process([off, usda], query: "egg")
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out.first?.source, .usda)
    }

    // MARK: - Production log path from a searched food

    @MainActor
    func testLogFoodPersistsGramsCanonicalEntry() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: DiaryEntry.self); try? ctx.save()
        let app = AppState(); app.completeAuth(demo: false)

        let egg = CommonFoods.all.first { $0.id == "forge-egg" }!
        app.logFood(egg, quantity: FoodQuantity(amount: 3, unitID: "egg"), meal: .breakfast)

        let stored = PersistenceService.loadTodayDiary()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.foodID, "forge-egg")
        XCTAssertEqual(stored.first?.grams, 150)                     // 3 eggs
        XCTAssertEqual(stored.first?.consumed[.calories], 155 * 1.5) // rich, grams-canonical
        // Remembers the serving for one-tap next time.
        XCTAssertEqual(FoodQuantityMemory().last(foodID: "forge-egg")?.amount, 3)
    }

    @MainActor
    func testDemoLogFoodStaysInMemory() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: DiaryEntry.self); try? ctx.save()
        let app = AppState(); app.completeAuth(demo: true)
        let before = app.nutrition.entries.count
        app.logFood(CommonFoods.all[0], quantity: FoodQuantity(amount: 1, unitID: CommonFoods.all[0].defaultUnitID), meal: .lunch)
        XCTAssertEqual(app.nutrition.entries.count, before + 1)
        XCTAssertTrue(PersistenceService.loadTodayDiary().isEmpty)   // demo never persists
    }
}
