import XCTest
@testable import Forge

/// Proves the intelligence loop is closed for training: a logged session becomes
/// strain, strain moves the Forge Score's Training Load component, and that moves
/// the Forge Score itself.
final class TrainingLoadTests: XCTestCase {

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: .now)!
    }

    // MARK: Pure engine

    func testSessionStrainBoundsAndDirection() {
        XCTAssertEqual(TrainingLoadEngine.sessionStrain(durationMin: 0, avgRPE: 10), 0)
        let easy = TrainingLoadEngine.sessionStrain(durationMin: 30, avgRPE: 5)
        let hard = TrainingLoadEngine.sessionStrain(durationMin: 90, avgRPE: 9.5)
        XCTAssertGreaterThan(hard, easy)                       // more/longer/harder → more strain
        XCTAssertLessThanOrEqual(hard, TrainingLoadEngine.maxStrain)
        XCTAssertGreaterThanOrEqual(easy, 0)
    }

    func testDayStrainSumsAndCaps() {
        let s = TrainingSession(date: .now, durationMin: 60, avgRPE: 8)
        let one = TrainingLoadEngine.dayStrain([s])
        let three = TrainingLoadEngine.dayStrain([s, s, s])
        XCTAssertGreaterThan(three, one)
        XCTAssertLessThanOrEqual(TrainingLoadEngine.dayStrain(Array(repeating: s, count: 20)),
                                 TrainingLoadEngine.maxStrain)
    }

    // MARK: End-to-end loop (session → strain → trainingLoadScore → forgeScore)

    func testHardDayLowersTrainingLoadScoreAndForgeScoreVsLightDay() {
        let hardApp = AppState()
        hardApp.applyTrainingLoad(sessions: [TrainingSession(date: daysAgo(1), durationMin: 120, avgRPE: 10)])

        let lightApp = AppState()
        lightApp.applyTrainingLoad(sessions: [TrainingSession(date: daysAgo(1), durationMin: 20, avgRPE: 5)])

        XCTAssertGreaterThan(hardApp.recovery.today.strainYesterday,
                             lightApp.recovery.today.strainYesterday)
        XCTAssertLessThan(hardApp.recovery.today.trainingLoadScore,
                          lightApp.recovery.today.trainingLoadScore)
        // The loop reaches the headline number the user sees.
        XCTAssertLessThan(hardApp.forgeScore, lightApp.forgeScore)
        XCTAssertTrue((0...100).contains(hardApp.forgeScore))
    }

    func testTodaysSessionSetsTodayStrain() {
        let app = AppState()
        app.applyTrainingLoad(sessions: [TrainingSession(date: .now, durationMin: 75, avgRPE: 8)])
        XCTAssertGreaterThan(app.recovery.today.strainToday, 0)
    }

    func testEmptySessionsLeaveDemoUntouched() {
        let app = AppState()
        let seededYesterday = app.recovery.today.strainYesterday
        app.applyTrainingLoad(sessions: [])
        XCTAssertEqual(app.recovery.today.strainYesterday, seededYesterday)
    }
}
