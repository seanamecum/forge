import XCTest
@testable import Forge

final class RepeatSessionTests: XCTestCase {

    private func makeWorkout(name: String = "Push Day", daysAgo: Int = 2) -> Workout {
        let bench = MockData.exercise("bench")
        let sets = [
            WorkoutSet(weightLb: 180, reps: 5, completed: true),
            WorkoutSet(weightLb: 180, reps: 5, completed: true),
            WorkoutSet(weightLb: 185, reps: 3, completed: true),
        ]
        return Workout(
            name: name,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
            durationMin: 55,
            exercises: [LoggedExercise(exercise: bench, sets: sets)],
            avgRPE: 8, feel: .fine)
    }

    func testPlanMirrorsLastSession() {
        let service = WorkoutService()
        service.history = [makeWorkout()]

        let plan = service.planFromLastSession()
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.name, "Push Day")
        XCTAssertEqual(plan?.estMinutes, 55)

        let items = plan?.blocks.flatMap(\.items) ?? []
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.exerciseID, "bench")
        // Top set by e1RM: 180×5 (210) beats 185×3 (203.5), so the scheme
        // shows 3 completed sets at the 180×5 top set.
        XCTAssertEqual(items.first?.scheme, "3 × 5 @ 180 lb")
    }

    func testBlockLabelSeedsTheLogger() {
        // The logger only seeds blocks labeled Main…/Accessory… — a repeat
        // plan must qualify or it opens empty.
        let service = WorkoutService()
        service.history = [makeWorkout()]
        let label = service.planFromLastSession()?.blocks.first?.label ?? ""
        XCTAssertTrue(label.hasPrefix("Main"))
    }

    func testEmptyHistoryYieldsNoPlan() {
        let service = WorkoutService()
        service.history = []
        XCTAssertNil(service.planFromLastSession())
    }

    func testSessionWithNoExercisesYieldsNoPlan() {
        let service = WorkoutService()
        var run = makeWorkout()
        run.exercises = []
        service.history = [run]
        XCTAssertNil(service.planFromLastSession())
    }

    func testUncompletedSetsStillProduceAScheme() {
        // Abandoned session: sets exist but none completed — fall back to
        // planned sets rather than dropping the exercise.
        let service = WorkoutService()
        let bench = MockData.exercise("bench")
        let workout = Workout(
            name: "Abandoned", date: .now, durationMin: 10,
            exercises: [LoggedExercise(exercise: bench,
                                       sets: [WorkoutSet(weightLb: 0, reps: 0),
                                              WorkoutSet(weightLb: 0, reps: 0)])],
            avgRPE: 5, feel: .fine)
        service.history = [workout]
        let item = service.planFromLastSession()?.blocks.first?.items.first
        XCTAssertEqual(item?.scheme, "2 sets · match last time")
    }
}
