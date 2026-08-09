import XCTest
@testable import Forge

/// In-session editing: remove/reorder exercises and delete sets. These back the
/// logger's long-press menus so the operations can't corrupt a live session.
final class WorkoutEditingTests: XCTestCase {

    private func ex(_ i: Int, sets: Int = 2) -> LoggedExercise {
        LoggedExercise(exercise: MockData.exercises[i],
                       sets: (0..<sets).map { _ in WorkoutSet(weightLb: 100, reps: 5) })
    }

    func testRemovingExercise() {
        let list = [ex(0), ex(1), ex(2)]
        let out = WorkoutEditing.removingExercise(list, id: list[1].id)
        XCTAssertEqual(out.map(\.id), [list[0].id, list[2].id])
        // Unknown id is a no-op.
        XCTAssertEqual(WorkoutEditing.removingExercise(list, id: UUID()).count, 3)
    }

    func testMovingExerciseUpAndDown() {
        let list = [ex(0), ex(1), ex(2)]
        let up = WorkoutEditing.movingExercise(list, id: list[2].id, by: -1)
        XCTAssertEqual(up.map(\.id), [list[0].id, list[2].id, list[1].id])
        let down = WorkoutEditing.movingExercise(list, id: list[0].id, by: 1)
        XCTAssertEqual(down.map(\.id), [list[1].id, list[0].id, list[2].id])
    }

    func testMovingAtBoundaryIsNoOp() {
        let list = [ex(0), ex(1)]
        XCTAssertEqual(WorkoutEditing.movingExercise(list, id: list[0].id, by: -1).map(\.id), list.map(\.id))
        XCTAssertEqual(WorkoutEditing.movingExercise(list, id: list[1].id, by: 1).map(\.id), list.map(\.id))
    }

    func testRemovingSet() {
        var e = ex(0, sets: 3)
        let target = e.sets[1].id
        e = WorkoutEditing.removingSet(e, setID: target)
        XCTAssertEqual(e.sets.count, 2)
        XCTAssertFalse(e.sets.contains { $0.id == target })
        // Deleting down to empty is allowed (the exercise can then be removed).
        for s in e.sets { e = WorkoutEditing.removingSet(e, setID: s.id) }
        XCTAssertTrue(e.sets.isEmpty)
    }
}
