import XCTest
@testable import Forge

/// Onboarding must produce the REAL user's starting state — their declared
/// injuries and a fresh profile — not the demo athlete's (previously the injury
/// selection was collected and then silently dropped).
final class OnboardingTests: XCTestCase {

    // MARK: Profile is stripped of the demo seed's identity

    func testOnboardingProfileResetsDemoGamification() {
        // MockData.sean carries a 23-day streak, a level, XP, and "Hockey".
        let fresh = AppState.onboardingProfile(from: MockData.sean)
        XCTAssertEqual(fresh.streakDays, 0)
        XCTAssertEqual(fresh.level, 1)
        XCTAssertEqual(fresh.xp, 0)
        XCTAssertTrue(fresh.sport.isEmpty, "A real user should not inherit the demo athlete's sport")
        // Real inputs are preserved.
        XCTAssertEqual(fresh.weightLb, MockData.sean.weightLb)
        XCTAssertEqual(fresh.primaryGoal, MockData.sean.primaryGoal)
    }

    // MARK: Declared injuries are applied (not the demo knee)

    func testDeclaredInjuriesReplaceTheDemoKnee() {
        let svc = InjuryService()
        XCTAssertEqual(svc.active.first?.type, .knee)          // demo seed
        svc.setActive(from: [.shoulder, .ankle])
        XCTAssertEqual(Set(svc.active.map(\.type)), [.shoulder, .ankle])
        XCTAssertFalse(svc.active.contains { $0.type == .knee })
    }

    func testNoDeclaredInjuriesMeansHealthy() {
        let svc = InjuryService()
        svc.setActive(from: [])
        XCTAssertTrue(svc.active.isEmpty)
        XCTAssertEqual(svc.injuryStatusScore, 100)             // healthy → full score
    }

    // MARK: End-to-end through AppState

    func testHealthyOnboardingClearsTheKneeDirective() {
        let app = AppState()
        // A healthy real user finishing onboarding with no injuries.
        app.commitOnboarding(profile: MockData.sean, injuries: [])
        XCTAssertTrue(app.injuries.active.isEmpty)
        XCTAssertEqual(app.injuries.injuryStatusScore, 100)
        XCTAssertEqual(app.user.streakDays, 0)
        // The directive no longer prescribes knee PT for someone without a knee injury.
        XCTAssertFalse(app.dailyDirective.priorityAction.lowercased().contains("knee"))
    }

    func testShoulderOnboardingConstrainsTraining() {
        let app = AppState()
        app.commitOnboarding(profile: MockData.sean, injuries: [.shoulder])
        XCTAssertTrue(app.injuries.active.contains { $0.type == .shoulder })
        // The generated session honours the declared shoulder injury.
        let names = app.todaysPlan.blocks.flatMap(\.items).map(\.name).joined(separator: " ")
        XCTAssertTrue(names.contains("neutral grip"))
    }
}
