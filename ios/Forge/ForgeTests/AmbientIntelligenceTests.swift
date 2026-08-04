import XCTest
@testable import Forge

/// Ambient intelligence surfaced from real state: honest generators, curated to a
/// calm one-or-two, and dismissals that persist so nothing nags.
final class AmbientIntelligenceTests: XCTestCase {

    // MARK: - Generators (honest thresholds)

    func testProteinShortOnlyWhenMateriallyShort() {
        XCTAssertNotNil(InsightGenerators.proteinShort(remaining: 40, target: 180))
        XCTAssertNil(InsightGenerators.proteinShort(remaining: 10, target: 180))     // basically there
        XCTAssertNil(InsightGenerators.proteinShort(remaining: 40, target: 0))       // no target
        let i = InsightGenerators.proteinShort(remaining: 35, target: 180)!
        XCTAssertTrue(i.title.contains("35 g"))
        XCTAssertFalse(i.reason.isEmpty)                                             // explainable
    }

    func testRecoveryVsNormalOnlyWhenNotablyLow() {
        XCTAssertNotNil(InsightGenerators.recoveryVsNormal(today: 60, usual: 80))
        XCTAssertNil(InsightGenerators.recoveryVsNormal(today: 78, usual: 80))       // within normal
        XCTAssertNil(InsightGenerators.recoveryVsNormal(today: 60, usual: 0))        // no baseline
    }

    func testOtherGeneratorsGate() {
        XCTAssertNotNil(InsightGenerators.hydrationLow(daysBelowTarget: 3))
        XCTAssertNil(InsightGenerators.hydrationLow(daysBelowTarget: 2))
        XCTAssertNotNil(InsightGenerators.trainingLoadPeak(weeksTracked: 6, isHighest: true))
        XCTAssertNil(InsightGenerators.trainingLoadPeak(weeksTracked: 6, isHighest: false))
        XCTAssertNotNil(InsightGenerators.sleepTrendingDown(slopePerDay: -0.3))
        XCTAssertNil(InsightGenerators.sleepTrendingDown(slopePerDay: -0.05))
        XCTAssertNotNil(InsightGenerators.goalPace(daysEarly: 5))
        XCTAssertNil(InsightGenerators.goalPace(daysEarly: 1))
    }

    // MARK: - Dismissal persistence

    func testDismissalStorePersistsAndSuppresses() {
        let suite = UserDefaults(suiteName: "ambient-test-\(UUID())")!
        let store = DismissalStore(defaults: suite)
        XCTAssertFalse(store.load().isSuppressed("x", now: .now))
        store.recordDismissal("x", at: .now)
        // A fresh store over the same suite still sees the dismissal (persisted).
        XCTAssertTrue(DismissalStore(defaults: suite).load().isSuppressed("x", now: .now))
    }

    // MARK: - AppState assembly + curation + dismissal

    @MainActor
    func testHomeSurfacesAtMostOneCalmInsight() {
        UserDefaults.standard.removeObject(forKey: "forge.insights.dismissed.v1")
        let app = AppState(); app.completeAuth(demo: false)
        app.nutrition.entries = []                        // nothing logged → protein wide open
        let insights = app.ambientInsights()
        XCTAssertLessThanOrEqual(insights.count, 1)       // calm: one at a time on Home
        XCTAssertTrue(insights.allSatisfy { !$0.reason.isEmpty })   // every one explainable
    }

    @MainActor
    func testDismissingAnInsightSuppressesIt() {
        UserDefaults.standard.removeObject(forKey: "forge.insights.dismissed.v1")
        let app = AppState(); app.completeAuth(demo: false)
        app.nutrition.entries = []
        guard let first = app.ambientInsights().first else { return }   // protein-short expected
        // Dismiss it enough to trigger suppression, then it's gone.
        for _ in 0..<3 { app.dismissInsight(id: first.id) }
        XCTAssertFalse(app.ambientInsights().contains { $0.id == first.id })
        UserDefaults.standard.removeObject(forKey: "forge.insights.dismissed.v1")   // cleanup
    }
}
