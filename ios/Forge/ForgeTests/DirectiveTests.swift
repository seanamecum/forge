import XCTest
@testable import Forge

final class DirectiveTests: XCTestCase {

    private func make(recovery: Int = 78, sleepDebt: Double = 0,
                      protein: Int = 0, hydration: Int = 100,
                      riskPct: Int = 10, riskBand: String = "Low",
                      injuryName: String? = nil, pain: Int? = nil,
                      workout: String = "Lower — Posterior Chain",
                      soreness: Int? = nil) -> DailyDirective {
        DirectiveEngine.make(
            recovery: recovery, sleepDebtHours: sleepDebt,
            proteinRemaining: protein, hydrationPct: hydration,
            injuryRiskPercent: riskPct, injuryRiskBand: riskBand,
            activeInjuryName: injuryName, activeInjuryPain: pain,
            workoutName: workout, soreness: soreness)
    }

    func testHighRecoveryPushesHard() {
        let d = make(recovery: 88)
        XCTAssertEqual(d.headline, "Push hard today.")
        XCTAssertEqual(d.tone, .green)
    }

    func testModerateRecoveryIsModerate() {
        XCTAssertEqual(make(recovery: 72).headline, "Train at moderate intensity.")
    }

    func testLowRecoveryPullsBack() {
        let d = make(recovery: 45)
        XCTAssertEqual(d.headline, "Pull back and recover today.")
        XCTAssertEqual(d.tone, .ruby)
        XCTAssertTrue(d.priorityAction.contains("recovery"))
    }

    func testInjuryPainIsTopPriority() {
        // Pain outranks every other priority, even at good recovery.
        let d = make(recovery: 82, protein: 80, hydration: 50,
                     injuryName: "Knee", pain: 4)
        XCTAssertTrue(d.priorityAction.lowercased().contains("knee"))
        XCTAssertTrue(d.priorityAction.contains("PT"))
    }

    func testProteinGapAppearsInRationale() {
        let d = make(protein: 72)
        XCTAssertTrue(d.rationale.contains("72g behind"))
    }

    func testHydrationPriorityWhenLow() {
        let d = make(recovery: 78, protein: 0, hydration: 55)
        XCTAssertTrue(d.priorityAction.contains("Hydrate"))
    }

    func testRationaleIsAGrammaticalSentence() {
        let d = make(recovery: 78, protein: 30, hydration: 60,
                     riskPct: 25, riskBand: "Moderate", injuryName: "Knee")
        XCTAssertTrue(d.rationale.hasSuffix("."))
        XCTAssertTrue(d.rationale.contains(", and "))
    }

    func testHighSorenessOverridesGoodRecovery() {
        // Even at high recovery, logging 8/10 soreness flips the directive to recovery.
        let d = make(recovery: 85, soreness: 8)
        XCTAssertEqual(d.headline, "Pull back and recover today.")
        XCTAssertEqual(d.tone, .ruby)
        XCTAssertTrue(d.priorityAction.lowercased().contains("mobility"))
        XCTAssertTrue(d.rationale.contains("soreness 8/10"))
    }

    func testLowSorenessDoesNotOverride() {
        let d = make(recovery: 85, soreness: 2)
        XCTAssertEqual(d.headline, "Push hard today.")
    }

    func testScoreNarrativeNamesWeakestDriver() {
        let app = AppState()
        let narrative = app.forgeScoreNarrative
        let weakest = app.forgeScoreBreakdown.min { $0.value < $1.value }!
        XCTAssertTrue(narrative.contains(weakest.label))
        XCTAssertTrue(narrative.hasPrefix("Held back by"))
        XCTAssertTrue(narrative.contains("Lifted by"))
    }
}
