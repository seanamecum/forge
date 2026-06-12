import XCTest
@testable import Forge

final class ScoringTests: XCTestCase {

    func testForgeScoreWeightsSumToOne() {
        let app = AppState()
        let totalWeight = app.forgeScoreBreakdown.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001,
                       "Score component weights must sum to 1.0")
    }

    func testForgeScoreIsInRange() {
        let app = AppState()
        XCTAssertGreaterThanOrEqual(app.forgeScore, 0)
        XCTAssertLessThanOrEqual(app.forgeScore, 100)
    }

    func testForgeScoreMatchesWeightedSum() {
        let app = AppState()
        let expected = Int(app.forgeScoreBreakdown
            .reduce(0.0) { $0 + Double($1.value) * $1.weight }
            .rounded())
        XCTAssertEqual(app.forgeScore, expected)
    }

    func testRecoveryDerivedScoresAreBounded() {
        let d = MockData.today
        for score in [d.trainingLoadScore, d.activityScore, d.stressScore, d.sleepScore] {
            XCTAssertGreaterThanOrEqual(score, 0)
            XCTAssertLessThanOrEqual(score, 100)
        }
    }

    func testReadinessPercentMapping() {
        XCTAssertEqual(RecoveryData.Readiness.low.percent, 30)
        XCTAssertEqual(RecoveryData.Readiness.peak.percent, 96)
        XCTAssertTrue(RecoveryData.Readiness.high.percent > RecoveryData.Readiness.moderate.percent)
    }

    func testInjuryStatusScoreDropsWithPain() {
        let service = InjuryService()
        let baseline = service.injuryStatusScore
        if let injury = service.active.first {
            service.logPain(9, for: injury)
            XCTAssertLessThan(service.injuryStatusScore, baseline,
                              "Higher pain must lower the injury component of the Forge Score")
        }
    }
}
