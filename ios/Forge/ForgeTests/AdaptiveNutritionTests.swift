import XCTest
@testable import Forge

final class AdaptiveNutritionTests: XCTestCase {

    private func inputs(goal: Goal = .buildMuscle,
                        weight: [Double] = [],
                        strain: Double = 10,
                        recovery: Int = 80,
                        injury: Bool = false,
                        endurance: Bool = false) -> AdaptiveNutritionEngine.Inputs {
        .init(baseCalories: 3200, baseProtein: 200, baseWaterOz: 120,
              goal: goal, weightTrend: weight, strainAvg7: strain,
              recoveryToday: recovery, injuryActive: injury, enduranceTomorrow: endurance)
    }

    func testQuietWeekMakesNoAdjustments() {
        let plan = AdaptiveNutritionEngine.plan(inputs())
        XCTAssertFalse(plan.isAdjusted)
        XCTAssertEqual(plan.calories, 3200)
        XCTAssertEqual(plan.protein, 200)
        XCTAssertTrue(plan.headline.contains("on plan"))
    }

    func testHeavyTrainingWeekRaisesCalories() {
        let plan = AdaptiveNutritionEngine.plan(inputs(strain: 14.5))
        XCTAssertEqual(plan.calories, 3350)
        XCTAssertTrue(plan.adjustments.contains { $0.id == "training-load" })
        XCTAssertTrue(plan.adjustments.first { $0.id == "training-load" }!.reason.contains("14.5"),
                      "The reason must cite the actual signal")
    }

    func testFatLossPlateauCutsCalories() {
        let flat = Array(repeating: 185.0, count: 14)
        let plan = AdaptiveNutritionEngine.plan(inputs(goal: .loseFat, weight: flat))
        XCTAssertEqual(plan.calories, 3100)
        XCTAssertTrue(plan.adjustments.contains { $0.id == "plateau-cut" })
    }

    func testOnPaceFatLossIsLeftAlone() {
        let dropping = (0..<14).map { 185.0 - Double($0) * 0.15 }   // ~1 lb/wk
        let plan = AdaptiveNutritionEngine.plan(inputs(goal: .loseFat, weight: dropping))
        XCTAssertFalse(plan.adjustments.contains { $0.id == "plateau-cut" },
                       "Working plans don't get touched")
    }

    func testStalledBulkAddsCalories() {
        let flat = Array(repeating: 200.0, count: 14)
        let plan = AdaptiveNutritionEngine.plan(inputs(goal: .buildMuscle, weight: flat))
        XCTAssertTrue(plan.adjustments.contains { $0.id == "stalled-gain" })
    }

    func testInjuryRaisesProtein() {
        let plan = AdaptiveNutritionEngine.plan(inputs(injury: true))
        XCTAssertEqual(plan.protein, 215)
        XCTAssertTrue(plan.adjustments.first { $0.id == "injury-protein" }!.reason.lowercased().contains("repair"))
    }

    func testLowRecoveryRaisesWater() {
        let plan = AdaptiveNutritionEngine.plan(inputs(recovery: 45))
        XCTAssertEqual(plan.waterOz, 136)
    }

    func testEnduranceTomorrowCarbLoads() {
        let plan = AdaptiveNutritionEngine.plan(inputs(endurance: true))
        XCTAssertTrue(plan.adjustments.contains { $0.id == "carb-load" })
    }

    func testAdjustmentsStack() {
        let plan = AdaptiveNutritionEngine.plan(inputs(strain: 15, injury: true))
        XCTAssertEqual(plan.calories, 3350)
        XCTAssertEqual(plan.protein, 215)
        XCTAssertEqual(plan.adjustments.count, 2)
    }

    func testShortWeightHistoryNeverJudgesProgress() {
        let plan = AdaptiveNutritionEngine.plan(inputs(goal: .loseFat, weight: [185, 185, 185]))
        XCTAssertFalse(plan.adjustments.contains { $0.id == "plateau-cut" },
                       "Three days is noise, not a plateau")
    }

    // MARK: - Integration: the plan drives every surface

    func testDemoAthletePlanIsCoherent() {
        let app = AppState()
        // Sean: heavy training week (strain avg ≥14) + active knee rehab.
        let plan = app.nutrition.activePlan
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.calories, 3350)
        XCTAssertEqual(plan?.protein, 215)
        // Coached calories flow into the gram targets: fat holds, carbs absorb.
        XCTAssertEqual(plan?.fat, 95)
        XCTAssertEqual(plan?.carbs, 405)
        XCTAssertEqual(app.nutrition.carbTarget, 405,
                       "Fuel bars must show the redistributed carb target, not the base")
    }

    func testMacrosReconcileToCoachedCalories() {
        let app = AppState()
        let plan = app.nutrition.activePlan!
        let reconstructed = plan.protein * 4 + plan.carbs * 4 + plan.fat * 9
        XCTAssertEqual(Double(reconstructed), Double(plan.calories), accuracy: 25,
                       "Protein + carbs + fat must add back up to the coached calories (within rounding)")
    }

    func testDirectiveAndCoachSpeakCoachedTargets() {
        let app = AppState()
        let fuel = app.dailyDirective.actions.first { $0.kind == .fuel }
        XCTAssertEqual(fuel?.value, "3,350 kcal",
                       "The Directive must show the coached target, not the base")
        XCTAssertEqual(app.coachContext.calorieTarget, 3350)
        XCTAssertEqual(app.coachContext.proteinTarget, 215)
    }

    func testServiceRemainingUsesCoachedTargets() {
        let app = AppState()
        XCTAssertEqual(app.nutrition.proteinRemaining,
                       max(0, 215 - app.nutrition.protein))
    }
}
