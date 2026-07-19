import XCTest
@testable import Forge

/// The flagship metric's maths, now tested directly (not only via AppState).
final class ForgeScoreEngineTests: XCTestCase {

    private func breakdown(all v: Int) -> [ScoreComponent] {
        ForgeScoreEngine.breakdown(sleep: v, recovery: v, nutrition: v, hydration: v,
                                   trainingLoad: v, activity: v, stress: v, injury: v)
    }

    func testWeightsSumToOne() {
        let total = breakdown(all: 50).reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    func testEightComponentsWithExpectedLabels() {
        let labels = breakdown(all: 50).map(\.label)
        XCTAssertEqual(labels.count, 8)
        XCTAssertEqual(Set(labels), ["Sleep", "Recovery (HRV)", "Nutrition", "Hydration",
                                     "Training Load", "Activity", "Stress", "Injury Status"])
    }

    func testAllEqualComponentsScoreToThatValue() {
        // Since weights sum to 1.0, a uniform breakdown scores to the component value.
        XCTAssertEqual(ForgeScoreEngine.score(breakdown(all: 80)), 80)
        XCTAssertEqual(ForgeScoreEngine.score(breakdown(all: 0)), 0)
        XCTAssertEqual(ForgeScoreEngine.score(breakdown(all: 100)), 100)
    }

    func testOutOfRangeComponentsCannotEscapeBounds() {
        XCTAssertEqual(ForgeScoreEngine.score(breakdown(all: 150)), 100)   // clamped high
        XCTAssertEqual(ForgeScoreEngine.score(breakdown(all: -40)), 0)     // clamped low
    }

    func testComponentValuesPassThrough() {
        let b = ForgeScoreEngine.breakdown(sleep: 10, recovery: 20, nutrition: 30, hydration: 40,
                                           trainingLoad: 50, activity: 60, stress: 70, injury: 80)
        XCTAssertEqual(b.first { $0.label == "Sleep" }?.value, 10)
        XCTAssertEqual(b.first { $0.label == "Injury Status" }?.value, 80)
    }

    func testMatchesAppStateComputation() {
        // The extraction is behaviour-preserving: AppState's score equals the engine's
        // over AppState's own breakdown.
        let app = AppState()
        XCTAssertEqual(app.forgeScore, ForgeScoreEngine.score(app.forgeScoreBreakdown))
    }
}
