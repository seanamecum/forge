import XCTest
@testable import Forge

final class HealthKitServiceTests: XCTestCase {

    func testStartsInMockModeWithSeededValues() {
        let service = HealthKitService()
        XCTAssertTrue(service.usingMockData)
        XCTAssertEqual(service.authState, .notDetermined)
        XCTAssertGreaterThan(service.steps, 0, "Mock seed must provide non-zero steps")
        XCTAssertGreaterThan(service.hrvMs, 0)
        XCTAssertGreaterThan(service.bodyMassLb, 0)
        XCTAssertGreaterThan(service.sleepHoursLastNight, 0)
    }

    func testWritesAreRefusedWithoutAuthorization() async {
        let service = HealthKitService()
        let workoutSaved = await service.saveWorkout(
            start: .now.addingTimeInterval(-3600), end: .now, calories: 300)
        XCTAssertFalse(workoutSaved, "Writes must be refused before authorization")
        XCTAssertNotNil(service.lastError)

        let massSaved = await service.saveBodyMass(200)
        XCTAssertFalse(massSaved)
    }

    func testRefreshIsNoOpWhenNotAuthorized() async {
        let service = HealthKitService()
        let stepsBefore = service.steps
        await service.refresh()
        XCTAssertEqual(service.steps, stepsBefore,
                       "Refresh must not touch values when not authorized")
        XCTAssertTrue(service.usingMockData)
    }

    func testNutritionTotalsAndWaterClamp() {
        let nutrition = NutritionService()
        let baseCalories = nutrition.calories
        nutrition.add(food: MockData.food("chicken"), to: .dinner)
        XCTAssertEqual(nutrition.calories, baseCalories + MockData.food("chicken").calories)

        nutrition.addWater(10_000)
        XCTAssertLessThanOrEqual(nutrition.waterOz,
                                 Double(nutrition.user.waterTargetOz) * 1.5,
                                 "Water logging must clamp at 150% of target")
        XCTAssertLessThanOrEqual(nutrition.hydrationScore, 100)
    }
}
