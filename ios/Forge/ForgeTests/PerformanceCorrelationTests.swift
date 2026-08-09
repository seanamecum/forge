import XCTest
@testable import Forge

/// The cross-domain analytical engine of the unified user model — finds honest,
/// explainable relationships across domains (weekday patterns, behavior→outcome,
/// paired correlation) and stays silent below data-sufficiency thresholds.
final class PerformanceCorrelationTests: XCTestCase {

    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    /// Build a daily series over the last `weeks` weeks; `value(weekday)` sets each day.
    private func series(weeks: Int, from ref: Date, value: (Int) -> Double) -> [DayValue] {
        var out: [DayValue] = []
        for d in 0..<(weeks * 7) {
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: -d, to: ref)!)
            out.append(DayValue(day: day, value: value(cal.component(.weekday, from: day))))
        }
        return out
    }

    private var ref: Date { cal.date(from: DateComponents(year: 2026, month: 3, day: 4, hour: 12))! }

    // MARK: - Weekday pattern ("Why Thursdays?")

    func testDetectsALowWeekday() {
        // Recovery ~80 all week, but Thursdays (weekday 5) run ~68.
        let s = series(weeks: 6, from: ref) { $0 == 5 ? 68 : 80 }
        let insights = PerformanceCorrelation.weekdayPattern(s, calendar: cal)
        let thursday = insights.first!         // sorted by |delta|, Thursday is the outlier
        XCTAssertEqual(thursday.name, "Thursday")
        XCTAssertTrue(thursday.notable)
        XCTAssertLessThan(thursday.deltaPct, 0)   // below average
        XCTAssertGreaterThanOrEqual(thursday.samples, 6)
    }

    func testFlatWeekHasNoNotableWeekday() {
        let s = series(weeks: 6, from: ref) { _ in 80 }
        XCTAssertFalse(PerformanceCorrelation.weekdayPattern(s, calendar: cal).contains { $0.notable })
    }

    func testWeekdayNeedsEnoughData() {
        // Only a few days total → nothing reported.
        let s = Array(series(weeks: 6, from: ref) { _ in 80 }.prefix(2))
        XCTAssertTrue(PerformanceCorrelation.weekdayPattern(s, calendar: cal).isEmpty)
    }

    // MARK: - Behavior → outcome ("What habit hurts recovery?")

    func testBehaviorLowersOutcome() {
        // Recovery is 82 normally, but 70 the day AFTER a "low-carb" day.
        var lowCarbDays: Set<Date> = []
        var outcome: [DayValue] = []
        for d in 0..<28 {
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: -d, to: ref)!)
            let isLowCarb = d % 4 == 0                // every 4th day
            if isLowCarb { lowCarbDays.insert(day) }
            // The NEXT day's recovery is lower after a low-carb day.
            let prevWasLowCarb = (d + 1) % 4 == 0
            outcome.append(DayValue(day: day, value: prevWasLowCarb ? 70 : 82))
        }
        let impact = PerformanceCorrelation.behaviorImpact(behaviorDays: lowCarbDays, outcome: outcome, lagDays: 1, calendar: cal)!
        XCTAssertTrue(impact.isMeaningful)
        XCTAssertLessThan(impact.deltaPct, 0)                     // recovery lower after low-carb
        XCTAssertGreaterThanOrEqual(impact.behaviorSamples, 3)
        XCTAssertGreaterThanOrEqual(impact.baselineSamples, 3)
    }

    func testBehaviorWithNoEffectIsNotMeaningful() {
        var days: Set<Date> = []; var outcome: [DayValue] = []
        for d in 0..<28 {
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: -d, to: ref)!)
            if d % 4 == 0 { days.insert(day) }
            outcome.append(DayValue(day: day, value: 80))        // constant → no effect
        }
        let impact = PerformanceCorrelation.behaviorImpact(behaviorDays: days, outcome: outcome, calendar: cal)!
        XCTAssertFalse(impact.isMeaningful)
        XCTAssertEqual(impact.deltaPct, 0, accuracy: 1e-9)
    }

    func testBehaviorNeedsEnoughSamples() {
        let day = cal.startOfDay(for: ref)
        let impact = PerformanceCorrelation.behaviorImpact(
            behaviorDays: [day],
            outcome: [DayValue(day: day, value: 70), DayValue(day: cal.date(byAdding: .day, value: -1, to: day)!, value: 80)],
            calendar: cal)
        XCTAssertNil(impact)                                      // too few days → honest silence
    }

    // MARK: - Paired correlation

    func testPairedCorrelationOfSleepAndRecovery() {
        // Recovery tracks sleep closely → strong positive correlation.
        var sleep: [DayValue] = []; var recovery: [DayValue] = []
        for d in 0..<14 {
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: -d, to: ref)!)
            let h = 6.0 + Double(d % 4) * 0.5
            sleep.append(DayValue(day: day, value: h))
            recovery.append(DayValue(day: day, value: 60 + (h - 6) * 20))   // linear in sleep
        }
        let r = PerformanceCorrelation.correlation(sleep, recovery, calendar: cal)!
        XCTAssertGreaterThan(r, 0.95)
    }

    func testCorrelationNeedsEnoughPairedPoints() {
        let a = (0..<4).map { DayValue(day: cal.date(byAdding: .day, value: -$0, to: ref)!, value: Double($0)) }
        XCTAssertNil(PerformanceCorrelation.correlation(a, a, calendar: cal))   // < min paired points
    }

    func testPearsonBasics() {
        XCTAssertEqual(PerformanceCorrelation.pearson([1, 2, 3], [2, 4, 6])!, 1.0, accuracy: 1e-9)
        XCTAssertEqual(PerformanceCorrelation.pearson([1, 2, 3], [6, 4, 2])!, -1.0, accuracy: 1e-9)
        XCTAssertNil(PerformanceCorrelation.pearson([1, 1, 1], [2, 4, 6]))     // no variance → nil
    }
}
