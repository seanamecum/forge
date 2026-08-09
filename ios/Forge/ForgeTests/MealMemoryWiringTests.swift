import XCTest
import SwiftData
@testable import Forge

/// Phase 2.2b: Smart Meal Memory wired into the app — the live diary produces
/// remembered meals + proactive suggestions, one-tap re-logs the usual, and
/// personalization signals derive from history. Demo never learns real data.
@MainActor
final class MealMemoryWiringTests: XCTestCase {

    private var cal: Calendar { .current }

    private func egg() -> CanonicalFood {
        CanonicalFood(id: "egg", name: "Eggs",
                      per100g: NutrientVector([.calories: 155, .protein: 13]),
                      portions: [.portion(id: "egg", label: "egg", plural: "eggs", grams: 50, source: .usda)],
                      defaultUnitID: "egg")
    }
    private func coffee() -> CanonicalFood {
        CanonicalFood(id: "coffee", name: "Coffee", per100g: NutrientVector([.calories: 2]),
                      portions: [.portion(id: "cup", label: "cup", grams: 240, source: .usda)], defaultUnitID: "cup")
    }

    private func cleanDiary() {
        let ctx = PersistenceService.context
        try? ctx.delete(model: DiaryEntry.self); try? ctx.save()
    }

    /// Seed a recurring breakfast (eggs + coffee) across the last `days` days at 8 am.
    private func seedBreakfasts(days: Int) {
        let ctx = PersistenceService.context
        for d in 1...days {
            let at = cal.date(byAdding: .hour, value: 8, to: cal.startOfDay(for: cal.date(byAdding: .day, value: -d, to: .now)!))!
            ctx.insert(DiaryEntry.log(food: egg(), quantity: FoodQuantity(amount: 3, unitID: "egg"), meal: .breakfast, at: at)!)
            ctx.insert(DiaryEntry.log(food: coffee(), quantity: FoodQuantity(amount: 1, unitID: "cup"), meal: .breakfast, at: at)!)
        }
        try? ctx.save()
    }

    func testAppLearnsARecurringMealFromTheDiary() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        seedBreakfasts(days: 7)
        let meals = app.rememberedMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(Set(meals[0].items.map(\.foodID)), ["egg", "coffee"])
        XCTAssertEqual(meals[0].occurrences, 7)
    }

    func testProactiveSuggestionAndOneTapLog() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        seedBreakfasts(days: 7)

        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let suggestions = app.mealSuggestions(for: .breakfast, now: morning)
        XCTAssertEqual(suggestions.first?.title, "Log your usual breakfast?")

        // One tap logs it into today's breakfast.
        app.logRememberedMeal(suggestions.first!, into: .breakfast)
        let today = PersistenceService.loadTodayDiary().filter { $0.meal == "Breakfast" }
        XCTAssertEqual(Set(today.map(\.foodID)), ["egg", "coffee"])
        XCTAssertEqual(today.first { $0.foodID == "egg" }?.consumed[.calories], 155 * 1.5) // 3 eggs re-logged
    }

    func testPartialMatchSuppressesAfterFullyLogged() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        seedBreakfasts(days: 7)
        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!

        app.logRememberedMeal(app.mealSuggestions(for: .breakfast, now: morning).first!, into: .breakfast)
        // Now the usual breakfast is fully logged → no more suggestion for it.
        XCTAssertTrue(app.mealSuggestions(for: .breakfast, now: morning).isEmpty)
    }

    func testPersonalSignalsReflectHistory() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: false)
        seedBreakfasts(days: 7)
        let signals = app.foodPersonalSignals()
        XCTAssertEqual(signals.frequency["egg"], 7)
        XCTAssertTrue(signals.recentFoodIDs.contains("egg"))
    }

    func testDemoNeverLearns() {
        cleanDiary()
        let app = AppState(); app.completeAuth(demo: true)
        // Even if entries existed, demo returns nothing from personalization.
        XCTAssertTrue(app.rememberedMeals().isEmpty)
        XCTAssertTrue(app.mealSuggestions(for: .breakfast).isEmpty)
        XCTAssertEqual(app.foodPersonalSignals().frequency.count, 0)
    }
}
