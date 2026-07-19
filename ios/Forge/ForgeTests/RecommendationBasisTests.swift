import XCTest
@testable import Forge

/// Every calculated recommendation must expose inputs used, inputs missing,
/// confidence, a timestamp, and a safe fallback (charter). These verify the
/// contract for the two flagship recommendations: Forge Score + Directive.
final class RecommendationBasisTests: XCTestCase {

    // MARK: Confidence rule (pure)

    func testConfidenceFollowsProvenanceAndCheckIn() {
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .demo, hasCheckIn: true), .low)
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .demo, hasCheckIn: false), .low)
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .partial, hasCheckIn: false), .low)
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .partial, hasCheckIn: true), .moderate)
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .live, hasCheckIn: false), .moderate)
        XCTAssertEqual(RecommendationBasis.confidence(provenance: .live, hasCheckIn: true), .high)
    }

    // MARK: Forge Score basis

    func testForgeScoreBasisIsHonestInDemoState() {
        let app = AppState()                      // demo: no live signals, no check-in
        let basis = app.forgeScoreBasis
        XCTAssertEqual(basis.confidence, .low)
        XCTAssertFalse(basis.inputsUsed.isEmpty)                 // names every component
        XCTAssertFalse(basis.inputsMissing.isEmpty)             // demo → missing live signals
        XCTAssertNotNil(basis.safeFallback)                     // never silent about the fallback
        XCTAssertFalse(basis.summary.isEmpty)
        XCTAssertTrue(basis.inputsMissing.contains { $0.contains("Apple Health") })
    }

    func testForgeScoreBasisNamesTheMissingCheckIn() {
        let app = AppState()
        XCTAssertTrue(app.forgeScoreBasis.inputsMissing.contains { $0.contains("check-in") })
    }

    func testConnectedRecoveryLiftsConfidence() {
        let app = AppState()
        // Genuine live HRV → provenance .partial (recovery derived from the user).
        app.recovery.updateReading(.hrv, value: 55, unit: "ms", source: .appleWatch)
        // With a check-in logged, a partially-live score reads Moderate, not Low.
        app.checkIn = CheckInSnapshot(sleepQuality: 4, soreness: 2, energy: 4, stress: 2)
        XCTAssertEqual(app.forgeScoreBasis.confidence, .moderate)
    }

    // MARK: Directive basis

    func testDirectiveBasisExposesInputsAndFallback() {
        let app = AppState()
        let basis = app.directiveBasis
        XCTAssertTrue(basis.inputsUsed.contains { $0.hasPrefix("Recovery") })
        XCTAssertTrue(basis.inputsMissing.contains { $0.contains("check-in") })  // none logged
        XCTAssertNotNil(basis.safeFallback)
        XCTAssertEqual(basis.summary, app.dailyDirective.rationale)
    }
}
