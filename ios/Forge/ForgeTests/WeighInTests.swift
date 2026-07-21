import XCTest
import SwiftData
@testable import Forge

/// Real users get their own persistent weight history, and adaptive nutrition uses
/// it — never demo data. Demo mode is preserved separately.
final class WeighInTests: XCTestCase {

    /// A fresh in-memory store so the tests never touch the app's shared container
    /// (also proves the WeightRecord model + schema addition — the migration path).
    @MainActor private func freshContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: WeightRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    // MARK: Persistence / migration

    @MainActor
    func testWeightRecordPersistsAndFetches() throws {
        let ctx = try freshContext()
        PersistenceService.saveWeight(178.5, context: ctx)
        let fetched = try ctx.fetch(FetchDescriptor<WeightRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.weightLb, 178.5)
    }

    // MARK: Demo vs real — never mixed

    func testDemoModeUsesTheDemoTrendRealDoesNot() {
        let demo = AppState(); demo.completeAuth(demo: true)
        XCTAssertEqual(demo.weightTrend, MockData.weightTrend)
        XCTAssertEqual(demo.latestWeight, MockData.weightTrend.last)

        let real = AppState(); real.completeAuth(demo: false)
        XCTAssertTrue(real.weightTrend.isEmpty)      // no weigh-ins yet
        XCTAssertNil(real.latestWeight)
    }

    // MARK: Logging — persists, rescales targets, refreshes the plan

    @MainActor
    func testLogWeightPersistsAppendsAndRescalesTargets() throws {
        let ctx = try freshContext()
        let app = AppState(); app.completeAuth(demo: false)
        let beforeCalories = app.user.calorieTarget      // at Sean's 200 lb
        app.logWeight(180, context: ctx)
        XCTAssertEqual(app.weightSamples.last, 180)
        XCTAssertEqual(app.user.weightLb, 180)           // profile weight follows the weigh-in
        XCTAssertLessThan(app.user.calorieTarget, beforeCalories)   // lighter → fewer calories
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<WeightRecord>()).count, 1)
    }

    @MainActor
    func testLogWeightIgnoresNonPositive() throws {
        let ctx = try freshContext()
        let app = AppState(); app.completeAuth(demo: false)
        app.logWeight(0, context: ctx)
        app.logWeight(-5, context: ctx)
        XCTAssertTrue(app.weightSamples.isEmpty)
    }

    // MARK: Adaptive nutrition uses the real trend

    @MainActor
    func testEnoughFlatWeighInsTriggerTheBuildMuscleNudge() throws {
        let ctx = try freshContext()
        let app = AppState(); app.completeAuth(demo: false)
        app.user.goals = [.buildMuscle]
        for _ in 0..<12 { app.logWeight(180, context: ctx) }   // flat trend, 12 samples
        XCTAssertTrue(app.nutrition.activePlan?.adjustments.contains { $0.id == "stalled-gain" } ?? false)
    }

    func testRealUserWithNoWeighInsGetsNoWeightAdjustment() {
        let app = AppState(); app.completeAuth(demo: false)
        app.refreshFuelPlan()
        let ids = app.nutrition.activePlan?.adjustments.map(\.id) ?? []
        XCTAssertFalse(ids.contains("stalled-gain"))
        XCTAssertFalse(ids.contains("plateau-cut"))
    }

    @MainActor
    func testTooFewWeighInsStillGraceful() throws {
        let ctx = try freshContext()
        let app = AppState(); app.completeAuth(demo: false)
        app.user.goals = [.buildMuscle]
        for _ in 0..<3 { app.logWeight(180, context: ctx) }    // < 10 → no trend judgement yet
        XCTAssertFalse(app.nutrition.activePlan?.adjustments.contains { $0.id == "stalled-gain" } ?? false)
        XCTAssertEqual(app.weightTrend.count, 3)
    }
}
