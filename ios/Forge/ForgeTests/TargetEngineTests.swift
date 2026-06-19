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
