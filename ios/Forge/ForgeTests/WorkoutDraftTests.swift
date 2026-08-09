import XCTest
@testable import Forge

/// LC-1: an in-progress workout must survive backgrounding / relaunch. These
/// verify the draft snapshot round-trips faithfully, only offers to resume once
/// there's real progress, and is cleared when the session finishes.
final class WorkoutDraftTests: XCTestCase {

    private func session() -> [LoggedExercise] {
        let a = MockData.exercises[0]
        let b = MockData.exercises[1]
        return [
            LoggedExercise(exercise: a, sets: [
                WorkoutSet(weightLb: 185, reps: 5, rpe: 8, completed: true, isPR: true),
                WorkoutSet(weightLb: 185, reps: 5, completed: false),
            ]),
            LoggedExercise(exercise: b, sets: [
                WorkoutSet(weightLb: 95, reps: 10, completed: false),
            ]),
        ]
    }

    func testSnapshotRestoresEverySetFaithfully() {
        let started = Date(timeIntervalSince1970: 1_700_000_000)
        let draft = WorkoutDraft.from(name: "Push Day", startedAt: started,
                                      exercises: session(), savedAt: started)
        let restored = draft.restore { MockData.exercise($0) }

        XCTAssertEqual(restored.count, 2)
        XCTAssertEqual(restored[0].exercise.id, MockData.exercises[0].id)   // ids preserved
        XCTAssertEqual(restored[0].sets.count, 2)
        XCTAssertEqual(restored[0].sets[0].weightLb, 185)
        XCTAssertEqual(restored[0].sets[0].reps, 5)
        XCTAssertEqual(restored[0].sets[0].rpe, 8)
        XCTAssertTrue(restored[0].sets[0].completed)
        XCTAssertTrue(restored[0].sets[0].isPR)                             // the PR flag survives
        XCTAssertFalse(restored[0].sets[1].completed)
    }

    func testHasProgressOnlyAfterACompletedSet() {
        let seededOnly = WorkoutDraft.from(name: "x", startedAt: .now, exercises: [
            LoggedExercise(exercise: MockData.exercises[0],
                           sets: [WorkoutSet(weightLb: 135, reps: 5, completed: false)])   // prefilled, not done
        ], savedAt: .now)
        XCTAssertFalse(seededOnly.hasProgress)
        XCTAssertEqual(seededOnly.completedSets, 0)

        let withProgress = WorkoutDraft.from(name: "x", startedAt: .now, exercises: session(), savedAt: .now)
        XCTAssertTrue(withProgress.hasProgress)          // one completed set in the fixture
        XCTAssertEqual(withProgress.completedSets, 1)
        XCTAssertEqual(withProgress.totalVolumeLb, 185 * 5)   // only completed sets count
    }

    func testStoreSaveLoadClearRoundTrip() {
        let suite = UserDefaults(suiteName: "draft-test-\(UUID())")!
        XCTAssertNil(WorkoutDraftStore.load(defaults: suite))

        let draft = WorkoutDraft.from(name: "Legs", startedAt: .now, exercises: session(), savedAt: .now)
        WorkoutDraftStore.save(draft, defaults: suite)
        XCTAssertEqual(WorkoutDraftStore.load(defaults: suite)?.name, "Legs")
        XCTAssertNotNil(WorkoutDraftStore.resumable(defaults: suite))   // has a completed set

        WorkoutDraftStore.clear(defaults: suite)
        XCTAssertNil(WorkoutDraftStore.load(defaults: suite))           // finish/discard leaves nothing
    }

    func testResumableIgnoresSeededOnlyDrafts() {
        let suite = UserDefaults(suiteName: "draft-test-\(UUID())")!
        let seededOnly = WorkoutDraft.from(name: "x", startedAt: .now, exercises: [
            LoggedExercise(exercise: MockData.exercises[0],
                           sets: [WorkoutSet(weightLb: 135, reps: 5, completed: false)])
        ], savedAt: .now)
        WorkoutDraftStore.save(seededOnly, defaults: suite)
        XCTAssertNotNil(WorkoutDraftStore.load(defaults: suite))        // it IS saved (no data loss)
        XCTAssertNil(WorkoutDraftStore.resumable(defaults: suite))      // but doesn't nag to resume
    }
}
