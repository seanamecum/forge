import XCTest
@testable import Forge

/// The UserModel "brain" — cross-domain causal insights. These must be honest:
/// a cause is named only when it's real in the data, and recovery must genuinely
/// be low. Forge never fabricates a correlation.
final class CrossDomainInsightsTests: XCTestCase {

    // MARK: - Sleep decline detector

    func testSleepDeclineDetectsRealMultiNightDrop() {
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([8.0, 7.5, 7.0, 6.5]), 4)
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([7.5, 7.0, 6.8]), 3)   // 3 nights, 0.7h lost
    }

    func testSleepDeclineIgnoresNoiseAndRecovery() {
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([7, 7, 7, 7]), 0)       // flat → no drop
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([6.5, 7.0, 7.5, 8.0]), 0) // improving
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([8.0, 7.9]), 0)          // too few nights
        XCTAssertEqual(CrossDomainInsights.sleepDeclineNights([7.6, 7.5, 7.4]), 0)     // decline too small (<0.5)
    }

    // MARK: - Volume change

    func testVolumeChangePct() {
        XCTAssertEqual(CrossDomainInsights.volumeChangePct(thisWeek: 11_800, priorWeek: 10_000), 18)
        XCTAssertEqual(CrossDomainInsights.volumeChangePct(thisWeek: 9_000, priorWeek: 10_000), -10)
        XCTAssertNil(CrossDomainInsights.volumeChangePct(thisWeek: 5_000, priorWeek: 0))   // no honest %
    }

    // MARK: - Recovery driver synthesis

    func testNoInsightWhenRecoveryIsNormal() {
        XCTAssertNil(CrossDomainInsights.recoveryDriver(
            recoveryToday: 80, usual: 82, sleepHours: [8, 7.5, 7, 6.5],
            volumeThisWeek: 11_800, volumePriorWeek: 10_000))              // not materially low
    }

    func testNoInsightWhenLowButNoRealDriver() {
        XCTAssertNil(CrossDomainInsights.recoveryDriver(
            recoveryToday: 60, usual: 80, sleepHours: [7, 7, 7, 7, 7],
            volumeThisWeek: 10_000, volumePriorWeek: 10_000))              // low, but nothing to blame
    }

    func testSingleDriverNamesOnlyTheRealCause() {
        let i = CrossDomainInsights.recoveryDriver(
            recoveryToday: 60, usual: 80, sleepHours: [8.0, 7.5, 7.0, 6.5],
            volumeThisWeek: 0, volumePriorWeek: 0)!                        // volume can't be computed → excluded
        XCTAssertTrue(i.title.hasPrefix("Recovery is lower because"))
        XCTAssertTrue(i.title.contains("sleep has trended down 4 days"))
        XCTAssertFalse(i.title.contains("training volume"))               // never claims an unmeasured cause
        XCTAssertEqual(i.confidence, 0.72, accuracy: 0.001)
        XCTAssertEqual(i.domain, .recovery)
    }

    func testBothDriversCombineWithHigherConfidence() {
        let i = CrossDomainInsights.recoveryDriver(
            recoveryToday: 58, usual: 80, sleepHours: [8.0, 7.5, 7.0, 6.5],
            volumeThisWeek: 11_800, volumePriorWeek: 10_000)!
        XCTAssertTrue(i.title.contains("sleep has trended down 4 days"))
        XCTAssertTrue(i.title.contains("training volume rose 18%"))
        XCTAssertEqual(i.confidence, 0.85, accuracy: 0.001)               // two independent drivers → more sure
        XCTAssertTrue(i.reason.contains("22 below your usual 80"))        // 80-58 = 22
    }

    func testNoInsightWithoutABaseline() {
        XCTAssertNil(CrossDomainInsights.recoveryDriver(
            recoveryToday: 40, usual: 0, sleepHours: [8.0, 7.5, 7.0, 6.5],
            volumeThisWeek: 11_800, volumePriorWeek: 10_000))             // no usual yet → no claim
    }
}
