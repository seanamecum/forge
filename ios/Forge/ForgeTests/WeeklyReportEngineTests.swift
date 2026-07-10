import XCTest
@testable import Forge

final class WeeklyReportEngineTests: XCTestCase {

    private func make(recovery: [Double] = Array(repeating: 75, count: 14),
                      sleep: [Double] = Array(repeating: 8, count: 14),
                      strain: [Double] = Array(repeating: 12, count: 14),
                      hrv: [Double] = Array(repeating: 60, count: 14),
                      streak: Int = 10,
                      lever: String = "Sleep is your biggest lever — up to +4 points on the table.") -> WeeklyReport {
        WeeklyReportEngine.make(recovery: recovery, sleep: sleep, strain: strain,
                                hrv: hrv, streakDays: streak, lever: lever)
    }

    func testAveragesAndWeekOverWeekDeltas() {
        let recovery = Array(repeating: 70.0, count: 7) + Array(repeating: 76.0, count: 7)
        let hrv = Array(repeating: 58.0, count: 7) + Array(repeating: 61.0, count: 7)
        let report = make(recovery: recovery, hrv: hrv)
        XCTAssertEqual(report.recoveryAvg, 76)
        XCTAssertEqual(report.recoveryDelta, 6)
        XCTAssertEqual(report.hrvDelta, 3)
    }

    func testSleepDebtCountsOnlyShortfalls() {
        // 7.0 + 9.0 alternating vs 8h target: debt = 4×1h shortfall nights... last 7 = [7,9,7,9,7,9,7] → 4h
        let sleep = Array(repeating: 8.0, count: 7) + [7, 9, 7, 9, 7, 9, 7]
        let report = make(sleep: sleep)
        XCTAssertEqual(report.sleepDebtHours, 4.0, accuracy: 0.001)
        XCTAssertEqual(report.sleepConsistency, "Erratic")
    }

    func testCleanWeekHasWinsAndNoWatchouts() {
        let report = make(recovery: Array(repeating: 70.0, count: 7) + Array(repeating: 74.0, count: 7))
        XCTAssertFalse(report.wins.isEmpty)
        XCTAssertTrue(report.watchouts.isEmpty, "A clean week must read clean: \(report.watchouts)")
        XCTAssertEqual(report.verdict, "You gained ground this week.")
    }

    func testRoughWeekSurfacesWatchouts() {
        let report = make(
            recovery: Array(repeating: 78.0, count: 7) + Array(repeating: 70.0, count: 7),
            sleep: Array(repeating: 8.0, count: 7) + Array(repeating: 6.5, count: 7),
            strain: Array(repeating: 12.0, count: 7) + [18, 18, 12, 17.5, 12, 12, 12])
        XCTAssertTrue(report.watchouts.contains { $0.contains("sleep debt") })
        XCTAssertTrue(report.watchouts.contains { $0.contains("slipped") })
        XCTAssertTrue(report.watchouts.contains { $0.contains("high-strain") })
        XCTAssertTrue(report.verdict.contains("took more"))
    }

    func testBigSleepDebtOwnsTheFocus() {
        let report = make(sleep: Array(repeating: 8.0, count: 7) + Array(repeating: 7.0, count: 7))
        XCTAssertTrue(report.nextFocus.contains("lights-out"),
                      "7h of debt must make sleep the one focus, not the generic lever")
    }

    func testFocusFallsBackToScoreLever() {
        let report = make(lever: "Hydration is your biggest lever — up to +3 points on the table.")
        XCTAssertTrue(report.nextFocus.contains("hydration is your biggest lever"))
    }

    func testShortHistoryDegradesGracefully() {
        let report = make(recovery: [70, 72, 74], sleep: [7.5, 8, 7], strain: [12], hrv: [60])
        XCTAssertEqual(report.recoveryDelta, 0, "No comparison week → no fabricated delta")
        XCTAssertFalse(report.wins.isEmpty)
        XCTAssertFalse(report.verdict.isEmpty)
    }

    func testAppStateWiresTheReport() {
        let app = AppState()
        let report = app.weeklyReport
        XCTAssertGreaterThan(report.recoveryAvg, 0)
        XCTAssertFalse(report.nextFocus.isEmpty)
    }
}
