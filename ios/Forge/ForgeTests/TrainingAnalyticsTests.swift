import XCTest
@testable import Forge

final class TrainingAnalyticsTests: XCTestCase {

    private func session(daysAgo: Int, name: String = "Barbell Bench Press",
                         weight: Double, reps: Int, rpe: Double?) -> Workout {
        let bench = MockData.exercise("bench")
        var ex = bench
        // Use the mock exercise but honor a custom display name when testing other lifts.
        if name != bench.name {
            ex = Exercise(id: name, name: name, category: .compound,
                          primaryMuscles: [], secondaryMuscles: [], equipment: [],
                          difficulty: .intermediate, instructions: [], commonMistakes: [],
                          coachingTips: [], alternatives: [])
        }
        return Workout(
            name: "Test", date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
            durationMin: 60,
            exercises: [LoggedExercise(exercise: ex, sets: [
                WorkoutSet(weightLb: weight, reps: reps, rpe: rpe, completed: true),
            ])],
            avgRPE: rpe ?? 8, feel: .fine)
    }

    func testLiftTrendIsOldestFirstWithBestSetPerSession() {
        let history = [
            session(daysAgo: 2, weight: 185, reps: 5, rpe: 9),
            session(daysAgo: 9, weight: 180, reps: 5, rpe: 8.5),
        ]
        let trend = TrainingAnalyticsEngine.liftTrend(exerciseName: "Barbell Bench Press", history: history)
        XCTAssertEqual(trend.count, 2)
        XCTAssertLessThan(trend[0].date, trend[1].date)
        XCTAssertEqual(trend[1].bestE1RM, 185 * (1 + 5.0 / 30), accuracy: 0.01)
    }

    func testFlatLiftAtHighRPEIsRecoveryLimitedPlateau() {
        let history = [
            session(daysAgo: 2, weight: 180, reps: 5, rpe: 9),
            session(daysAgo: 9, weight: 180, reps: 5, rpe: 9),
            session(daysAgo: 16, weight: 180, reps: 5, rpe: 8.5),
        ]
        let findings = TrainingAnalyticsEngine.plateaus(history: history)
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.exerciseName, "Barbell Bench Press")
        XCTAssertTrue(findings.first!.recommendation.contains("recovery-limited"))
    }

    func testFlatLiftAtLowRPEIsStimulusLimited() {
        let history = [
            session(daysAgo: 2, weight: 180, reps: 5, rpe: 7.5),
            session(daysAgo: 9, weight: 180, reps: 5, rpe: 7.5),
            session(daysAgo: 16, weight: 180, reps: 5, rpe: 7),
        ]
        let findings = TrainingAnalyticsEngine.plateaus(history: history)
        XCTAssertTrue(findings.first!.recommendation.contains("microload") ||
                      findings.first!.recommendation.contains("Add a set"))
    }

    func testProgressingLiftIsNotAPlateau() {
        let history = [
            session(daysAgo: 2, weight: 190, reps: 5, rpe: 8.5),
            session(daysAgo: 9, weight: 185, reps: 5, rpe: 8.5),
            session(daysAgo: 16, weight: 180, reps: 5, rpe: 8.5),
        ]
        XCTAssertTrue(TrainingAnalyticsEngine.plateaus(history: history).isEmpty)
    }

    func testTwoSessionsAreNotEnoughToJudge() {
        let history = [
            session(daysAgo: 2, weight: 180, reps: 5, rpe: 9),
            session(daysAgo: 9, weight: 180, reps: 5, rpe: 9),
        ]
        XCTAssertTrue(TrainingAnalyticsEngine.plateaus(history: history).isEmpty)
    }

    func testWeakPointsAreBelowVolumeFloor() {
        let weak = TrainingAnalyticsEngine.weakPoints(volume: MockData.muscleVolume)
        XCTAssertEqual(weak.map(\.muscle), ["Quads"], "Demo athlete under-trains quads (knee rehab)")
    }

    func testDemoAthleteBenchPlateauIsDetected() {
        // The coach's "bench stalled" story must be backed by real analysis.
        let service = WorkoutService()
        let bench = service.plateaus.first { $0.exerciseName == "Barbell Bench Press" }
        XCTAssertNotNil(bench)
        XCTAssertEqual(Int(bench!.bestE1RM), 210)
        XCTAssertTrue(bench!.recommendation.contains("recovery-limited"))
    }

    func testCoachContextCarriesPlateauNote() {
        let app = AppState()
        XCTAssertTrue(app.coachContext.plateauNote.contains("Barbell Bench Press"))
        let prompt = AIService.systemPrompt(context: app.coachContext, checkInNote: nil)
        XCTAssertTrue(prompt.contains("Lift watch:"))
    }

    func testWeeklyVolumeOnlyCountsLastSevenDays() {
        let service = WorkoutService()
        // History spans 16 days; the -9 and -16 day sessions must not count.
        let recent = service.history.filter {
            $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        }
        XCTAssertEqual(service.weeklyVolumeLb,
                       recent.reduce(0) { $0 + $1.totalVolumeLb }, accuracy: 0.01)
    }
}
