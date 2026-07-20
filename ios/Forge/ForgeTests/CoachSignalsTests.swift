import XCTest
@testable import Forge

/// The Coach's "signals" panel must show the real inputs Forge fed the coach —
/// not fabricated per-answer reasoning that implies a model chain-of-thought.
final class CoachSignalsTests: XCTestCase {

    func testContextSignalsReflectRealContextValues() {
        let c = CoachContext.demo
        let signals = AIService.contextSignals(c)
        XCTAssertFalse(signals.isEmpty)
        // Every signal is derived from the actual context, not invented.
        XCTAssertTrue(signals.contains { $0.contains("Forge Score \(c.forgeScore)") })
        XCTAssertTrue(signals.contains { $0.contains("Recovery \(c.recovery)") })
        XCTAssertTrue(signals.contains { $0.contains("HRV \(c.hrv)") })
        XCTAssertTrue(signals.contains { $0.contains("Hydration \(c.hydrationPct)%") })
        XCTAssertTrue(signals.contains { $0.contains("Directive:") })
    }

    func testSignalsTrackChangingContext() {
        var c = CoachContext.demo
        c.forgeScore = 41
        c.recovery = 41
        XCTAssertTrue(AIService.contextSignals(c).contains { $0.contains("Forge Score 41") })
    }

    func testMockReplyNoLongerCarriesFabricatedReasoning() {
        // Fabricated "steps" were removed; reply() attaches the real signals instead.
        for q in ["what should I train today", "why am I tired", "should I deload",
                  "what should I eat", "how do I hit 225 bench", "how's my knee"] {
            XCTAssertTrue(AIService.mockReply(to: q).steps.isEmpty,
                          "mockReply must not hardcode reasoning steps for: \(q)")
        }
    }

    func testMockReplyStillAnswersWithText() {
        XCTAssertFalse(AIService.mockReply(to: "what should I train today").text.isEmpty)
    }
}
