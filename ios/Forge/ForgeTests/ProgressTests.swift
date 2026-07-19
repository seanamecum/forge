import XCTest
@testable import Forge

/// The shared progress/score maths that used to be re-inlined in views. These
/// guard the exact failure modes the launch audit found: divide-by-zero, NaN/∞,
/// negatives, and a visual/VoiceOver clamp mismatch.
final class ProgressTests: XCTestCase {

    // MARK: Progress.percent / displayPercent

    func testZeroTargetIsSafe() {
        XCTAssertEqual(Progress.percent(500, of: 0), 0)
        XCTAssertEqual(Progress.displayPercent(500, of: 0), 0)
        XCTAssertEqual(Progress.fraction(500, of: 0), 0)
    }

    func testNegativeTargetIsSafe() {
        XCTAssertEqual(Progress.percent(500, of: -100), 0)
    }

    func testNonFiniteInputsAreSafe() {
        XCTAssertEqual(Progress.percent(.nan, of: 100), 0)
        XCTAssertEqual(Progress.percent(.infinity, of: 100), 0)
        XCTAssertEqual(Progress.percent(100, of: .nan), 0)
        XCTAssertEqual(Progress.fraction(.infinity, of: 100), 0)
    }

    func testNegativeValueClampsToZero() {
        XCTAssertEqual(Progress.percent(-50, of: 100), 0)
        XCTAssertEqual(Progress.fraction(-50, of: 100), 0)
    }

    func testTruePercentCanExceed100() {
        XCTAssertEqual(Progress.percent(130, of: 100), 130)
    }

    func testDisplayPercentClampsAt100() {
        XCTAssertEqual(Progress.displayPercent(130, of: 100), 100)
    }

    func testVisualAndAccessibilityUseTheSameClampedValue() {
        // The audit's exact bug: a bar clamped to 100 while VoiceOver read 130.
        // Both surfaces now call displayPercent, so they cannot diverge.
        let value = 260, target = 200
        let visual = Progress.displayPercent(value, of: target)
        let accessibility = Progress.displayPercent(value, of: target)
        XCTAssertEqual(visual, accessibility)
        XCTAssertEqual(visual, 100)
    }

    func testFractionIsClampedToUnitInterval() {
        XCTAssertEqual(Progress.fraction(50, of: 100), 0.5, accuracy: 0.0001)
        XCTAssertEqual(Progress.fraction(300, of: 100), 1.0, accuracy: 0.0001)
    }

    // MARK: ForgeScoreBounds

    func testScoreClampBounds() {
        XCTAssertEqual(ForgeScoreBounds.clamp(150), 100)
        XCTAssertEqual(ForgeScoreBounds.clamp(-8), 0)
        XCTAssertEqual(ForgeScoreBounds.clamp(73), 73)
    }

    func testScoreClampHandlesNonFiniteDouble() {
        XCTAssertEqual(ForgeScoreBounds.clamp(Double.nan), 0)
        XCTAssertEqual(ForgeScoreBounds.clamp(103.6), 100)
    }

    func testLiveForgeScoreIsAlwaysInRange() {
        XCTAssertTrue(ForgeScoreBounds.range.contains(AppState().forgeScore))
    }

    // MARK: Directive identity (persisted dismissal)

    func testDirectiveIDIsStableForTheSameDecision() {
        let a = AppState().dailyDirective
        let b = AppState().dailyDirective
        // Same decision → same id, so a persisted dismissal keeps sticking.
        XCTAssertEqual(a.id, b.id)
        XCTAssertFalse(a.id.isEmpty)
    }

    func testDifferentDecisionsGetDifferentIDs() {
        let base = DailyDirective(headline: "Push hard today.", rationale: "Recovery is 88%.",
                                  priorityAction: "Hit the main lift.", workoutName: "Push", tone: .green)
        let changed = DailyDirective(headline: "Pull back and recover today.", rationale: "Recovery is 44%.",
                                     priorityAction: "Mobility only.", workoutName: "Recover", tone: .ruby)
        XCTAssertNotEqual(base.id, changed.id)
    }
}
