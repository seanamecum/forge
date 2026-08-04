import XCTest
@testable import Forge

/// Micronutrients computed from real intake: 7-day-average coverage vs. reference
/// Daily Values, and honest — nutrients with no logged data are never shown.
final class MicronutrientEngineTests: XCTestCase {

    func testAveragesOverDaysAndComputesPercentOfDV() {
        // Two logged days: iron totals 36 mg → avg 18 mg = 100% of the 18 mg DV;
        // calcium totals 650 mg → avg 325 mg = 25% of the 1300 mg DV.
        let total = NutrientVector([.iron: 36, .calcium: 650])
        let groups = MicronutrientEngine.groups(totalConsumed: total, daysLogged: 2)

        let minerals = groups.first { $0.name == "Minerals" }
        XCTAssertNotNil(minerals)
        let iron = minerals?.items.first { $0.name == "Iron" }
        let calcium = minerals?.items.first { $0.name == "Calcium" }
        XCTAssertEqual(iron?.percentOfTarget, 100)
        XCTAssertEqual(calcium?.percentOfTarget, 25)
    }

    func testOnlyLoggedNutrientsAppear() {
        // Only magnesium was ever logged — nothing else should be invented as 0%.
        let groups = MicronutrientEngine.groups(totalConsumed: NutrientVector([.magnesium: 420]), daysLogged: 1)
        let items = groups.flatMap(\.items)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Magnesium")
        XCTAssertEqual(items.first?.percentOfTarget, 100)
        XCTAssertFalse(items.contains { $0.name == "Zinc" })   // never logged → never shown
    }

    func testNoDaysLoggedYieldsNothing() {
        XCTAssertTrue(MicronutrientEngine.groups(totalConsumed: NutrientVector([.iron: 18]), daysLogged: 0).isEmpty)
    }

    func testVitaminsAndMineralsSplitIntoGroups() {
        let total = NutrientVector([.iron: 18, .vitaminC: 90])
        let groups = MicronutrientEngine.groups(totalConsumed: total, daysLogged: 1)
        XCTAssertEqual(Set(groups.map(\.name)), ["Minerals", "Vitamins"])
    }

    func testGapsReturnsUnderTargetSortedMostDeficientFirst() {
        // magnesium 210/420 = 50% (gap), iron 18/18 = 100% (fine), calcium 260/1300 = 20% (worst).
        let groups = MicronutrientEngine.groups(
            totalConsumed: NutrientVector([.magnesium: 210, .iron: 18, .calcium: 260]), daysLogged: 1)
        let gaps = MicronutrientEngine.gaps(in: groups)
        XCTAssertEqual(gaps.map(\.name), ["Calcium", "Magnesium"])   // 20% then 50%; iron excluded
    }

    func testEveryTrackedMicroHasADailyValue() {
        for n in MicronutrientEngine.minerals + MicronutrientEngine.vitamins {
            XCTAssertNotNil(MicronutrientEngine.dailyValue[n], "missing DV for \(n)")
        }
    }
}
