import XCTest
@testable import Forge

final class InsightEngineTests: XCTestCase {

    // MARK: - Recovery attribution

    func testRecoveryDriversDecomposeTheScore() {
        let drivers = InsightEngine.recoveryDrivers(
            recovery: 78,
            sleepHours: 7.2, sleepReference: 8.5,
            hrv: 58, hrvBaseline: 62,
            strainYesterday: 14.2, strainAvg: 14.0,
            restingHR: 56, restingHRBaseline: 52,
            magnesiumPct: 52, magnesiumDaysLow: 6)

        let factors = drivers.map(\.factor)
        XCTAssertTrue(factors.contains("Sleep"))
        XCTAssertTrue(factors.contains("HRV"))
        XCTAssertTrue(factors.contains("Magnesium"))
        // Ordered by magnitude — the sleep shortfall is the biggest single driver here.
        XCTAssertEqual(drivers.first?.factor, "Sleep")
        // The sleep shortfall is hurting recovery, not helping it.
        XCTAssertEqual(drivers.first { $0.factor == "Sleep" }?.positive, false)
        // HRV detail carries the signed delta.
        XCTAssertTrue(drivers.first { $0.factor == "HRV" }?.detail.contains("-4ms") ?? false)
    }

    func testGoodSleepAndHrvArePositiveDrivers() {
        let drivers = InsightEngine.recoveryDrivers(
            recovery: 90,
            sleepHours: 8.9, sleepReference: 8.5,
            hrv: 66, hrvBaseline: 62,
            strainYesterday: 10, strainAvg: 14,
            restingHR: 50, restingHRBaseline: 52,
            magnesiumPct: 100, magnesiumDaysLow: 0)
        XCTAssertTrue(drivers.contains { $0.factor == "Sleep" && $0.positive })
        XCTAssertTrue(drivers.contains { $0.factor == "HRV" && $0.positive })
    }

    // MARK: - Cross-module chains

    func testCrossModuleChainsConnectModules() {
        let insights = InsightEngine.crossModule(
            recovery: 78, sleepDebtHours: 3.1,
            hrv: 58, hrvBaseline: 62,
            proteinRemaining: 72, hydrationPct: 62,
            injuryName: "Knee", injuryPhase: "Phase 2", injuryPain: 2,
            injuryRiskPercent: 22, injuryRiskBand: "Moderate",
            magnesiumPct: 52, magnesiumDaysLow: 6)

        XCTAssertFalse(insights.isEmpty)
        // Sleep debt is the most severe chain → it surfaces first.
        XCTAssertTrue(insights.first?.chain.contains("Sleep debt") ?? false)
        // A chain connects training load to the active injury.
        XCTAssertTrue(insights.contains { $0.chain.lowercased().contains("injury risk") })
        // Every chain ships with a concrete action.
        XCTAssertTrue(insights.allSatisfy { !$0.action.isEmpty })
    }

    func testHealthyAthleteHasNoNaggingChains() {
        let insights = InsightEngine.crossModule(
            recovery: 92, sleepDebtHours: 0,
            hrv: 66, hrvBaseline: 62,
            proteinRemaining: 0, hydrationPct: 100,
            injuryName: nil, injuryPhase: nil, injuryPain: nil,
            injuryRiskPercent: 8, injuryRiskBand: "Low",
            magnesiumPct: 100, magnesiumDaysLow: 0)
        XCTAssertTrue(insights.isEmpty, "A fully-recovered athlete shouldn't be nagged with chains")
    }

    // MARK: - Live wiring through AppState

    func testAppStateExposesConnectedIntelligence() {
        let app = AppState()
        XCTAssertFalse(app.recoveryDrivers.isEmpty, "The dashboard must be able to explain recovery")
        XCTAssertFalse(app.forgeInsights.isEmpty, "The dashboard must surface cross-module connections")
    }
}
