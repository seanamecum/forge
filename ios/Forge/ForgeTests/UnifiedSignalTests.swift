import XCTest
@testable import Forge

/// The unified stream actually DRIVING the app: today's snapshot — and therefore
/// the Forge Score, Directive, and Coach — follows source priority, the user's
/// preferred source, disconnections, and live HealthKit readings.
///
/// 1.0 ships Apple-Health-only, so the demo stack starts with just Apple
/// devices connected; tests that exercise multi-device arbitration connect
/// WHOOP themselves.
final class UnifiedSignalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "forge.datahub.preferred.v1")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "forge.datahub.preferred.v1")
        super.tearDown()
    }

    private func connectWhoop(_ recovery: RecoveryService) {
        guard let whoop = recovery.wearables.first(where: { $0.source == .whoop }),
              !whoop.connected else { return }
        recovery.toggleConnection(whoop)
    }

    func testDefaultResolutionIsAppleOnly() {
        // 1.0 default: Apple Watch is the source of truth for sleep/HRV/RHR.
        let recovery = RecoveryService()
        XCTAssertEqual(recovery.today.sleep.hours, 7.9, accuracy: 0.001)
        XCTAssertEqual(recovery.today.sleep.score, 89)
        XCTAssertEqual(recovery.today.hrv, 61)
        XCTAssertEqual(recovery.today.restingHR, 58)
    }

    func testPreferredSleepSourceRewiresTheSnapshot() {
        let recovery = RecoveryService()
        connectWhoop(recovery)
        XCTAssertEqual(recovery.today.sleep.hours, 7.2, accuracy: 0.001,
                       "With WHOOP connected it outranks the Watch by default priority")

        recovery.setPreferred(.appleWatch, for: .sleep)
        XCTAssertEqual(recovery.today.sleep.hours, 7.9, accuracy: 0.001,
                       "Choosing Apple Watch for sleep must change what the whole app sees")
        XCTAssertEqual(recovery.today.sleep.score, 89, "Sleep score rescales with the new hours")

        recovery.setPreferred(nil, for: .sleep)
        XCTAssertEqual(recovery.today.sleep.hours, 7.2, accuracy: 0.001,
                       "Clearing the preference restores the default winner")
    }

    func testDisconnectingWhoopFallsBackForAllItsMetrics() {
        let recovery = RecoveryService()
        connectWhoop(recovery)
        XCTAssertEqual(recovery.today.hrv, 58, "WHOOP wins HRV while connected")

        recovery.toggleConnection(recovery.wearables.first(where: { $0.source == .whoop })!)  // unpair
        XCTAssertEqual(recovery.today.sleep.hours, 7.9, accuracy: 0.001, "Sleep falls back to Apple Watch")
        XCTAssertEqual(recovery.today.hrv, 61)
        XCTAssertEqual(recovery.today.restingHR, 58)
    }

    func testLiveHealthKitReadingEntersThePipeline() {
        // Apple-only stack: a live Watch sample must drive the app directly.
        let recovery = RecoveryService()
        recovery.updateReading(.sleep, value: 6.4, unit: "h", source: .appleWatch)
        XCTAssertEqual(recovery.today.sleep.hours, 6.4, accuracy: 0.001,
                       "The live reading replaces the seed for the winning source")

        // A connected WHOOP outranks the Watch again — until the user chooses.
        connectWhoop(recovery)
        XCTAssertEqual(recovery.today.sleep.hours, 7.2, accuracy: 0.001)
        recovery.setPreferred(.appleWatch, for: .sleep)
        XCTAssertEqual(recovery.today.sleep.hours, 6.4, accuracy: 0.001,
                       "Preferring the Watch surfaces the LIVE value, not the seed")
    }

    func testCoachContextFollowsPreferredSource() {
        let app = AppState()
        connectWhoop(app.recovery)
        let before = app.coachContext.sleepHours
        XCTAssertEqual(before, 7.2, accuracy: 0.001)
        app.recovery.setPreferred(.appleWatch, for: .sleep)
        XCTAssertEqual(app.coachContext.sleepHours, 7.9, accuracy: 0.001,
                       "The coach must cite the source the user chose")
        XCTAssertNotEqual(before, app.coachContext.sleepHours)
    }

    func testWaitlistRoundTrip() {
        let feature = "Test Feature \(UUID().uuidString.prefix(6))"
        XCTAssertFalse(Waitlist.isJoined(feature))
        Waitlist.join(feature)
        XCTAssertTrue(Waitlist.isJoined(feature))
        Waitlist.leave(feature)
        XCTAssertFalse(Waitlist.isJoined(feature))
    }
}
