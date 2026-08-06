import XCTest
@testable import Forge

/// Onboarding foundation: a real new user starts truly blank (never "Sean"),
/// Continue is gated only where a real value is required, progress survives an
/// interruption, and events are captured.
final class OnboardingFoundationTests: XCTestCase {

    // MARK: - Blank start (no demo identity)

    func testBlankProfileHasNoDemoIdentity() {
        let b = UserProfile.blank
        XCTAssertTrue(b.name.isEmpty)
        XCTAssertEqual(b.weightLb, 0)
        XCTAssertEqual(b.heightInches, 0)
        XCTAssertTrue(b.goals.isEmpty)
        XCTAssertTrue(b.equipment.isEmpty)
        XCTAssertEqual(b.streakDays, 0)
        XCTAssertEqual(b.level, 1)
        XCTAssertEqual(b.xp, 0)
        XCTAssertNotEqual(b.name, MockData.sean.name)   // never seeded from the demo athlete
        XCTAssertNotEqual(b.sport, MockData.sean.sport)
    }

    // MARK: - Gating

    func testReadyToFinishRequiresRealValues() {
        XCTAssertFalse(OnboardingValidation.readyToFinish(.blank))
        var p = UserProfile.blank
        p.name = "Alex"; p.age = 30; p.heightInches = 70; p.weightLb = 165
        p.goals = [.buildMuscle]; p.equipment = [.fullGym]
        XCTAssertTrue(OnboardingValidation.readyToFinish(p))
    }

    func testFieldValidatorsGateOnlyWhereNeeded() {
        XCTAssertFalse(OnboardingValidation.nameValid(.blank))
        XCTAssertFalse(OnboardingValidation.nameValid({ var p = UserProfile.blank; p.name = "   "; return p }()))
        XCTAssertFalse(OnboardingValidation.weightValid(.blank))
        XCTAssertFalse(OnboardingValidation.weightValid({ var p = UserProfile.blank; p.weightLb = 800; return p }()))
        XCTAssertTrue(OnboardingValidation.weightValid({ var p = UserProfile.blank; p.weightLb = 165; return p }()))
        XCTAssertFalse(OnboardingValidation.ageValid({ var p = UserProfile.blank; p.age = 5; return p }()))
        XCTAssertTrue(OnboardingValidation.goalsValid({ var p = UserProfile.blank; p.goals = [.loseFat]; return p }()))
    }

    // MARK: - Resume-after-interruption

    func testProgressRoundTripsAndClears() {
        let suite = UserDefaults(suiteName: "onb-\(UUID())")!
        XCTAssertNil(OnboardingStore.load(defaults: suite))

        var p = UserProfile.blank; p.name = "Alex"; p.goals = [.loseFat]; p.weightLb = 150
        OnboardingStore.save(OnboardingProgress(step: 4, profile: p,
                                                injuries: [.knee], wearables: ["Apple Watch"]),
                             defaults: suite)

        let loaded = OnboardingStore.load(defaults: suite)
        XCTAssertEqual(loaded?.step, 4)
        XCTAssertEqual(loaded?.profile.name, "Alex")
        XCTAssertEqual(loaded?.profile.weightLb, 150)
        XCTAssertEqual(loaded?.injuries, [.knee])
        XCTAssertEqual(loaded?.wearables, ["Apple Watch"])

        OnboardingStore.clear(defaults: suite)
        XCTAssertNil(OnboardingStore.load(defaults: suite))   // committing wipes the resume state
    }

    // MARK: - Analytics

    func testAnalyticsCapturesAndClears() {
        let suite = UserDefaults(suiteName: "an-\(UUID())")!
        Analytics.log(.onboardingStarted, defaults: suite)
        Analytics.log(.onboardingCompleted, ["step": "13"], defaults: suite)

        let events = Analytics.all(defaults: suite)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.name, "onboarding_started")
        XCTAssertEqual(events.last?.props["step"], "13")

        Analytics.clear(defaults: suite)
        XCTAssertTrue(Analytics.all(defaults: suite).isEmpty)
    }
}
