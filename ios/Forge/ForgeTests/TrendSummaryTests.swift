import XCTest
@testable import Forge

/// Trend charts must not be silent to VoiceOver — this is the spoken summary they
/// all share.
final class TrendSummaryTests: XCTestCase {

    func testEmptySeries() {
        XCTAssertEqual(TrendSummary.describe([]), "no data yet")
        XCTAssertEqual(TrendSummary.describe([], context: "Recovery trend"),
                       "Recovery trend: no data yet")
    }

    func testRisingSeries() {
        XCTAssertEqual(TrendSummary.describe([72, 74, 78]),
                       "now 78, up from 72 over 3 points")
    }

    func testFallingSeries() {
        XCTAssertEqual(TrendSummary.describe([80, 76, 70]),
                       "now 70, down from 80 over 3 points")
    }

    func testSingleOrFlatSeriesReadsSteady() {
        XCTAssertEqual(TrendSummary.describe([78]), "steady at 78")
        XCTAssertEqual(TrendSummary.describe([78, 78, 78]), "steady at 78")
    }

    func testContextIsPrefixed() {
        XCTAssertEqual(TrendSummary.describe([72, 78], context: "Recovery trend"),
                       "Recovery trend: now 78, up from 72 over 2 points")
    }

    func testDecimalsRenderCleanly() {
        XCTAssertEqual(TrendSummary.describe([7.2, 7.5]),
                       "now 7.5, up from 7.2 over 2 points")
    }
}
