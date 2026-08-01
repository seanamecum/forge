import Foundation

/// What Forge knows about *right now*, so it can suggest the right meal at the right
/// moment ("Log your usual breakfast?" at 8 am on a weekday).
struct SuggestionContext {
    var now: Date
    /// The meal section the user is in (nil = anywhere / home screen).
    var meal: MealType?
    /// Foods already logged today for the relevant meal (drives partial-match + suppression).
    var alreadyLoggedFoodIDs: Set<String> = []
    var calendar: Calendar = .current
}

/// A proactive suggestion: log (or finish) a remembered meal with one tap.
struct MealSuggestion: Identifiable, Equatable, Sendable {
    var meal: RememberedMeal
    var score: Double                 // 0–1 confidence
    var missingItems: [MealItem]      // items not yet logged today (partial-match)
    var id: String { meal.id }

    /// True when some — but not all — of the meal is already logged.
    var isPartial: Bool { missingItems.count < meal.items.count && !missingItems.isEmpty }

    var title: String {
        isPartial ? "Finish \(meal.label)?" : "Log \(meal.label)?"
    }

    /// The items a one-tap accept would log (the missing ones for a partial, else all).
    var itemsToLog: [MealItem] { isPartial ? missingItems : meal.items }
}

/// Ranks remembered meals for the current moment. Pure + tested. Combines meal-type
/// fit, time-of-day proximity, weekday/weekend fit, frequency, and recency, and
/// filters out meals already fully logged today.
enum MealSuggester {
    /// Only surface suggestions at least this confident.
    static let minScore = 0.35

    static func suggestions(remembered: [RememberedMeal], context: SuggestionContext) -> [MealSuggestion] {
        let cal = context.calendar
        let hour = cal.component(.hour, from: context.now)
        let isWeekend = cal.isDateInWeekend(context.now)

        return remembered.compactMap { meal -> MealSuggestion? in
            // Meal-type gate: in a specific meal section, only that meal's memories.
            if let ctxMeal = context.meal, meal.meal != ctxMeal.rawValue { return nil }

            let missing = meal.items.filter { !context.alreadyLoggedFoodIDs.contains($0.foodID) }
            if missing.isEmpty { return nil }                 // already fully logged → suppress

            // Nutrition is one consumer of the unified habit-scoring engine.
            var score = 0.35 + 0.4 * HabitScore.frequency(meal.occurrences)   // base from how established it is
            score *= HabitScore.recency(lastSeen: meal.lastSeen, now: context.now,
                                        calendar: cal, freshnessDays: MealMemory.freshnessDays)
            score *= HabitScore.timeOfDay(typicalHour: meal.typicalHour, nowHour: hour,
                                          strongContext: context.meal != nil)
            score *= HabitScore.weekday(bias: meal.weekdayBias, isWeekend: isWeekend)

            guard score >= minScore else { return nil }
            return MealSuggestion(meal: meal, score: min(1, score), missingItems: missing)
        }
        .sorted { $0.score > $1.score }
    }
}

extension LoggedFood {
    /// Reduce a persisted diary entry to the meal-memory signal set.
    init(entry d: DiaryEntry) {
        self.init(day: d.day, loggedAt: d.loggedAt, meal: d.meal,
                  foodID: d.foodID, foodName: d.foodName,
                  amount: d.amount, unitID: d.unitID, unitLabel: d.unitLabel)
    }
}
