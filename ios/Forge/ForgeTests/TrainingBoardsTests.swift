import XCTest
@testable import Forge

/// The PR and weekly muscle-volume boards, derived from real logged sessions
/// (they used to be demo-seeded, so a real account saw them empty).
final class TrainingBoardsTests: XCTestCase {

    private func workout(_ ex: Exercise, weight: Double, reps: Int, sets: Int,
                         completed: Bool, date: Date) -> Workout {
        Workout(name: "W", date: date, durationMin: 30,
                exercises: [LoggedExercise(exercise: ex,
                    sets: (0..<sets).map { _ in WorkoutSet(weightLb: weight, reps: reps, completed: completed) })],
                avgRPE: 8, feel: .fine)
    }

    // MARK: - Personal records

    func testPRPicksHighestE1RMWithRealDate() {
        let ex = MockData.exercises[0]
        let older = workout(ex, weight: 185, reps: 5, sets: 1, completed: true,
                            date: Date(timeIntervalSince1970: 1_000_000))   // e1RM 215.8
        let newer = workout(ex, weight: 200, reps: 3, sets: 1, completed: true,
                            date: Date(timeIntervalSince1970: 2_000_000))   // e1RM 220 → wins
        let prs = TrainingAnalyticsEngine.personalRecords(from: [newer, older])
        XCTAssertEqual(prs.count, 1)
        XCTAssertEqual(prs[0].weightLb, 200)
        XCTAssertEqual(prs[0].reps, 3)
        XCTAssertFalse(prs[0].date.isEmpty)
        XCTAssertNotEqual(prs[0].date, "Today")   // real formatted date, not the old placeholder
    }

    func testPRIgnoresUncompletedSets() {
        let ex = MockData.exercises[1]
        let notDone = workout(ex, weight: 300, reps: 5, sets: 1, completed: false,
                              date: Date(timeIntervalSince1970: 1_000_000))
        XCTAssertTrue(TrainingAnalyticsEngine.personalRecords(from: [notDone]).isEmpty)
    }

    // MARK: - Muscle volume

    func testMuscleVolumeCountsOnlyInWindow() {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let chest = MockData.exercises.first { $0.primaryMuscles == ["Chest"] }!
        let recent = workout(chest, weight: 100, reps: 5, sets: 3, completed: true, date: now)
        let stale = workout(chest, weight: 100, reps: 5, sets: 3, completed: true,
                            date: now.addingTimeInterval(-8 * 86_400))   // 8 days ago → excluded
        let vol = TrainingAnalyticsEngine.muscleVolume(from: [recent, stale], days: 7, now: now)
        XCTAssertEqual(vol.first { $0.muscle == "Chest" }?.sets, 3)
        XCTAssertNil(vol.first { $0.muscle == "Back" })   // nothing trained it → omitted
    }

    func testMuscleGroupMapping() {
        XCTAssertEqual(TrainingAnalyticsEngine.muscleGroup(for: "Front Delts"), "Shoulders")
        XCTAssertEqual(TrainingAnalyticsEngine.muscleGroup(for: "Lats"), "Back")
        XCTAssertEqual(TrainingAnalyticsEngine.muscleGroup(for: "Biceps"), "Arms")
        XCTAssertEqual(TrainingAnalyticsEngine.muscleGroup(for: "Glutes"), "Glutes")
        XCTAssertNil(TrainingAnalyticsEngine.muscleGroup(for: "Cardiovascular"))
    }

    func testEmptyHistoryYieldsEmptyBoards() {
        XCTAssertTrue(TrainingAnalyticsEngine.personalRecords(from: []).isEmpty)
        XCTAssertTrue(TrainingAnalyticsEngine.muscleVolume(from: []).isEmpty)
    }
}
