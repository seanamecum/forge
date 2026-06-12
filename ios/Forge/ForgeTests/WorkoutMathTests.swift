import XCTest
@testable import Forge

final class WorkoutMathTests: XCTestCase {

    func testEpleyOneRepMax() {
        let set = WorkoutSet(weightLb: 180, reps: 5)
        // Epley: 180 × (1 + 5/30) = 210
        XCTAssertEqual(set.estimatedOneRepMax, 210, accuracy: 0.01)
    }

    func testOneRepMaxZeroForEmptySet() {
        XCTAssertEqual(WorkoutSet(weightLb: 0, reps: 5).estimatedOneRepMax, 0)
        XCTAssertEqual(WorkoutSet(weightLb: 100, reps: 0).estimatedOneRepMax, 0)
    }

    func testVolumeCountsOnlyCompletedSets() {
        let exercise = MockData.exercise("bench")
        let logged = LoggedExercise(exercise: exercise, sets: [
            WorkoutSet(weightLb: 100, reps: 10, completed: true),   // 1000
            WorkoutSet(weightLb: 200, reps: 5, completed: false),   // ignored
            WorkoutSet(weightLb: 50, reps: 4, completed: true),     // 200
        ])
        XCTAssertEqual(logged.volumeLb, 1200, accuracy: 0.01)
    }

    func testWorkoutTotalVolumeSumsExercises() {
        let bench = LoggedExercise(exercise: MockData.exercise("bench"),
                                   sets: [WorkoutSet(weightLb: 100, reps: 10, completed: true)])
        let row = LoggedExercise(exercise: MockData.exercise("row"),
                                 sets: [WorkoutSet(weightLb: 50, reps: 10, completed: true)])
        let workout = Workout(name: "Test", date: .now, durationMin: 30,
                              exercises: [bench, row], avgRPE: 8, feel: .fine)
        XCTAssertEqual(workout.totalVolumeLb, 1500, accuracy: 0.01)
    }

    func testFinishingWorkoutPromotesPRs() {
        let service = WorkoutService()
        let before = service.personalRecords.count
        let exercise = MockData.exercise("bench")
        let logged = LoggedExercise(exercise: exercise, sets: [
            WorkoutSet(weightLb: 185, reps: 5, completed: true, isPR: true),
        ])
        service.finish(Workout(name: "PR Day", date: .now, durationMin: 40,
                               exercises: [logged], avgRPE: 9, feel: .fine))
        XCTAssertEqual(service.personalRecords.count, before + 1)
        XCTAssertEqual(service.history.first?.name, "PR Day")
    }
}
