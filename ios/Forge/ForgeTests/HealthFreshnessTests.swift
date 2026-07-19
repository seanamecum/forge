import XCTest
@testable import Forge

/// Freshness (audit P2-6): a live HRV that's fresh drives recovery; a stale one
/// must not masquerade as today's, and its staleness is surfaced honestly.
final class HealthFreshnessTests: XCTestCase {

    func testFreshLiveHRVDerivesRecovery() {
        let svc = RecoveryService()
        svc.updateReading(.hrv, value: 40, unit: "ms", source: .appleWatch, ageHours: 1)
        XCTAssertTrue(svc.recoveryFromLiveSignals)
        XCTAssertFalse(svc.hasStaleLiveSignal)
        XCTAssertEqual(svc.liveAgeHours(.hrv), 1)
    }

    func testStaleLiveHRVDoesNotDriveRecovery() {
        let svc = RecoveryService()
        let demoRecovery = svc.today.recovery
        svc.updateReading(.hrv, value: 40, unit: "ms", source: .appleWatch, ageHours: 48)
        // Stale → recovery is NOT derived from it; the seeded value is held.
        XCTAssertFalse(svc.recoveryFromLiveSignals)
        XCTAssertTrue(svc.hasStaleLiveSignal)
        XCTAssertEqual(svc.today.recovery, demoRecovery)
    }

    func testNegativeAgeIsClampedToZero() {
        let svc = RecoveryService()
        svc.updateReading(.hrv, value: 55, unit: "ms", source: .appleWatch, ageHours: -5)
        XCTAssertEqual(svc.liveAgeHours(.hrv), 0)
        XCTAssertTrue(svc.recoveryFromLiveSignals)   // clamped age is fresh
    }

    func testAgeHoursNilWithoutASample() {
        // A fresh service has no real samples → no age, no false freshness.
        XCTAssertNil(HealthKitService().ageHours(for: .hrv))
    }

    func testStaleSignalSurfacesInScoreBasis() {
        let app = AppState()
        app.recovery.updateReading(.hrv, value: 40, unit: "ms", source: .appleWatch, ageHours: 40)
        XCTAssertTrue(app.forgeScoreBasis.inputsMissing.contains { $0.contains("fresh HRV") })
    }
}
