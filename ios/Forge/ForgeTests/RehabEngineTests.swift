import XCTest
@testable import Forge

/// Injury rehab must be prescribed, not just tracked — a daily plan, a readiness
/// score, and a feed into the Daily Directive.
final class RehabEngineTests: XCTestCase {

    func testKneePlanUsesTheMatchingProtocol() {
        let plan = RehabEngine.plan(for: MockData.knee,
                                    library: MockData.ptExercises,
                                    protocols: MockData.protocols)
        XCTAssertFalse(plan.exercises.isEmpty)
        XCTAssertEqual(plan.exercises.first?.name, "Spanish Squat Isometric")
        XCTAssertTrue(plan.exercises.contains { $0.name == "Terminal Knee Extensions" })
        XCTAssertTrue(plan.summary.lowercased().contains("knee pt"))
        XCTAssertGreaterThanOrEqual(plan.estMinutes, 10)
        XCTAssertTrue(plan.title.contains("Knee"))
    }

    func testReadinessReflectsChecklistStrengthAndPain() {
        let r = RehabEngine.readiness(checklist: MockData.kneeRTSChecklist, injury: MockData.knee)
        XCTAssertEqual(r.totalCount, MockData.kneeRTSChecklist.count)
        XCTAssertEqual(r.clearedCount, MockData.kneeRTSChecklist.filter(\.done).count)
        XCTAssertTrue((0...100).contains(r.percent))
        XCTAssertNotNil(r.nextMilestone)   // not fully cleared yet
        XCTAssertFalse(r.etaText.isEmpty)
    }

    func testTopBandNeverClaimsMedicalClearance() {
        // Meeting every self-check gate must NOT read as "cleared" — Forge does
        // not issue return-to-sport clearance; that is a clinician's call.
        let cleared = MockData.kneeRTSChecklist.map {
            RTSChecklistItem(label: $0.label, detail: $0.detail, done: true)
        }
        var healthy = MockData.knee
        healthy.painToday = 0
        healthy.strengthPct = 98
        let r = RehabEngine.readiness(checklist: cleared, injury: healthy)
        XCTAssertGreaterThanOrEqual(r.percent, 90)
        XCTAssertEqual(r.band, "Criteria met")
        XCTAssertEqual(r.etaText, "Final gate: clinician sign-off")
        XCTAssertNil(r.nextMilestone)
        // Guard against regressing to clearance language anywhere in the result.
        XCTAssertFalse(r.band.lowercased().contains("cleared"))
        XCTAssertFalse(r.etaText.lowercased().contains("cleared for"))
    }

    func testConcussionDemoDoesNotShowGameCleared() {
        // The concussion return-to-play demo must not depict an athlete already
        // returned to competition (P0-4).
        let stages = MockData.rtpStages
        let contactOrGame = stages.filter { $0.number >= 6 }
        XCTAssertFalse(contactOrGame.contains { $0.completed },
                       "Contact/competition RTP stages must not be pre-completed in the demo")
    }

    func testDirectiveMobilityActionCarriesTheRehabPlan() {
        // The Daily Directive's mobility slot must show the specific PT, not a generic line.
        let app = AppState()
        let mobility = app.dailyDirective.actions.first { $0.kind == .mobility }
        XCTAssertNotNil(mobility)
        XCTAssertTrue(mobility!.value.lowercased().contains("knee pt"))
    }
}
