import XCTest
import SwiftData
@testable import Forge

/// Two launch-critical correctness guarantees:
///  1. Trend charts show the athlete's OWN history — a real user never sees the
///     demo athlete's recovery/HRV/sleep/Forge-Score trend.
///  2. Demo interactions (food, water, weigh-ins) NEVER persist or sync — they
///     can't leak into a real account's cloud data.
final class TrendAndDemoLeakTests: XCTestCase {

    // MARK: - TrendBuilder (pure)

    func testTrendBuilderMapsAndPreservesOrder() {
        let s = TrendBuilder.make(recovery: [60, 70, 80], hrv: [50, 55, 60],
                                  sleepHours: [7, 7.5, 8], strain: [10, 12, 14], scores: [65, 72, 78])
        XCTAssertEqual(s.recovery, [60, 70, 80])
        XCTAssertEqual(s.hrv, [50, 55, 60])
        XCTAssertEqual(s.forgeScore, [65, 72, 78])
        XCTAssertTrue(s.hasEnoughToShow)
    }

    func testTrendBuilderEmptyIsHonestlyEmpty() {
        let s = TrendBuilder.make(recovery: [], hrv: [], sleepHours: [], strain: [], scores: [])
        XCTAssertTrue(s.recovery.isEmpty)
        XCTAssertFalse(s.hasEnoughToShow)   // nothing to chart yet
    }

    func testHasEnoughNeedsMinPoints() {
        let two = TrendBuilder.make(recovery: [60, 70], hrv: [], sleepHours: [], strain: [], scores: [])
        XCTAssertFalse(two.hasEnoughToShow)
        let three = TrendBuilder.make(recovery: [60, 70, 80], hrv: [], sleepHours: [], strain: [], scores: [])
        XCTAssertTrue(three.hasEnoughToShow)
    }

    // MARK: - Demo vs real trends never mix

    @MainActor
    func testDemoAccountShowsSeededTrendsRealDoesNot() {
        let demo = AppState(); demo.completeAuth(demo: true)
        XCTAssertFalse(demo.recovery.trendsAreLive)
        XCTAssertEqual(demo.recovery.trends.first { $0.name == "Recovery" }?.values, MockData.recoveryTrend)
        XCTAssertEqual(demo.recovery.forgeScoreTrend, MockData.forgeScoreTrend)

        let real = AppState(); real.completeAuth(demo: false)
        XCTAssertTrue(real.recovery.trendsAreLive)          // its own series, even if empty
        // A brand-new real account has no history → empty, NOT the demo trend.
        XCTAssertNotEqual(real.recovery.trends.first { $0.name == "Recovery" }?.values, MockData.recoveryTrend)
        XCTAssertTrue(real.recovery.forgeScoreTrend.isEmpty || real.recovery.forgeScoreTrend != MockData.forgeScoreTrend)
    }

    @MainActor
    func testSwitchingBackToDemoRestoresSeededTrends() {
        let app = AppState()
        app.completeAuth(demo: false)
        XCTAssertTrue(app.recovery.trendsAreLive)
        app.completeAuth(demo: true)
        XCTAssertFalse(app.recovery.trendsAreLive)          // demo seed restored
        XCTAssertEqual(app.recovery.forgeScoreTrend, MockData.forgeScoreTrend)
    }

    @MainActor
    func testRealTrendsBuildFromPersistedRecords() {
        // Seed the shared store with this account's own daily snapshots, then rebuild.
        let ctx = PersistenceService.context
        try? ctx.delete(model: RecoveryRecord.self)
        try? ctx.delete(model: ScoreRecord.self)
        try? ctx.save()
        for i in 0..<5 {
            ctx.insert(RecoveryRecord(date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!,
                                      recovery: 60 + i, hrv: 50 + i, restingHR: 52, strain: 10 + Double(i)))
        }
        try? ctx.save()

        let app = AppState(); app.completeAuth(demo: false)
        app.refreshTrends()
        let rec = app.recovery.trends.first { $0.name == "Recovery" }?.values ?? []
        XCTAssertEqual(rec.count, 5)
        XCTAssertNotEqual(rec, MockData.recoveryTrend)

        // cleanup
        try? ctx.delete(model: RecoveryRecord.self); try? ctx.save()
    }

    // MARK: - Demo interactions never persist (data-leak guard)

    @MainActor
    func testDemoFoodAndWaterDoNotPersist() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: NutritionEntryRecord.self); try? ctx.save()

        let app = AppState(); app.completeAuth(demo: true)
        XCTAssertTrue(app.nutrition.isDemo)
        let food = Food(id: "probe", name: "Probe Bar", serving: "1", calories: 200, protein: 20, carbs: 10, fat: 5)
        app.nutrition.add(food: food, to: .snack)
        app.nutrition.addWater(16)

        // Shown in the in-memory demo view…
        XCTAssertTrue(app.nutrition.entries.contains { $0.food.name == "Probe Bar" })
        // …but NOTHING reached the persistent store.
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<NutritionEntryRecord>()).isEmpty)
    }

    @MainActor
    func testDemoWeighInDoesNotPersistButRealDoes() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: WeightRecord.self); try? ctx.save()

        let demo = AppState(); demo.completeAuth(demo: true)
        demo.logWeight(185, context: ctx)
        XCTAssertEqual(demo.user.weightLb, 185)                        // in-memory update ok
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<WeightRecord>()).isEmpty)   // not persisted

        let real = AppState(); real.completeAuth(demo: false)
        real.logWeight(180, context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<WeightRecord>()).count, 1) // real persists

        try? ctx.delete(model: WeightRecord.self); try? ctx.save()
    }

    @MainActor
    func testDemoRecordsAreNotCollectedForSync() throws {
        let ctx = PersistenceService.context
        try? ctx.delete(model: NutritionEntryRecord.self)
        try? ctx.delete(model: WeightRecord.self); try? ctx.save()

        let app = AppState(); app.completeAuth(demo: true)
        app.nutrition.add(food: Food(id: "p", name: "Demo Food", serving: "1", calories: 100, protein: 5, carbs: 5, fat: 2), to: .lunch)
        app.logWeight(190, context: ctx)

        // The sync engine must find nothing to push from a demo session.
        let pending = SyncEngine.collectPending(context: ctx)
        XCTAssertTrue(pending.filter { $0.kind == "nutrition" || $0.kind == "weight" }.isEmpty,
                      "demo food/weight must never enter the sync push set")
    }
}
