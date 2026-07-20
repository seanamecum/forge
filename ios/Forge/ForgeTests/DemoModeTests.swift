import XCTest
@testable import Forge

/// A real account must see only its own training data; the demo athlete's seeded
/// history/PRs/volume belong to demo mode only.
final class DemoModeTests: XCTestCase {

    func testClearAndRestoreDemoSeed() {
        let svc = WorkoutService()
        XCTAssertFalse(svc.history.isEmpty)          // demo seed present
        svc.clearDemoSeed()
        XCTAssertTrue(svc.history.isEmpty)
        XCTAssertTrue(svc.personalRecords.isEmpty)
        XCTAssertTrue(svc.muscleVolume.isEmpty)
        svc.restoreDemoSeed()
        XCTAssertFalse(svc.history.isEmpty)          // demo world back
        XCTAssertFalse(svc.personalRecords.isEmpty)
    }

    func testDemoModeKeepsTheDemoAthletesTraining() {
        let app = AppState()
        app.completeAuth(demo: true)
        XCTAssertTrue(app.isDemoAccount)
        XCTAssertFalse(app.workouts.history.isEmpty)     // Sean's sessions
    }

    func testRealAccountStartsWithCleanTraining() {
        let app = AppState()
        app.completeAuth(demo: false)
        XCTAssertFalse(app.isDemoAccount)
        XCTAssertTrue(app.workouts.history.isEmpty)      // no demo contamination
        XCTAssertTrue(app.workouts.personalRecords.isEmpty)
        XCTAssertTrue(app.workouts.muscleVolume.isEmpty)
    }

    func testOnboardingClearsTheDemoTrainingSeed() {
        let app = AppState()
        app.commitOnboarding(profile: MockData.sean, injuries: [])
        XCTAssertFalse(app.isDemoAccount)
        XCTAssertTrue(app.workouts.history.isEmpty)
        XCTAssertTrue(app.workouts.weeklyVolumeLb == 0)  // analytics read a clean slate
        XCTAssertTrue(app.workouts.plateaus.isEmpty)
    }

    func testDemoAfterRealSessionRestoresTheDemoWorld() {
        // Real account clears the seed; entering demo mode must bring Sean's world back.
        let app = AppState()
        app.completeAuth(demo: false)
        XCTAssertTrue(app.workouts.history.isEmpty)
        app.completeAuth(demo: true)
        XCTAssertFalse(app.workouts.history.isEmpty)
    }
}
