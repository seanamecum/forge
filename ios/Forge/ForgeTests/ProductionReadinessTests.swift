import XCTest
@testable import Forge

// MARK: - Coach pipeline (live-mode message shape + context threading)

final class CoachPipelineTests: XCTestCase {

    func testAPIMessagesStartWithUser() {
        let history: [CoachMessage] = [
            CoachMessage(role: .coach, text: "Morning, Sean."),   // seed turn must be dropped
            CoachMessage(role: .user, text: "Should I deload?"),
            CoachMessage(role: .coach, text: "Not yet."),
        ]
        let messages = AIService.buildAPIMessages(question: "Why not?", history: history)
        XCTAssertEqual(messages.first?.role, "user")
        XCTAssertEqual(messages.last, AIService.APIMessage(role: "user", content: "Why not?"))
    }

    /// Regression: the view model appends the user's message to `messages` before
    /// calling the service. The question must reach the API exactly once even if
    /// a caller passes history that already ends with it.
    func testAPIMessagesDropTrailingDuplicateQuestion() {
        let history: [CoachMessage] = [
            CoachMessage(role: .user, text: "Should I deload?"),
            CoachMessage(role: .coach, text: "Not yet."),
            CoachMessage(role: .user, text: "Why not?"),          // duplicate of the question
        ]
        let messages = AIService.buildAPIMessages(question: "Why not?", history: history)
        XCTAssertEqual(messages.filter { $0.content == "Why not?" }.count, 1)
        XCTAssertEqual(messages.count, 3)
    }

    func testAPIMessagesWindowIsBounded() {
        let long = (0..<40).map { i in
            CoachMessage(role: i.isMultiple(of: 2) ? .user : .coach, text: "turn \(i)")
        }
        let messages = AIService.buildAPIMessages(question: "latest", history: long)
        XCTAssertLessThanOrEqual(messages.count, 13)  // 12-turn window + the question
    }

    func testSystemPromptReflectsLiveContext() {
        var ctx = CoachContext.demo
        ctx.proteinRemaining = 137
        ctx.hydrationPct = 41
        ctx.forgeScore = 66
        ctx.name = "Alex Rivera"
        let prompt = AIService.systemPrompt(context: ctx, checkInNote: nil)
        XCTAssertTrue(prompt.contains("137g protein still to go"))
        XCTAssertTrue(prompt.contains("hydration at 41%"))
        XCTAssertTrue(prompt.contains("Forge Score 66"))
        XCTAssertTrue(prompt.contains("Alex Rivera"))
    }

    func testDailyBriefAgreesWithDirective() {
        var ctx = CoachContext.demo
        let brief = AIService.dailyBrief(context: ctx)
        XCTAssertTrue(brief.contains("Forge Score \(ctx.forgeScore)"))
        XCTAssertTrue(brief.contains("\(ctx.proteinRemaining) g protein"))

        // A recovery-day directive must not read like a green light.
        ctx.directive = DirectiveEngine.make(
            recovery: 45, sleepDebtHours: 4, proteinRemaining: 0, hydrationPct: 90,
            injuryRiskPercent: 10, injuryRiskBand: "Low",
            activeInjuryName: nil, activeInjuryPain: nil, workoutName: "Recovery Spin")
        ctx.recovery = 45
        ctx.proteinRemaining = 0
        let lowBrief = AIService.dailyBrief(context: ctx)
        XCTAssertTrue(lowBrief.lowercased().contains("pull back"))
        XCTAssertFalse(lowBrief.contains("protein gap"))
    }
}

// MARK: - Time-of-day greeting

final class DaypartTests: XCTestCase {

    func testGreetingBoundaries() {
        XCTAssertEqual(Daypart.greeting(hour: 4), "Evening")   // pre-dawn reads as evening
        XCTAssertEqual(Daypart.greeting(hour: 5), "Morning")
        XCTAssertEqual(Daypart.greeting(hour: 11), "Morning")
        XCTAssertEqual(Daypart.greeting(hour: 12), "Afternoon")
        XCTAssertEqual(Daypart.greeting(hour: 16), "Afternoon")
        XCTAssertEqual(Daypart.greeting(hour: 17), "Evening")
        XCTAssertEqual(Daypart.greeting(hour: 23), "Evening")
    }
}

// MARK: - Live plan generation (profile-driven, not canned)

final class LivePlanTests: XCTestCase {

    func testTodaysPlanRespectsActiveInjury() {
        let app = AppState()
        // Demo athlete has an active knee injury → plan must be knee-safe.
        XCTAssertTrue(app.todaysPlan.rationale.contains("Knee flag"))

        // Injury resolved → the knee constraint disappears from the same pipeline.
        app.injuries.active = []
        XCTAssertFalse(app.todaysPlan.rationale.contains("Knee flag"))
    }

    func testTodaysPlanTracksRecovery() {
        let app = AppState()
        app.recovery.today.recovery = 45
        XCTAssertTrue(app.todaysPlan.rationale.contains("RPE 7"),
                      "Low recovery must cap intensity in the generated plan")
        app.recovery.today.recovery = 90
        XCTAssertTrue(app.todaysPlan.rationale.contains("green light"))
    }

    func testDirectiveWorkoutNameMatchesTodaysPlan() {
        let app = AppState()
        XCTAssertEqual(app.dailyDirective.workoutName, app.todaysPlan.name,
                       "Dashboard directive and Train tab must describe the same session")
    }

    func testCoachContextMirrorsLiveServices() {
        let app = AppState()
        let ctx = app.coachContext
        XCTAssertEqual(ctx.proteinRemaining, app.nutrition.proteinRemaining)
        XCTAssertEqual(ctx.hydrationPct, app.nutrition.hydrationPct)
        XCTAssertEqual(ctx.forgeScore, app.forgeScore)
        XCTAssertEqual(ctx.directive, app.dailyDirective)

        // Logging water must flow straight through to what the coach sees.
        app.nutrition.addWater(16)
        XCTAssertEqual(app.coachContext.hydrationPct, app.nutrition.hydrationPct)
    }
}

// MARK: - Nutrition hardening

final class NutritionHardeningTests: XCTestCase {

    func testSupplementStreakNeverGoesNegative() {
        let n = NutritionService()
        guard var first = n.supplements.first else { return XCTFail("no supplements seeded") }
        first.streak = 0
        first.loggedToday = true
        n.supplements[0] = first

        n.toggleSupplement(n.supplements[0])   // un-log at streak 0
        XCTAssertEqual(n.supplements[0].streak, 0, "Streak must clamp at zero")
        n.toggleSupplement(n.supplements[0])   // re-log
        XCTAssertEqual(n.supplements[0].streak, 1)
    }

    func testWaterTargetIsAlwaysPositive() {
        // Guards the hydrationPct divide — every reachable profile has a real target.
        for weight in [80.0, 100, 200, 400] {
            var p = MockData.sean
            p.weightLb = weight
            XCTAssertGreaterThan(TargetEngine.water(p), 0)
        }
    }

    func testCarbTargetNeverNegative() {
        var p = MockData.sean
        p.weightLb = 90          // extreme low-calorie profile
        p.goals = [.loseFat]
        p.activityLevel = .sedentary
        XCTAssertGreaterThanOrEqual(TargetEngine.carbs(p), 0)
    }
}
