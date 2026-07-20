import XCTest
@testable import Forge

/// Targets must be personal — and the demo athlete's established numbers must
/// survive the switch from hardcoded constants to a derived engine.
final class TargetEngineTests: XCTestCase {

    func testDemoAthleteTargetsArePreserved() {
        let s = MockData.sean
        XCTAssertEqual(s.calorieTarget, 3200)
        XCTAssertEqual(s.proteinTarget, 200)
        XCTAssertEqual(s.waterTargetOz, 120)
        XCTAssertEqual(s.fatTarget, 95)
    }

    func testTargetsScaleWithBodyweight() {
        var small = MockData.sean; small.weightLb = 140
        var big = MockData.sean;   big.weightLb = 240
        XCTAssertLessThan(small.calorieTarget, big.calorieTarget)
        XCTAssertLessThan(small.proteinTarget, big.proteinTarget)
        XCTAssertLessThan(small.waterTargetOz, big.waterTargetOz)
    }

    func testGoalShiftsCalories() {
        var cut = MockData.sean;  cut.goals = [.loseFat]
        var bulk = MockData.sean; bulk.goals = [.buildMuscle]
        XCTAssertLessThan(cut.calorieTarget, bulk.calorieTarget)
    }

    func testMacrosReconcileToCalories() {
        let s = MockData.sean
        let macroCalories = s.proteinTarget * 4 + s.carbTarget * 4 + s.fatTarget * 9
        XCTAssertEqual(Double(macroCalories), Double(s.calorieTarget), accuracy: 60)
    }

    func testStepAndEnergyGoalsAreDerivedNotHardcoded() {
        // Replaces the flat 10,000 steps / 1,000 kcal. A more active athlete gets
        // a higher goal; a sedentary one gets a lower, safer default.
        var couch = MockData.sean; couch.activityLevel = .sedentary
        var athlete = MockData.sean; athlete.activityLevel = .veryActive
        XCTAssertLessThan(TargetEngine.steps(couch), TargetEngine.steps(athlete))
        XCTAssertLessThan(TargetEngine.activeEnergy(couch), TargetEngine.activeEnergy(athlete))
        // Sanity: goals are positive and not the old universal constants for everyone.
        XCTAssertGreaterThan(TargetEngine.steps(couch), 0)
        XCTAssertNotEqual(TargetEngine.steps(couch), 10_000)
        XCTAssertGreaterThan(TargetEngine.activeEnergy(athlete), 0)
    }

    func testActiveEnergyScalesWithBodyweight() {
        var small = MockData.sean; small.weightLb = 130
        var big = MockData.sean;   big.weightLb = 250
        XCTAssertLessThan(TargetEngine.activeEnergy(small), TargetEngine.activeEnergy(big))
    }

    func testProfilePersistsThroughCodable() throws {
        // Backs profile persistence — a returning user must not revert to the demo.
        let data = try JSONEncoder().encode(MockData.sean)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.name, MockData.sean.name)
        XCTAssertEqual(decoded.weightLb, MockData.sean.weightLb)
        XCTAssertEqual(decoded.primaryGoal.rawValue, MockData.sean.primaryGoal.rawValue)
        XCTAssertEqual(decoded.calorieTarget, MockData.sean.calorieTarget)
    }
}
