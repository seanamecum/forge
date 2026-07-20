import XCTest
@testable import Forge

/// Injury is now real, editable, and connected — not a hardcoded singleton.
final class InjuryServiceTests: XCTestCase {

    func testSeedsDemoInjuryHermeticallyInTests() {
        // In a test run, persistence is skipped so we always start from the known
        // demo seed rather than whatever the simulator's UserDefaults holds.
        let s = InjuryService()
        XCTAssertEqual(s.active.count, 1)
        XCTAssertEqual(s.active.first?.type, .knee)
    }

    func testAddAppendsAndDragsStatusScoreDown() {
        let s = InjuryService()
        let before = s.injuryStatusScore
        s.add(type: .shoulder, phase: .acute, pain: 9)
        XCTAssertTrue(s.active.contains { $0.type == .shoulder })
        XCTAssertLessThanOrEqual(s.injuryStatusScore, before)
    }

    func testResolveRemovesAndRestoresHealthyScore() {
        let s = InjuryService()
        s.active.forEach { s.resolve($0) }
        XCTAssertTrue(s.active.isEmpty)
        XCTAssertEqual(s.injuryStatusScore, 100)   // no injuries → fully healthy
    }

    func testLogPainUpdatesValueAndAppendsHistory() {
        let s = InjuryService()
        guard let injury = s.active.first else { return XCTFail("expected a seeded injury") }
        let historyCount = injury.painHistory.count
        s.logPain(7, for: injury)
        XCTAssertEqual(s.active.first?.painToday, 7)
        XCTAssertEqual(s.active.first?.painHistory.count, historyCount + 1)
    }

    func testMakeInjurySeverityScalesWithPain() {
        XCTAssertEqual(InjuryService.makeInjury(type: .knee, phase: .acute, pain: 0).severity, 1)
        XCTAssertEqual(InjuryService.makeInjury(type: .knee, phase: .acute, pain: 10).severity, 5)
        XCTAssertTrue((1...5).contains(InjuryService.makeInjury(type: .knee, phase: .acute, pain: 5).severity))
    }

    func testInjuryProfileCodableRoundTrips() throws {
        let original = [InjuryService.makeInjury(type: .hamstring, phase: .rehab, pain: 4)]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([InjuryProfile].self, from: data)
        XCTAssertEqual(decoded.first?.type, .hamstring)
        XCTAssertEqual(decoded.first?.phase, .rehab)
        XCTAssertEqual(decoded.first?.painToday, 4)
    }

    func testAddedInjuryReachesTheWorkoutGenerator() {
        // The loop: a newly-logged injury constrains the actual prescribed session.
        let s = InjuryService()
        s.active.forEach { s.resolve($0) }        // start clean
        s.add(type: .shoulder, phase: .subacute, pain: 5)

        let plan = WorkoutService().generate(
            goal: .buildMuscle, minutes: 60, equipment: .fullGym,
            recovery: 78, injuries: s.active.map(\.type), level: .intermediate)
        let names = plan.blocks.flatMap(\.items).map(\.name).joined(separator: " ")
        XCTAssertFalse(names.contains("Barbell Bench Press"))     // shoulder-aggravating lift blocked
        XCTAssertTrue(names.contains("neutral grip"))            // shoulder-safe swap queued
    }
}
