import XCTest
@testable import Forge

/// Locks the production math behind fuel, recovery, and the Digital Twin so a
/// refactor can't silently change what users see. Pure, fast, no network.
final class ProductionMathTests: XCTestCase {

    // MARK: - Nutrition

    func testRemainingNeverGoesNegative() {
        let n = NutritionService()
        XCTAssertEqual(n.caloriesRemaining, max(0, n.user.calorieTarget - n.calories))
        XCTAssertEqual(n.proteinRemaining, max(0, n.user.proteinTarget - n.protein))
        XCTAssertGreaterThanOrEqual(n.caloriesRemaining, 0)
        XCTAssertGreaterThanOrEqual(n.proteinRemaining, 0)
    }

    func testHydrationPercentMatchesIntake() {
        let n = NutritionService()
        XCTAssertEqual(n.hydrationPct, Int(n.waterOz / Double(n.user.waterTargetOz) * 100))
    }

    func testNutritionScoresStayInRange() {
        let n = NutritionService()
        XCTAssertTrue((0...100).contains(n.nutritionScore))
        XCTAssertTrue((0...100).contains(n.hydrationScore))
    }

    func testAddWaterAccumulatesAndCaps() {
        let n = NutritionService()
        let start = n.waterOz
        n.addWater(16)
        XCTAssertEqual(n.waterOz, start + 16, accuracy: 0.001)
        n.addWater(1000)   // cannot exceed 1.5x the daily target
        XCTAssertLessThanOrEqual(n.waterOz, Double(n.user.waterTargetOz) * 1.5 + 0.001)
    }

    func testToggleSupplementFlipsLoggedState() {
        let n = NutritionService()
        let first = n.supplements[0]
        let was = first.loggedToday
        n.toggleSupplement(first)
        XCTAssertNotEqual(n.supplements[0].loggedToday, was)
    }

    // MARK: - Recovery

    func testRecoveryDerivedSignalsAreConsistent() {
        let d = MockData.today
        XCTAssertEqual(d.hrvDelta, d.hrv - d.hrvBaseline)
        XCTAssertEqual(d.sleepScore, d.sleep.score)
        for v in [d.trainingLoadScore, d.activityScore, d.stressScore, d.sleepScore] {
            XCTAssertTrue((0...100).contains(v))
        }
    }

    func testTrainingLoadDropsAsStrainRises() {
        func snapshot(strain: Double) -> RecoveryData {
            RecoveryData(recovery: 80, hrv: 60, hrvBaseline: 60, restingHR: 52,
                         sleep: MockData.today.sleep, strainYesterday: strain, strainToday: 6,
                         steps: 9000, stepGoal: 10000, caloriesOut: 2800,
                         sleepDebtHours: 0, readiness: .high)
        }
        XCTAssertGreaterThan(snapshot(strain: 8).trainingLoadScore,
                             snapshot(strain: 19).trainingLoadScore)
    }

    // MARK: - Forecasts (Digital Twin)

    func testForecastsAreWellFormed() {
        XCTAssertFalse(MockData.forecasts.isEmpty)
        for f in MockData.forecasts {
            XCTAssertFalse(f.metric.isEmpty)
            XCTAssertFalse(f.current.isEmpty)
            XCTAssertFalse(f.projected.isEmpty)
            XCTAssertFalse(f.eta.isEmpty)
            XCTAssertFalse(f.rationale.isEmpty)
            XCTAssertTrue((0.0...1.0).contains(f.confidence), "Confidence must read as a probability")
        }
    }
}
