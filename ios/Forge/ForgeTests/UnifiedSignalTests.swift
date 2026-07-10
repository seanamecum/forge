import XCTest
@testable import Forge

/// The unified stream actually DRIVING the app: today's snapshot — and therefore
/// the Forge Score, Directive, and Coach — follows source priority, the user's
/// preferred source, disconnections, and live HealthKit readings.
final class UnifiedSignalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "forge.datahub.preferred.v1")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "forge.datahub.preferred.v1")
        super.tearDown()
    }

    func testDefaultResolutionMatchesSeededSnapshot() {
        // WHOOP wins sleep/HRV/RHR by default and its seeds equal the snapshot —
        // the demo must be bit-identical until the user makes a choice.
        let recovery = RecoveryService()
        XCTAssertEqual(recovery.today.sleep.hours, 7.2, accuracy: 0.001)
        XCTAssertEqual(recovery.today.sleep.score, 81)
        XCTAssertEqual(recovery.today.hrv, 58)
        XCTAssertEqual(recovery.today.restingHR, 56)
    }

    func testPreferredSleepSourceRewiresTheSnapshot() {
        let recovery = RecoveryService()
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
        guard let whoop = recovery.wearables.first(where: { $0.source == .whoop }) else {
            return XCTFail("demo stack should include WHOOP")
        }
        recovery.toggleConnection(whoop)   // unpair
        XCTAssertEqual(recovery.today.sleep.hours, 7.9, accuracy: 0.001, "Sleep falls back to Apple Watch")
        XCTAssertEqual(recovery.today.hrv, 61)
        XCTAssertEqual(recovery.today.restingHR, 58)

        recovery.toggleConnection(recovery.wearables.first(where: { $0.source == .whoop })!)  // re-pair
        XCTAssertEqual(recovery.today.hrv, 58, "Re-pairing restores WHOOP as the HRV winner")
    }

    func testLiveHealthKitReadingEntersThePipeline() {
        let recovery = RecoveryService()
        // A real Apple Watch sleep sample arrives (fresher than every seed)…
        recovery.updateReading(.sleep, value: 6.4, unit: "h", source: .appleWatch)
        // …but WHOOP still outranks it by default priority.
        XCTAssertEqual(recovery.today.sleep.hours, 7.2, accuracy: 0.001)
        // Until the user prefers Apple Watch — then the LIVE value wins, not the seed.
        recovery.setPreferred(.appleWatch, for: .sleep)
        XCTAssertEqual(recovery.today.sleep.hours, 6.4, accuracy: 0.001)
    }

    func testCoachContextFollowsPreferredSource() {
        let app = AppState()
        let before = app.coachContext.sleepHours
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
