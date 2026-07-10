import XCTest
@testable import Forge

#if canImport(ActivityKit)
/// The Live Activity's shared content-state helpers — the widget renders
/// exactly these, so they're locked here.
final class WorkoutActivityTests: XCTestCase {

    private func state(done: Int, total: Int, volume: Double = 12_450) -> WorkoutActivityAttributes.ContentState {
        .init(setsDone: done, totalSets: total, volumeLb: volume, restEndsAt: nil, isPR: false)
    }

    func testSetsLabelAndProgress() {
        let s = state(done: 9, total: 15)
        XCTAssertEqual(s.setsLabel, "9/15")
        XCTAssertEqual(s.progress, 0.6, accuracy: 0.001)
    }

    func testZeroTotalSetsNeverDividesByZero() {
        XCTAssertEqual(state(done: 0, total: 0).progress, 0)
    }

    func testVolumeLabelGroupsThousands() {
        XCTAssertEqual(state(done: 1, total: 1, volume: 12450).volumeLabel, "12,450 lb")
    }

    func testControllerIsSafeWithoutAnActivity() async {
        // No activity started: update/end must be silent no-ops, never crashes.
        await WorkoutLiveActivityController.update(
            setsDone: 1, totalSets: 10, volumeLb: 500, restEndsAt: nil)
        await WorkoutLiveActivityController.end()
    }
}
#endif
