import XCTest
@testable import Forge

/// The food-detail facts panel — full macro/mineral/vitamin breakdown with %DV,
/// honest (only known nutrients shown, never a fabricated zero).
final class NutritionFactsTests: XCTestCase {

    private let sample = NutrientVector([
        .calories: 200, .protein: 25, .fat: 10,
        .fiber: 5, .calcium: 130, .vitaminC: 45,
    ])

    func testOnlyKnownNutrientsAndSectionsAppear() {
        let sections = NutritionFacts.sections(sample)
        XCTAssertEqual(sections.map(\.title), ["Energy", "Macronutrients", "Carbohydrate", "Minerals", "Vitamins"])
        // Carbs macro wasn't provided → not shown; Fats section fully absent.
        let macros = sections.first { $0.title == "Macronutrients" }!
        XCTAssertEqual(macros.rows.map(\.name), ["Protein", "Total Fat"])
        // Zinc never provided → never appears.
        XCTAssertFalse(sections.flatMap(\.rows).contains { $0.name == "Zinc" })
    }

    func testPercentDVComputedAgainstDailyValues() {
        let rows = NutritionFacts.sections(sample).flatMap(\.rows)
        XCTAssertEqual(rows.first { $0.name == "Protein" }?.percentDV, 50)      // 25 / 50 g
        XCTAssertEqual(rows.first { $0.name == "Total Fat" }?.percentDV, 13)    // 10 / 78 g
        XCTAssertEqual(rows.first { $0.name == "Fiber" }?.percentDV, 18)        // 5 / 28 g
        XCTAssertEqual(rows.first { $0.name == "Calcium" }?.percentDV, 10)      // 130 / 1300 mg
        XCTAssertEqual(rows.first { $0.name == "Vitamin C" }?.percentDV, 50)    // 45 / 90 mg
        XCTAssertNil(rows.first { $0.name == "Calories" }?.percentDV)           // energy has no %DV
    }

    func testAmountFormattingByUnit() {
        XCTAssertEqual(NutritionFacts.amountText(12.34, unit: .gram), "12.3 g")
        XCTAssertEqual(NutritionFacts.amountText(10, unit: .gram), "10 g")       // whole → no decimal
        XCTAssertEqual(NutritionFacts.amountText(0.5, unit: .gram), "0.5 g")
        XCTAssertEqual(NutritionFacts.amountText(150.6, unit: .milligram), "151 mg")
        XCTAssertEqual(NutritionFacts.amountText(90, unit: .microgram), "90 µg")
        XCTAssertEqual(NutritionFacts.amountText(199.6, unit: .kcal), "200 kcal")
    }

    func testEmptyVectorHasNoSections() {
        XCTAssertTrue(NutritionFacts.sections(.empty).isEmpty)
    }
}
