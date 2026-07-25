import XCTest
import SwiftData
@testable import Forge

/// Real HealthKit ingestion: the personal-baseline engine (pure) and the daily
/// recovery/sleep persistence that feeds relaunch + cloud sync. The HKHealthStore
/// queries themselves need a device; everything downstream of them is covered here.
final class HealthIngestionTests: XCTestCase {

    // MARK: - HealthBaselineEngine (pure)

    func testMedianOddAndEven() {
        XCTAssertEqual(HealthBaselineEngine.median([3, 1, 2]), 2)
        XCTAssertEqual(HealthBaselineEngine.median([4, 1, 3, 2]), 2.5)
        XCTAssertEqual(HealthBaselineEngine.median([]), 0)
    }

    func testHRVBaselineNeedsEnoughHistory() {
        // 13 days < the 14-day minimum → nil (caller keeps the demo baseline).
        XCTAssertNil(HealthBaselineEngine.hrvBaseline(fromDailyHRV: Array(repeating: 55, count: 13)))
        // 14 days → the median.
        XCTAssertEqual(HealthBaselineEngine.hrvBaseline(fromDailyHRV: Array(repeating: 55, count: 14)), 55)
    }

    func testHRVBaselineUsesMedianAndIgnoresJunk() {
        // A big spike shouldn't drag a median baseline; zeros/negatives are dropped.
        var days = Array(repeating: 50.0, count: 14)
        days.append(300)          // one bad spike
        days.append(0); days.append(-5)   // junk, filtered
        XCTAssertEqual(HealthBaselineEngine.hrvBaseline(fromDailyHRV: days), 50)
    }

    func testSleepDebtSumsShortfallsOverWindow() {
        // 7 nights of 7h vs 8h need → 7h debt.
        XCTAssertEqual(HealthBaselineEngine.sleepDebt(recentNights: Array(repeating: 7, count: 7), need: 8, window: 7)!,
                       7, accuracy: 0.001)
        // A surplus night contributes 0, never negative debt.
        XCTAssertEqual(HealthBaselineEngine.sleepDebt(recentNights: [9, 9, 6], need: 8, window: 7)!,
                       2, accuracy: 0.001)   // only the 6h night is short by 2
        // Only the last `window` nights count.
        XCTAssertEqual(HealthBaselineEngine.sleepDebt(recentNights: [2, 2, 8, 8, 8], need: 8, window: 3)!,
                       0, accuracy: 0.001)   // last 3 are all 8h
    }

    func testSleepDebtEmptyIsNilAndClamped() {
        XCTAssertNil(HealthBaselineEngine.sleepDebt(recentNights: [], need: 8))
        // Extreme deprivation clamps to 40.
        let debt = HealthBaselineEngine.sleepDebt(recentNights: Array(repeating: 0, count: 50), need: 8, window: 50)!
        XCTAssertEqual(debt, 40, accuracy: 0.001)
    }

    func testSleepNeedFallsBackAndIsBounded() {
        XCTAssertEqual(HealthBaselineEngine.sleepNeed(fromNights: [7, 7], minDays: 7), 8.0)          // too few → fallback
        XCTAssertEqual(HealthBaselineEngine.sleepNeed(fromNights: Array(repeating: 7.5, count: 7)), 7.5)
        // Chronic short sleep is floored at 6h, never normalized below.
        XCTAssertEqual(HealthBaselineEngine.sleepNeed(fromNights: Array(repeating: 3, count: 7)), 6.0)
        // Long sleepers capped at 9h.
        XCTAssertEqual(HealthBaselineEngine.sleepNeed(fromNights: Array(repeating: 11, count: 7)), 9.0)
    }

    // MARK: - A real baseline actually changes the recovery estimate

    func testRealBaselineMovesRecoveryOffTheDemoAnchor() {
        // Same live HRV, but computed against the user's own baseline vs Sean's 62.
        let hrv = 58, rhr = 52; let sleep = 7.5
        let againstDemo = RecoveryEstimator.recovery(hrv: hrv, hrvBaseline: 62, restingHR: rhr, sleepHours: sleep)
        let againstOwn  = RecoveryEstimator.recovery(hrv: hrv, hrvBaseline: 48, restingHR: rhr, sleepHours: sleep)
        // A user whose true baseline is 48 is at/above baseline → higher recovery
        // than being measured against the demo athlete's higher 62 baseline.
        XCTAssertGreaterThan(againstOwn, againstDemo)
    }

    // MARK: - Daily snapshot persistence (feeds relaunch + sync)

    @MainActor private func store() throws -> ModelContext {
        let c = try ModelContainer(
            for: RecoveryRecord.self, SleepRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(c)
    }

    @MainActor
    func testRecoveryUpsertIsOneRowPerDayAndSyncPending() throws {
        let ctx = try store()
        PersistenceService.upsertRecoveryRecord(recovery: 70, hrv: 55, restingHR: 52, strain: 12, context: ctx)
        var rows = try ctx.fetch(FetchDescriptor<RecoveryRecord>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.recovery, 70)
        XCTAssertTrue(rows.first?.syncPending ?? false)

        // Re-ingesting later today updates the SAME row, not a second one.
        PersistenceService.upsertRecoveryRecord(recovery: 81, hrv: 60, restingHR: 50, strain: 14, context: ctx)
        rows = try ctx.fetch(FetchDescriptor<RecoveryRecord>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.recovery, 81)
        XCTAssertEqual(rows.first?.hrv, 60)
        XCTAssertTrue(rows.first?.syncPending ?? false, "an update re-marks it dirty for sync")
    }

    @MainActor
    func testSleepUpsertIsOneRowPerDay() throws {
        let ctx = try store()
        PersistenceService.upsertSleepRecord(hours: 7.1, deepHours: 1.2, remHours: 1.5, score: 78, context: ctx)
        PersistenceService.upsertSleepRecord(hours: 8.0, deepHours: 1.5, remHours: 1.8, score: 88, context: ctx)
        let rows = try ctx.fetch(FetchDescriptor<SleepRecord>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.hours, 8.0)
        XCTAssertEqual(rows.first?.score, 88)
    }
}
