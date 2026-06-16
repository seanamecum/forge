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

    // MARK: - "Why it changed" + biggest lever

    func testForgeScoreChangesAreSignedAndNonEmpty() {
        let app = AppState()
        let changes = app.forgeScoreChanges
        XCTAssertFalse(changes.isEmpty, "The score must always explain what moved it")
        // A positive anchor is guaranteed even on a flat day.
        XCTAssertTrue(changes.contains { $0.positive })
    }

    func testForgeScoreLeverNamesTheHighestImpactFix() {
        let app = AppState()
        let lever = app.forgeScoreLever
        XCTAssertFalse(lever.isEmpty)
        // The biggest lever maximizes recoverable points = (100 - value) * weight.
        let expected = app.forgeScoreBreakdown.max {
            Double(100 - $0.value) * $0.weight < Double(100 - $1.value) * $1.weight
        }!
        XCTAssertTrue(lever.contains(expected.label) || lever.contains("dialed"))
    }
}
