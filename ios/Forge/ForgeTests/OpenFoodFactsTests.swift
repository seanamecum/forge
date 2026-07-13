import XCTest
@testable import Forge

final class OpenFoodFactsTests: XCTestCase {

    // Real-shape OpenFoodFacts v2 payload (trimmed to the fields we request).
    private let fixture = """
    {
      "status": 1,
      "product": {
        "product_name": "Whey Protein Isolate",
        "brands": "Ascent, Ascent Protein",
        "nutriments": {
          "energy-kcal_100g": 375.0,
          "proteins_100g": 78.1,
          "carbohydrates_100g": 9.4,
          "fat_100g": 3.1,
          "fiber_100g": 0.0,
          "sugars_100g": 6.2
        }
      }
    }
    """.data(using: .utf8)!

    func testDecodesProductIntoFood() throws {
        let food = try OpenFoodFacts.food(fromJSON: fixture, barcode: "0857777004003")
        XCTAssertEqual(food.id, "off-0857777004003")
        XCTAssertEqual(food.name, "Whey Protein Isolate")
        XCTAssertEqual(food.brand, "Ascent")          // first brand only
        XCTAssertEqual(food.serving, "100 g")
        XCTAssertEqual(food.calories, 375)
        XCTAssertEqual(food.protein, 78.1, accuracy: 0.001)
        XCTAssertEqual(food.carbs, 9.4, accuracy: 0.001)
        XCTAssertEqual(food.fat, 3.1, accuracy: 0.001)
        XCTAssertEqual(food.sugar, 6.2, accuracy: 0.001)
    }

    func testMissingMacrosDefaultToZero() throws {
        let json = """
        {"status": 1, "product": {"product_name": "Black Coffee",
         "nutriments": {"energy-kcal_100g": 2.0}}}
        """.data(using: .utf8)!
        let food = try OpenFoodFacts.food(fromJSON: json, barcode: "123")
        XCTAssertEqual(food.calories, 2)
        XCTAssertNil(food.brand)
        XCTAssertEqual(food.protein, 0)
        XCTAssertEqual(food.carbs, 0)
        XCTAssertEqual(food.fat, 0)
    }

    func testUnknownBarcodeThrowsNotFound() {
        let json = #"{"status": 0}"#.data(using: .utf8)!
        XCTAssertThrowsError(try OpenFoodFacts.food(fromJSON: json, barcode: "999")) {
            XCTAssertEqual($0 as? OpenFoodFacts.LookupError, .notFound)
        }
    }

    func testProductWithoutCaloriesThrowsNotFound() {
        // A product record with no kcal is unusable for logging.
        let json = """
        {"status": 1, "product": {"product_name": "Mystery", "nutriments": {}}}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try OpenFoodFacts.food(fromJSON: json, barcode: "1")) {
            XCTAssertEqual($0 as? OpenFoodFacts.LookupError, .notFound)
        }
    }

    func testEmptyNameThrowsNotFound() {
        let json = """
        {"status": 1, "product": {"product_name": "",
         "nutriments": {"energy-kcal_100g": 100.0}}}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try OpenFoodFacts.food(fromJSON: json, barcode: "1"))
    }
}
