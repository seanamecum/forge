import XCTest
@testable import Forge

/// Guards the P0-6 fix: a connected user's recovery must be derived from their own
/// live signals (a disclosed estimate), never the demo athlete's value, and the
/// score's provenance must be surfaced honestly.
final class RecoveryEstimatorTests: XCTestCase {

    // MARK: Pure estimator

    func testEstimatorIsBoundedAndDirectionallyCorrect() {
        let base = RecoveryEstimator.recovery(hrv: 60, hrvBaseline: 60, restingHR: 50, sleepHours: 8)
        XCTAssertTrue((0...100).contains(base))
        XCTAssertGreaterThan(RecoveryEstimator.recovery(hrv: 90, hrvBaseline: 60, restingHR: 50, sleepHours: 8), base)
        XCTAssertLessThan(RecoveryEstimator.recovery(hrv: 30, hrvBaseline: 60, restingHR: 50, sleepHours: 8), base)
        XCTAssertLessThan(RecoveryEstimator.recovery(hrv: 60, hrvBaseline: 60, restingHR: 80, sleepHours: 8), base)
        XCTAssertLessThan(RecoveryEstimator.recovery(hrv: 60, hrvBaseline: 60, restingHR: 50, sleepHours: 4), base)
    }

    func testEstimatorClampsAndSurvivesZeroBaseline() {
        XCTAssertEqual(RecoveryEstimator.recovery(hrv: 9999, hrvBaseline: 10, restingHR: 30, sleepHours: 12), 100)
        XCTAssertTrue((0...100).contains(RecoveryEstimator.recovery(hrv: 0, hrvBaseline: 60, restingHR: 220, sleepHours: 0)))
        // hrvBaseline 0 must not divide-by-zero / crash.
        XCTAssertTrue((0...100).contains(RecoveryEstimator.recovery(hrv: 40, hrvBaseline: 0, restingHR: 60, sleepHours: 7)))
    }

    // MARK: Provenance + live derivation

    func testSeriesAndStrainBaseline() {
        let svc = RecoveryService()
        let strain = svc.series("Strain")
        XCTAssertFalse(strain.isEmpty)
        XCTAssertEqual(svc.strainBaseline, strain.reduce(0, +) / Double(strain.count), accuracy: 0.0001)
        XCTAssertTrue(svc.series("does-not-exist").isEmpty)
    }

    func testDefaultsToDemoProvenance() {
        let svc = RecoveryService()
        XCTAssertEqual(svc.provenance, .demo)
        XCTAssertFalse(svc.recoveryFromLiveSignals)
        XCTAssertEqual(svc.provenance.label, "Demo data")
    }

    func testLiveHRVDerivesRecoveryFromUserAndFlipsProvenance() {
        let svc = RecoveryService()            // Apple Watch is connected by default
        let demoRecovery = svc.today.recovery
        // A genuine live HRV well below the demo baseline.
        svc.updateReading(.hrv, value: 20, unit: "ms", source: .appleWatch)
        XCTAssertEqual(svc.provenance, .partial)
        XCTAssertEqual(svc.provenance.label, "Partial · estimated")
        XCTAssertTrue(svc.recoveryFromLiveSignals)
        XCTAssertNotEqual(svc.today.recovery, demoRecovery,
                          "Connected recovery must reflect the user's live HRV, not the demo value")
        XCTAssertTrue((0...100).contains(svc.today.recovery))
    }
}
