import XCTest
@testable import Forge

final class StreakEngineTests: XCTestCase {
    private let cal = Calendar.current
    private func day(_ offset: Int, from ref: Date = .now) -> Date {
        cal.date(byAdding: .day, value: offset, to: ref)!
    }

    // MARK: - Timezone / DST reliability (audit Phase 9/10)

    private func fixedCal(_ tz: String) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: tz)!
        return c
    }
    private func at(_ cal: Calendar, _ y: Int, _ m: Int, _ d: Int, _ h: Int = 15) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testStreakSurvivesFallBackDST() {
        // US 2025 fall-back is Nov 2 (a 25-hour day). Three consecutive calendar
        // days across it must still read as a 3-day streak.
        let cal = fixedCal("America/New_York")
        let days = [at(cal, 2025, 11, 1), at(cal, 2025, 11, 2), at(cal, 2025, 11, 3)]
        XCTAssertEqual(StreakEngine.streak(days: days, today: at(cal, 2025, 11, 3), calendar: cal), 3)
    }

    func testStreakSurvivesSpringForwardDST() {
        // US 2025 spring-forward is Mar 9 (a 23-hour day).
        let cal = fixedCal("America/New_York")
        let days = [at(cal, 2025, 3, 8), at(cal, 2025, 3, 9), at(cal, 2025, 3, 10)]
        XCTAssertEqual(StreakEngine.streak(days: days, today: at(cal, 2025, 3, 10), calendar: cal), 3)
    }

    func testStreakCountsCalendarDaysNotRaw24Hours() {
        // 23:00 then 01:00 next day are only 2h apart but are DIFFERENT calendar
        // days → streak 2. Raw 24h arithmetic would wrongly collapse them.
        let cal = fixedCal("Europe/London")
        let days = [at(cal, 2025, 6, 1, 23), at(cal, 2025, 6, 2, 1)]
        XCTAssertEqual(StreakEngine.streak(days: days, today: at(cal, 2025, 6, 2, 1), calendar: cal), 2)
    }

    func testStreakIsConsistentInANonDefaultTimezone() {
        let tokyo = fixedCal("Asia/Tokyo")
        let days = [at(tokyo, 2025, 6, 1), at(tokyo, 2025, 6, 2), at(tokyo, 2025, 6, 3)]
        XCTAssertEqual(StreakEngine.streak(days: days, today: at(tokyo, 2025, 6, 3), calendar: tokyo), 3)
    }

    // MARK: - Core semantics

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
