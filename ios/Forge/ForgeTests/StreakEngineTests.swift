import XCTest
@testable import Forge

final class StreakEngineTests: XCTestCase {
    private let cal = Calendar.current
    private func day(_ offset: Int, from ref: Date = .now) -> Date {
        cal.date(byAdding: .day, value: offset, to: ref)!
    }

    func testUnbrokenRunEndingToday() {
        let days = [day(0), day(-1), day(-2)]
        XCTAssertEqual(StreakEngine.streak(days: days), 3)
    }

    func testTodayMissingCountsFromYesterday() {
        // Opened every day through yesterday; today just hasn't happened yet.
        let days = [day(-1), day(-2), day(-3)]
        XCTAssertEqual(StreakEngine.streak(days: days), 3)
    }

    func testFullMissedDayBreaksTheStreak() {
        let days = [day(-2), day(-3)]
        XCTAssertEqual(StreakEngine.streak(days: days), 0)
    }

    func testGapOnlyCountsTheRecentRun() {
        let days = [day(0), day(-1), day(-3), day(-4), day(-5)]
        XCTAssertEqual(StreakEngine.streak(days: days), 2)
    }

    func testDuplicatesAndDisorderAreHarmless() {
        let days = [day(-1), day(0), day(0), day(-1)]
        XCTAssertEqual(StreakEngine.streak(days: days), 2)
    }

    func testEmptyIsZero() {
        XCTAssertEqual(StreakEngine.streak(days: []), 0)
    }
}
