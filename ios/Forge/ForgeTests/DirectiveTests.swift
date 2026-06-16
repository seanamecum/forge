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

    // MARK: - Prescription (the structured daily plan)

    func testDirectiveBuildsFullPrescription() {
        let d = DirectiveEngine.make(
            recovery: 78, sleepDebtHours: 3.1, proteinRemaining: 72, hydrationPct: 61,
            injuryRiskPercent: 22, injuryRiskBand: "Moderate",
            activeInjuryName: "Knee", activeInjuryPain: 2,
            workoutName: "Upper Push + Knee-Safe Lower", soreness: nil,
            calorieTarget: 3200, proteinTarget: 200, mobilityMinutes: 20,
            keySupplement: "Magnesium 400 mg", sleepTargetHours: 8.25)

        let kinds = d.actions.map(\.kind)
        XCTAssertTrue(kinds.contains(.train))
        XCTAssertTrue(kinds.contains(.fuel))
        XCTAssertTrue(kinds.contains(.protein))
        XCTAssertTrue(kinds.contains(.mobility))
        XCTAssertTrue(kinds.contains(.supplement))
        XCTAssertTrue(kinds.contains(.sleep))

        XCTAssertEqual(d.actions.first { $0.kind == .fuel }?.value, "3,200 kcal")
        XCTAssertEqual(d.actions.first { $0.kind == .protein }?.value, "200 g · 72 g to go")
        XCTAssertTrue(d.actions.first { $0.kind == .mobility }?.value.contains("knee PT") ?? false)
        XCTAssertEqual(d.actions.first { $0.kind == .sleep }?.value, "8h 15m target")
    }

    func testScalarDirectiveHasOnlyTrainActionByDefault() {
        // Without prescription inputs the directive still works — just the session.
        let d = make()
        XCTAssertEqual(d.actions.map(\.kind), [.train])
    }

    func testProteinActionReadsOnTrackWhenMet() {
        let d = DirectiveEngine.make(
            recovery: 78, sleepDebtHours: 0, proteinRemaining: 0, hydrationPct: 100,
            injuryRiskPercent: 10, injuryRiskBand: "Low",
            activeInjuryName: nil, activeInjuryPain: nil,
            workoutName: "Push", proteinTarget: 200)
        XCTAssertEqual(d.actions.first { $0.kind == .protein }?.value, "200 g · on track")
    }

    func testMobilityActionIsGenericWithoutInjury() {
        let d = DirectiveEngine.make(
            recovery: 78, sleepDebtHours: 0, proteinRemaining: 0, hydrationPct: 100,
            injuryRiskPercent: 10, injuryRiskBand: "Low",
            activeInjuryName: nil, activeInjuryPain: nil,
            workoutName: "Push", mobilityMinutes: 12)
        XCTAssertEqual(d.actions.first { $0.kind == .mobility }?.value, "12 min mobility")
    }
}
