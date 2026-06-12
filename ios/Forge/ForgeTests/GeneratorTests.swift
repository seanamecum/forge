import XCTest
@testable import Forge

final class GeneratorTests: XCTestCase {

    private func allItemNames(_ plan: GeneratedWorkout) -> [String] {
        plan.blocks.flatMap(\.items).map(\.name)
    }

    func testKneeInjuryRemovesKneeStressors() {
        let plan = WorkoutService().generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                                             recovery: 78, injuries: [.knee], level: .intermediate)
        let names = allItemNames(plan).joined(separator: " ")
        XCTAssertFalse(names.contains("Back Squat"))
        XCTAssertFalse(names.contains("Walking Lunge"))
        XCTAssertTrue(names.contains("Hip Thrust"), "Knee-safe swap should appear")
    }

    func testShoulderInjuryRemovesOverheadPressing() {
        let plan = WorkoutService().generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                                             recovery: 78, injuries: [.shoulder], level: .intermediate)
        let names = allItemNames(plan).joined(separator: " ")
        XCTAssertFalse(names.contains("Barbell Bench Press"))
        XCTAssertTrue(names.contains("neutral grip"), "Neutral-grip swap should appear")
    }

    func testBackInjuryRemovesSpinalLoaders() {
        let plan = WorkoutService().generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                                             recovery: 78, injuries: [.back], level: .intermediate)
        let names = allItemNames(plan).joined(separator: " ")
        XCTAssertFalse(names.contains("Barbell Row"))
        XCTAssertTrue(names.contains("Chest-Supported Row"))
    }

    func testLowRecoveryCapsIntensity() {
        let plan = WorkoutService().generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                                             recovery: 45, injuries: [], level: .intermediate)
        XCTAssertTrue(plan.rationale.contains("RPE 7"), "Low recovery must cap intensity")
        let schemes = plan.blocks.flatMap(\.items).map(\.scheme).joined(separator: " ")
        XCTAssertTrue(schemes.contains("3 ×"), "Low recovery must reduce set count")
    }

    func testHighRecoveryAllowsProgression() {
        let plan = WorkoutService().generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                                             recovery: 88, injuries: [], level: .intermediate)
        XCTAssertTrue(plan.rationale.contains("green light"))
    }
}
