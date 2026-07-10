import XCTest
@testable import Forge

/// Hevy-grade logging intelligence: last-time ghosts, PR baselines, and live
/// PR detection — the loop that makes every workout feed the next one.
final class TrainingExperienceTests: XCTestCase {

    func testLastPerformanceFindsBestCompletedSetFromLatestSession() {
        let service = WorkoutService()
        let last = service.lastPerformance(of: "Barbell Bench Press")
        XCTAssertNotNil(last, "Demo history contains bench sessions")
        // Best set of the most recent bench day: 180 × 5 (e1RM 210).
        XCTAssertEqual(last?.weightLb, 180)
        XCTAssertEqual(last?.reps, 5)
    }

    func testLastPerformanceIsNilForNeverTrainedExercise() {
        XCTAssertNil(WorkoutService().lastPerformance(of: "Nordic Curl"))
    }

    func testPRBaselineUsesBestEstimatedOneRepMax() {
        let service = WorkoutService()
        service.personalRecords = [
            PersonalRecord(exerciseName: "Back Squat", weightLb: 225, reps: 3, date: "May 2"),
            PersonalRecord(exerciseName: "Back Squat", weightLb: 230, reps: 1, date: "Jun 8"),
        ]
        // 225×3 → e1RM 247.5 beats 230×1 → 230.
        XCTAssertEqual(service.prBaseline(for: "Back Squat")!, 247.5, accuracy: 0.01)
    }

    func testPRCandidateBeatsBaseline() {
        let service = WorkoutService()
        service.personalRecords = [
            PersonalRecord(exerciseName: "Barbell Bench Press", weightLb: 180, reps: 5, date: "Jun 20"),
        ]   // baseline e1RM 210
        XCTAssertTrue(service.isPRCandidate(WorkoutSet(weightLb: 185, reps: 5, completed: true),
                                            exerciseName: "Barbell Bench Press"))
        XCTAssertFalse(service.isPRCandidate(WorkoutSet(weightLb: 175, reps: 5, completed: true),
                                             exerciseName: "Barbell Bench Press"))
        XCTAssertFalse(service.isPRCandidate(WorkoutSet(weightLb: 0, reps: 5, completed: true),
                                             exerciseName: "Barbell Bench Press"),
                       "Empty sets can never be records")
    }

    func testFirstEverSetIsAlwaysARecord() {
        let service = WorkoutService()
        service.personalRecords = []
        XCTAssertTrue(service.isPRCandidate(WorkoutSet(weightLb: 95, reps: 8, completed: true),
                                            exerciseName: "Nordic Curl"))
    }

    func testLivePRFlowPromotesRecordOnFinish() {
        let service = WorkoutService()
        let baseline = service.prBaseline(for: "Barbell Bench Press")!
        var prSet = WorkoutSet(weightLb: 190, reps: 5)
        prSet.completed = true
        prSet.isPR = service.isPRCandidate(prSet, exerciseName: "Barbell Bench Press")
        XCTAssertTrue(prSet.isPR)

        let bench = MockData.exercise("bench")
        let workout = Workout(name: "Test", date: .now, durationMin: 45,
                              exercises: [LoggedExercise(exercise: bench, sets: [prSet])],
                              avgRPE: 8.5, feel: .fine)
        service.finish(workout)

        XCTAssertEqual(service.personalRecords.first?.weightLb, 190,
                       "The live-flagged PR must land on the record board")
        XCTAssertGreaterThan(service.prBaseline(for: "Barbell Bench Press")!, baseline)
    }

    func testGhostPrefillMatchesLastPerformance() {
        // The logger seeds new sessions from lastPerformance — verify the pair
        // it would use is the real most-recent best, not a stale one.
        let service = WorkoutService()
        let ghost = service.lastPerformance(of: "Barbell Bench Press")!
        XCTAssertEqual(ghost.estimatedOneRepMax, 180 * (1 + 5.0 / 30), accuracy: 0.01)
    }
}
