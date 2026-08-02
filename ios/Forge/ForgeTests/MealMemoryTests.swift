import XCTest
@testable import Forge

/// Phase 2.2a: Smart Meal Memory + prediction — Forge learns the user's recurring
/// meals from the diary and proactively suggests "Log your usual breakfast?" at the
/// right moment. Pure engine, deterministic (`now`/`calendar` injected).
final class MealMemoryTests: XCTestCase {

    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    /// A day at a fixed hour, N days before `ref`.
    private func day(_ daysAgo: Int, hour: Int, from ref: Date) -> (day: Date, at: Date) {
        let d = cal.date(byAdding: .day, value: -daysAgo, to: ref)!
        let start = cal.startOfDay(for: d)
        let at = cal.date(byAdding: .hour, value: hour, to: start)!
        return (start, at)
    }

    private func log(_ daysAgo: Int, hour: Int, meal: MealType, foods: [(String, String)], from ref: Date) -> [LoggedFood] {
        let d = day(daysAgo, hour: hour, from: ref)
        return foods.map { LoggedFood(day: d.day, loggedAt: d.at, meal: meal.rawValue,
                                      foodID: $0.0, foodName: $0.1, amount: 1, unitID: "serving", unitLabel: "serving") }
    }

    // A Wednesday noon reference so weekday/weekend logic is stable.
    private var ref: Date { cal.date(from: DateComponents(year: 2026, month: 3, day: 4, hour: 12))! }

    private let breakfast = [("egg", "Eggs"), ("bread", "Sourdough"), ("coffee", "Coffee")]

    // MARK: - Recurring meal detection

    func testDetectsARecurringBreakfast() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let meals = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        XCTAssertEqual(meals.count, 1)
        let m = meals[0]
        XCTAssertEqual(m.meal, MealType.breakfast.rawValue)
        XCTAssertEqual(m.occurrences, 5)
        XCTAssertEqual(Set(m.items.map(\.foodID)), ["egg", "bread", "coffee"])
        XCTAssertEqual(m.typicalHour, 8)
        XCTAssertEqual(m.label, "your usual breakfast")
    }

    func testBelowThresholdIsNotRemembered() {
        var logs: [LoggedFood] = []
        for d in [1, 2] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }  // only twice
        XCTAssertTrue(MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal).isEmpty)
    }

    func testStaleMealIsNotRemembered() {
        var logs: [LoggedFood] = []
        for d in [40, 41, 42] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }  // >21d ago
        XCTAssertTrue(MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal).isEmpty)
    }

    func testWeekdayBiasDetected() {
        // Log breakfast on 5 recent weekdays (skipping the weekend around the ref).
        var logs: [LoggedFood] = []
        for d in [1, 2, 5, 6, 7] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let m = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal).first!
        XCTAssertEqual(m.weekdayBias, .weekday)
    }

    func testRepresentativeItemsUseTheMostCommonAmount() {
        // Same breakfast 4×, but the eggs amount varies (3,3,3,2) → representative = 3.
        var logs: [LoggedFood] = []
        for (i, d) in [1, 2, 3, 4].enumerated() {
            let dd = day(d, hour: 8, from: ref)
            let eggAmt: Double = i == 3 ? 2 : 3
            logs.append(LoggedFood(day: dd.day, loggedAt: dd.at, meal: MealType.breakfast.rawValue,
                                   foodID: "egg", foodName: "Eggs", amount: eggAmt, unitID: "egg", unitLabel: "egg"))
            logs.append(LoggedFood(day: dd.day, loggedAt: dd.at, meal: MealType.breakfast.rawValue,
                                   foodID: "coffee", foodName: "Coffee", amount: 1, unitID: "cup", unitLabel: "cup"))
        }
        let m = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal).first!
        XCTAssertEqual(m.items.first { $0.foodID == "egg" }?.amount, 3)
    }

    func testDifferentFoodSetsAreDifferentMeals() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        for d in [4, 5, 6] { logs += log(d, hour: 13, meal: .lunch, foods: [("chicken", "Chicken"), ("rice", "Rice")], from: ref) }
        let meals = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        XCTAssertEqual(meals.count, 2)
    }

    // MARK: - Frequent / recent foods

    func testFrequentAndRecentFoods() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        logs += log(1, hour: 20, meal: .snack, foods: [("banana", "Banana")], from: ref)  // once, recent
        let freq = MealMemory.frequentFoods(from: logs, now: ref, calendar: cal)
        XCTAssertEqual(freq.first?.count, 5)                        // eggs/bread/coffee logged 5×
        let recent = MealMemory.recentFoods(from: logs)
        XCTAssertTrue(recent.contains { $0.foodID == "banana" })    // most-recent surfaces
    }

    // MARK: - Proactive suggestions

    func testSuggestsUsualBreakfastInTheMorning() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        // 8 am, in the breakfast section, nothing logged yet.
        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: ref)!
        let ctx = SuggestionContext(now: morning, meal: .breakfast, alreadyLoggedFoodIDs: [], calendar: cal)
        let sug = MealSuggester.suggestions(remembered: remembered, context: ctx)
        XCTAssertEqual(sug.first?.title, "Log your usual breakfast?")
        XCTAssertEqual(sug.first?.itemsToLog.count, 3)
        XCTAssertGreaterThan(sug.first?.score ?? 0, MealSuggester.minScore)
    }

    func testPartialMatchOffersTheRest() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: ref)!
        // Already logged the eggs today → suggest finishing with bread + coffee.
        let ctx = SuggestionContext(now: morning, meal: .breakfast, alreadyLoggedFoodIDs: ["egg"], calendar: cal)
        let s = MealSuggester.suggestions(remembered: remembered, context: ctx).first!
        XCTAssertTrue(s.isPartial)
        XCTAssertEqual(s.title, "Finish your usual breakfast?")
        XCTAssertEqual(Set(s.itemsToLog.map(\.foodID)), ["bread", "coffee"])
    }

    func testFullyLoggedMealIsSuppressed() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        let ctx = SuggestionContext(now: ref, meal: .breakfast,
                                    alreadyLoggedFoodIDs: ["egg", "bread", "coffee"], calendar: cal)
        XCTAssertTrue(MealSuggester.suggestions(remembered: remembered, context: ctx).isEmpty)
    }

    func testWrongMealSectionIsFilteredOut() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        // In the dinner section, the breakfast memory must not appear.
        let ctx = SuggestionContext(now: ref, meal: .dinner, calendar: cal)
        XCTAssertTrue(MealSuggester.suggestions(remembered: remembered, context: ctx).isEmpty)
    }

    // MARK: - Explainability (never an unexplained recommendation)

    func testEverySuggestionCarriesAConcreteReason() {
        var logs: [LoggedFood] = []
        // Weekday breakfasts (Mon–Fri near the ref week) at 8 am.
        for d in [1, 2, 5, 6, 7] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: ref)!
        let s = MealSuggester.suggestions(remembered: remembered,
                                          context: SuggestionContext(now: morning, meal: .breakfast, calendar: cal)).first!
        XCTAssertFalse(s.reason.isEmpty)                       // never unexplained
        XCTAssertTrue(s.reason.contains("\(s.meal.occurrences)×"))   // concrete count
        XCTAssertTrue(s.reason.contains("weekday mornings"))         // learned timing
    }

    func testReasonReflectsWeekendAndTimeOfDay() {
        // A weekend evening dinner.
        func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))! }
        let weekend = [(2026,2,21,19), (2026,2,22,19), (2026,2,28,19)]   // Sat/Sun/Sat
        let logs = weekend.flatMap { w in
            [("steak","Steak"), ("potato","Potato")].map {
                LoggedFood(day: cal.startOfDay(for: at(w.0,w.1,w.2,w.3)), loggedAt: at(w.0,w.1,w.2,w.3),
                           meal: MealType.dinner.rawValue, foodID: $0.0, foodName: $0.1, amount: 1, unitID: "serving", unitLabel: "serving")
            }
        }
        let m = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal).first!
        let reason = MealSuggester.reason(for: m, now: ref, calendar: cal)
        XCTAssertTrue(reason.contains("weekend evenings"))
    }

    func testTimeOfDayRanksTheRightMealFirst() {
        var logs: [LoggedFood] = []
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 8, meal: .breakfast, foods: breakfast, from: ref) }
        for d in [1, 2, 3, 4, 5] { logs += log(d, hour: 19, meal: .dinner, foods: [("salmon", "Salmon"), ("veg", "Veg")], from: ref) }
        let remembered = MealMemory.rememberedMeals(from: logs, now: ref, calendar: cal)
        // At 8 am with no section context, breakfast should outrank dinner.
        let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: ref)!
        let sug = MealSuggester.suggestions(remembered: remembered, context: SuggestionContext(now: morning, meal: nil, calendar: cal))
        XCTAssertEqual(sug.first?.meal.meal, MealType.breakfast.rawValue)
    }
}
