import XCTest
@testable import Forge

/// Phase 1 foundation: grams-canonical serving math + nutrient scaling. The
/// flagship requirement — log a food as 1 egg / 5 eggs / 200 g / 7 oz / a fraction —
/// with instant, correct recalculation of every macro and micronutrient, and
/// **never a fabricated gram conversion.**
final class NutritionCoreTests: XCTestCase {

    // A per-100 g egg: ~155 kcal, 13 g protein, 1.1 g carbs, 11 g fat, plus micros.
    // Portions: 1 egg = 50 g (USDA). Mass units come for free.
    private func egg() -> CanonicalFood {
        CanonicalFood(
            id: "usda-egg",
            name: "Egg, whole, raw",
            per100g: NutrientVector([
                .calories: 155, .protein: 13, .carbs: 1.1, .fat: 11,
                .sodium: 124, .potassium: 126, .calcium: 50, .iron: 1.75, .vitaminD: 2.0,
            ]),
            portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
            defaultUnitID: "egg")
    }

    // MARK: - Mass conversions are exact

    func testExactMassConversions() {
        XCTAssertEqual(ServingConversion.grams(amount: 200, unit: .gram).grams!, 200, accuracy: 1e-9)
        XCTAssertEqual(ServingConversion.grams(amount: 7, unit: .ounce).grams!, 7 * 28.349523125, accuracy: 1e-6)
        XCTAssertEqual(ServingConversion.grams(amount: 1, unit: .pound).grams!, 453.59237, accuracy: 1e-6)
        XCTAssertFalse(ServingConversion.grams(amount: 7, unit: .ounce).isEstimated)
    }

    func testUnitToUnitConversion() {
        // 7 oz → grams → oz round-trips; oz↔lb exact.
        XCTAssertEqual(ServingConversion.convert(amount: 16, from: .ounce, to: .pound)!, 1.0, accuracy: 1e-9)
        XCTAssertEqual(ServingConversion.convert(amount: 500, from: .gram, to: .ounce)!,
                       500 / 28.349523125, accuracy: 1e-9)
        // Non-convertible unit (bare ml, no density) → nil, never fabricated.
        XCTAssertNil(ServingConversion.convert(amount: 1, from: .milliliter, to: .gram))
    }

    // MARK: - The eggs acceptance bar

    func testEggLoggedManyWays() {
        let e = egg()
        func kcal(_ amount: Double, _ unitID: String) -> Double? {
            e.nutrients(for: FoodQuantity(amount: amount, unitID: unitID)).nutrients?[.calories]
        }
        // 1 egg = 50 g → 77.5 kcal
        XCTAssertEqual(kcal(1, "egg")!, 155 * 0.5, accuracy: 1e-6)
        // 5 eggs = 250 g → 387.5 kcal
        XCTAssertEqual(kcal(5, "egg")!, 155 * 2.5, accuracy: 1e-6)
        // 200 g → 310 kcal
        XCTAssertEqual(kcal(200, "g")!, 310, accuracy: 1e-6)
        // 7 oz → grams → kcal
        let g7oz = 7 * 28.349523125
        XCTAssertEqual(kcal(7, "oz")!, 155 * g7oz / 100, accuracy: 1e-6)
        // 0.5 serving-egg = 25 g → 38.75 kcal
        XCTAssertEqual(kcal(0.5, "egg")!, 155 * 0.25, accuracy: 1e-6)
    }

    // MARK: - Fractions & decimals

    func testFractionsAndDecimals() {
        let e = egg()
        let third = e.nutrients(for: FoodQuantity(amount: 1.0/3.0, unitID: "egg")).nutrients!
        XCTAssertEqual(third[.protein]!, 13 * (50.0/3.0) / 100, accuracy: 1e-9)
        let deci = e.nutrients(for: FoodQuantity(amount: 2.5, unitID: "egg")).nutrients!
        XCTAssertEqual(deci[.calories]!, 155 * 1.25, accuracy: 1e-9)
    }

    // MARK: - Large quantities don't overflow or lose precision meaningfully

    func testLargeQuantities() {
        let e = egg()
        let n = e.nutrients(for: FoodQuantity(amount: 10_000, unitID: "g")).nutrients!
        XCTAssertEqual(n[.calories]!, 15_500, accuracy: 1e-3)
        XCTAssertEqual(n[.protein]!, 1_300, accuracy: 1e-3)
    }

    // MARK: - Every nutrient (incl. micros) scales correctly

    func testAllNutrientsScaleTogether() {
        let e = egg()
        let n = e.nutrients(for: FoodQuantity(amount: 5, unitID: "egg")).nutrients!  // 250 g → ×2.5
        XCTAssertEqual(n[.calories]!, 155 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(n[.protein]!, 13 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(n[.sodium]!, 124 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(n[.iron]!, 1.75 * 2.5, accuracy: 1e-6)
        XCTAssertEqual(n[.vitaminD]!, 2.0 * 2.5, accuracy: 1e-6)
    }

    // MARK: - Unknown conversions are NEVER fabricated

    func testMissingConversionYieldsNilNotZero() {
        // A food whose only portion is a volume unit with no density.
        let soup = CanonicalFood(
            id: "soup", name: "Homemade soup",
            per100g: NutrientVector([.calories: 40, .protein: 2, .carbs: 5, .fat: 1]),
            portions: [ServingUnit(id: "cup", label: "cup", kind: .volume, gramsPerUnit: nil, source: .estimated)],
            defaultUnitID: "cup")
        let res = soup.nutrients(for: FoodQuantity(amount: 1, unitID: "cup"))
        XCTAssertNil(res.nutrients, "no density → no fabricated grams → no nutrients")
        XCTAssertFalse(res.resolution.isKnown)
        // But grams still works for the same food.
        let byGrams = soup.nutrients(for: FoodQuantity(amount: 240, unitID: "g")).nutrients
        XCTAssertEqual(byGrams?[.calories] ?? 0, 96, accuracy: 1e-6)
    }

    func testEstimatedConversionIsFlagged() {
        // A user-defined scoop = 38 g is trusted; a generic "estimated" portion is flagged.
        let est = ServingUnit.portion(id: "handful", label: "handful", grams: 30, source: .estimated)
        let r = ServingConversion.grams(amount: 2, unit: est)
        XCTAssertEqual(r.grams!, 60, accuracy: 1e-9)
        XCTAssertTrue(r.isEstimated)

        let user = ServingUnit.portion(id: "scoop", label: "scoop", grams: 38, source: .user)
        XCTAssertFalse(ServingConversion.grams(amount: 1, unit: user).isEstimated)
    }

    // MARK: - NutrientVector honesty: unknown ≠ zero

    func testUnknownNutrientStaysUnknownThroughScaleAndSum() {
        var v = NutrientVector([.calories: 100, .protein: 5])   // carbs/fat unknown
        XCTAssertFalse(v.has(.carbs))
        v = v.scaled(by: 2)
        XCTAssertFalse(v.has(.carbs), "scaling must not invent carbs")
        XCTAssertEqual(v[.calories]!, 200, accuracy: 1e-9)
        XCTAssertFalse(v.hasAllMacros)

        let known = NutrientVector([.carbs: 10, .fat: 3])
        let sum = v + known
        XCTAssertEqual(sum[.carbs]!, 10, accuracy: 1e-9)   // now known from the other side
        XCTAssertEqual(sum[.calories]!, 200, accuracy: 1e-9)
    }

    func testDayTotalSumsMeals() {
        let a = NutrientVector([.calories: 300, .protein: 20, .carbs: 30, .fat: 10])
        let b = NutrientVector([.calories: 500, .protein: 40, .carbs: 45, .fat: 18])
        let total = NutrientVector.total([a, b])
        XCTAssertEqual(total[.calories]!, 800, accuracy: 1e-9)
        XCTAssertEqual(total[.protein]!, 60, accuracy: 1e-9)
    }

    // MARK: - Completeness / available units

    func testCompletenessAndAvailableUnits() {
        let e = egg()
        XCTAssertTrue(e.per100g.hasAllMacros)
        XCTAssertGreaterThan(e.completeness, 0.8)
        // Portions first (egg), then standard mass (g/oz/lb), deduped.
        XCTAssertEqual(e.availableUnits.map(\.id), ["egg", "g", "oz", "lb"])
        XCTAssertEqual(e.defaultUnit.id, "egg")
    }

    // MARK: - Codable round-trip (facts persist/sync cleanly)

    func testNutrientVectorCodableRoundTrips() throws {
        let v = NutrientVector([.calories: 155, .protein: 13, .iron: 1.75])
        let data = try JSONEncoder().encode(v)
        let back = try JSONDecoder().decode(NutrientVector.self, from: data)
        XCTAssertEqual(back, v)
        // Clean string-keyed JSON (not an array-of-pairs).
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(obj?["values"])
    }

    func testCanonicalFoodCodableRoundTrips() throws {
        let e = egg()
        let data = try JSONEncoder().encode(e)
        let back = try JSONDecoder().decode(CanonicalFood.self, from: data)
        XCTAssertEqual(back, e)
    }
}
