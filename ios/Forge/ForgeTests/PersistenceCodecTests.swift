import XCTest
@testable import Forge

final class PersistenceCodecTests: XCTestCase {

    func testExercisesRoundTrip() {
        let original = [
            LoggedExercise(exercise: MockData.exercise("bench"), sets: [
                WorkoutSet(weightLb: 180, reps: 5, rpe: 8.5, completed: true),
                WorkoutSet(weightLb: 185, reps: 3, completed: false),
            ]),
            LoggedExercise(exercise: MockData.exercise("row"), sets: [
                WorkoutSet(weightLb: 155, reps: 8, completed: true),
            ]),
        ]

        let json = PersistenceService.encodeExercises(original)
        XCTAssertFalse(json.isEmpty)
        let decoded = PersistenceService.decodeExercises(json)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].exercise.id, "bench")
        XCTAssertEqual(decoded[0].sets.count, 2)
        XCTAssertEqual(decoded[0].sets[0].weightLb, 180)
        XCTAssertEqual(decoded[0].sets[0].reps, 5)
        XCTAssertEqual(decoded[0].sets[0].rpe, 8.5)
        XCTAssertTrue(decoded[0].sets[0].completed)
        XCTAssertFalse(decoded[0].sets[1].completed)
        XCTAssertEqual(decoded[1].exercise.id, "row")
    }

    func testDecodeGarbageYieldsEmpty() {
        XCTAssertTrue(PersistenceService.decodeExercises("").isEmpty)
        XCTAssertTrue(PersistenceService.decodeExercises("not json").isEmpty)
    }

    func testRepeatSurvivesRoundTrip() {
        // The full loop that must work across relaunch: log → encode → decode
        // → planFromLastSession still produces a usable plan.
        let sets = [WorkoutSet(weightLb: 180, reps: 5, completed: true)]
        let logged = [LoggedExercise(exercise: MockData.exercise("bench"), sets: sets)]
        let restored = PersistenceService.decodeExercises(
            PersistenceService.encodeExercises(logged))

        let service = WorkoutService()
        service.history = [Workout(name: "Restored", date: .now, durationMin: 45,
                                   exercises: restored, avgRPE: 8, feel: .fine)]
        let plan = service.planFromLastSession()
        XCTAssertEqual(plan?.blocks.first?.items.first?.scheme, "1 × 5 @ 180 lb")
    }

    func testIsTestRunDetectsTests() {
        // The guard that keeps unit tests from writing into the real store.
        XCTAssertTrue(PersistenceService.isTestRun)
    }
}

final class FoodVisionMatchTests: XCTestCase {

    private let foods = [
        Food(id: "chicken", name: "Grilled Chicken Breast", serving: "6 oz",
             calories: 280, protein: 52, carbs: 0, fat: 6),
        Food(id: "rice", name: "White Rice", serving: "1 cup",
             calories: 205, protein: 4.3, carbs: 45, fat: 0.4),
        Food(id: "whey", name: "Whey Protein", serving: "1 scoop",
             calories: 120, protein: 25, carbs: 3, fat: 1),
    ]

    func testLabelMatchesFoodByWordOverlap() {
        let matches = FoodVision.match(labels: ["chicken", "plate"], in: foods)
        XCTAssertEqual(matches.map(\.id), ["chicken"])
    }

    func testMultiWordLabelAndUnderscoreNormalization() {
        // Vision identifiers arrive underscore-separated; classify() maps
        // "fried_rice" → "fried rice" before matching.
        let matches = FoodVision.match(labels: ["fried rice"], in: foods)
        XCTAssertEqual(matches.map(\.id), ["rice"])
    }

    func testNoFalsePositives() {
        XCTAssertTrue(FoodVision.match(labels: ["laptop", "desk"], in: foods).isEmpty)
    }

    func testDeduplicatesAcrossLabels() {
        let matches = FoodVision.match(labels: ["chicken", "grilled chicken"], in: foods)
        XCTAssertEqual(matches.filter { $0.id == "chicken" }.count, 1)
    }
}
