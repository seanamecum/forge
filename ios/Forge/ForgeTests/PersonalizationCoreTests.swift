import XCTest
@testable import Forge

/// The unified personalization core (`HabitScore`) — the reusable habit-scoring math
/// that every Forge domain plugs into. Nutrition's Smart Meal Memory now sits on it
/// (behavior-preserving; the MealMemoryTests remain the regression guard).
final class PersonalizationCoreTests: XCTestCase {

    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private var now: Date { cal.date(from: DateComponents(year: 2026, month: 3, day: 4, hour: 12))! }

    // MARK: - Profile

    func testProfileSummarizesTimes() {
        let days = [1, 2, 3, 4, 5].map { cal.date(byAdding: .day, value: -$0, to: cal.date(bySettingHour: 8, minute: 0, second: 0, of: now)!)! }
        let p = HabitScore.profile(occurrenceTimes: days, now: now, calendar: cal)!
        XCTAssertEqual(p.occurrences, 5)
        XCTAssertEqual(p.typicalHour, 8)
        XCTAssertEqual(p.lastSeen, days.max())
        XCTAssertNil(HabitScore.profile(occurrenceTimes: [], now: now, calendar: cal))
    }

    func testProfileWeekdayBias() {
        // Build times on known weekdays vs weekend. 2026-03-04 is a Wednesday.
        func at(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: 8))! }
        let weekdays = [at(2026,3,2), at(2026,3,3), at(2026,3,4)]         // Mon/Tue/Wed
        XCTAssertEqual(HabitScore.profile(occurrenceTimes: weekdays, now: now, calendar: cal)?.weekdayBias, .weekday)
        let weekend = [at(2026,2,28), at(2026,3,1)]                       // Sat/Sun
        XCTAssertEqual(HabitScore.profile(occurrenceTimes: weekend, now: now, calendar: cal)?.weekdayBias, .weekend)
    }

    // MARK: - Signal shapes

    func testFrequencyMonotonicAndBounded() {
        XCTAssertEqual(HabitScore.frequency(0), 0, accuracy: 1e-9)
        XCTAssertGreaterThan(HabitScore.frequency(10), HabitScore.frequency(3))
        XCTAssertLessThanOrEqual(HabitScore.frequency(1000), 1.0)
    }

    func testRecencyFadesWithTime() {
        let fresh = cal.date(byAdding: .day, value: -1, to: now)!
        let old = cal.date(byAdding: .day, value: -20, to: now)!
        XCTAssertEqual(HabitScore.recency(lastSeen: fresh, now: now, calendar: cal), 1, accuracy: 1e-9)
        XCTAssertLessThan(HabitScore.recency(lastSeen: old, now: now, calendar: cal), 0.5)
        XCTAssertGreaterThanOrEqual(HabitScore.recency(lastSeen: old, now: now, calendar: cal), 0.3)  // floor
    }

    func testTimeOfDayPeaksAtTypicalHourAndWrapsMidnight() {
        XCTAssertEqual(HabitScore.timeOfDay(typicalHour: 8, nowHour: 8, strongContext: false), 1, accuracy: 1e-9)
        XCTAssertLessThan(HabitScore.timeOfDay(typicalHour: 8, nowHour: 14, strongContext: false),
                          HabitScore.timeOfDay(typicalHour: 8, nowHour: 9, strongContext: false))
        // 23:00 and 01:00 are 2 h apart, not 22.
        XCTAssertEqual(HabitScore.timeOfDay(typicalHour: 23, nowHour: 1, strongContext: false),
                       HabitScore.timeOfDay(typicalHour: 1, nowHour: 23, strongContext: false), accuracy: 1e-9)
        // Strong context floors the score.
        XCTAssertGreaterThanOrEqual(HabitScore.timeOfDay(typicalHour: 8, nowHour: 20, strongContext: true), 0.6)
    }

    func testWeekdayFit() {
        XCTAssertEqual(HabitScore.weekday(bias: .any, isWeekend: true), 1)
        XCTAssertEqual(HabitScore.weekday(bias: .weekday, isWeekend: false), 1)
        XCTAssertEqual(HabitScore.weekday(bias: .weekday, isWeekend: true), 0.5)
        XCTAssertEqual(HabitScore.weekday(bias: .weekend, isWeekend: true), 1)
    }

    // MARK: - Settings (user control)

    func testSettingsControlPerDomain() {
        var s = PersonalizationSettings.allOn
        XCTAssertTrue(s.isEnabled(.nutrition))
        s.disabledDomains.insert(.coaching)
        XCTAssertFalse(s.isEnabled(.coaching))
        XCTAssertTrue(s.isEnabled(.training))
        XCTAssertEqual(PersonalizationDomain.allCases.count, 10)
    }
}
