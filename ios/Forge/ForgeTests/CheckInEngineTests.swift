import XCTest
@testable import Forge

/// The morning check-in must actually drive recovery + the Forge Score — its whole
/// value for the (majority) athletes without a wearable.
final class CheckInEngineTests: XCTestCase {

    private func snap(sleep: Int, sore: Int, energy: Int, stress: Int) -> CheckInSnapshot {
        CheckInSnapshot(sleepQuality: sleep, soreness: sore, energy: energy, stress: stress)
    }

    // MARK: Pure engine

    func testRecoveryBoundsAndDirection() {
        let great = CheckInEngine.recovery(snap(sleep: 5, sore: 0, energy: 5, stress: 1))
        let mid   = CheckInEngine.recovery(snap(sleep: 3, sore: 2, energy: 3, stress: 2))
        let awful = CheckInEngine.recovery(snap(sleep: 1, sore: 9, energy: 1, stress: 5))
        XCTAssertEqual(great, 100)
        XCTAssertTrue((0...100).contains(mid))
        XCTAssertGreaterThan(great, mid)
        XCTAssertGreaterThan(mid, awful)
        XCTAssertGreaterThanOrEqual(awful, 0)
    }

    func testEachDimensionMovesRecoveryTheRightWay() {
        let base = snap(sleep: 3, sore: 3, energy: 3, stress: 3)
        let b = CheckInEngine.recovery(base)
        XCTAssertGreaterThan(CheckInEngine.recovery(snap(sleep: 5, sore: 3, energy: 3, stress: 3)), b) // better sleep
        XCTAssertLessThan(CheckInEngine.recovery(snap(sleep: 3, sore: 8, energy: 3, stress: 3)), b)    // more sore
        XCTAssertGreaterThan(CheckInEngine.recovery(snap(sleep: 3, sore: 3, energy: 5, stress: 3)), b) // more energy
        XCTAssertLessThan(CheckInEngine.recovery(snap(sleep: 3, sore: 3, energy: 3, stress: 5)), b)    // more stress
    }

    func testSleepScoreAndReadinessBands() {
        XCTAssertEqual(CheckInEngine.sleepScore(1), 40)
        XCTAssertEqual(CheckInEngine.sleepScore(5), 95)
        XCTAssertEqual(CheckInEngine.readiness(for: 95), .peak)
        XCTAssertEqual(CheckInEngine.readiness(for: 80), .high)
        XCTAssertEqual(CheckInEngine.readiness(for: 60), .moderate)
        XCTAssertEqual(CheckInEngine.readiness(for: 20), .low)
    }

    // MARK: Integration — moves the score without a wearable

    func testCheckInMovesRecoveryAndForgeScoreWithoutWearable() {
        let good = AppState(); good.checkIn = snap(sleep: 5, sore: 0, energy: 5, stress: 1)
        let bad  = AppState(); bad.checkIn  = snap(sleep: 1, sore: 9, energy: 1, stress: 5)
        XCTAssertTrue(good.recovery.recoveryFromCheckIn)
        XCTAssertGreaterThan(good.recovery.today.recovery, bad.recovery.today.recovery)
        XCTAssertGreaterThan(good.forgeScore, bad.forgeScore)     // the check-in reaches the headline number
        XCTAssertEqual(good.recovery.provenance, .partial)        // no longer "demo"
    }

    func testLiveHRVWinsOverTheCheckIn() {
        let app = AppState()
        app.recovery.updateReading(.hrv, value: 30, unit: "ms", source: .appleWatch, ageHours: 1) // live, low
        let liveRecovery = app.recovery.today.recovery
        app.checkIn = snap(sleep: 5, sore: 0, energy: 5, stress: 1)   // a great check-in
        XCTAssertFalse(app.recovery.recoveryFromCheckIn)
        XCTAssertEqual(app.recovery.today.recovery, liveRecovery)     // objective HRV not overridden
    }
}
