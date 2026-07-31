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

            var score = 0.35 + 0.4 * frequencyScore(meal.occurrences)   // base from how established it is
            score *= recencyScore(lastSeen: meal.lastSeen, now: context.now, calendar: cal)
            score *= timeOfDayScore(typicalHour: meal.typicalHour, nowHour: hour, mealMatched: context.meal != nil)
            score *= weekdayScore(bias: meal.weekdayBias, isWeekend: isWeekend)

            guard score >= minScore else { return nil }
            return MealSuggestion(meal: meal, score: min(1, score), missingItems: missing)
        }
        .sorted { $0.score > $1.score }
    }

    // MARK: - Signals (each 0–1)

    static func frequencyScore(_ occurrences: Int) -> Double {
        min(1, log(Double(occurrences) + 1) / log(20))    // ~1.0 near 19 occurrences
    }

    static func recencyScore(lastSeen: Date, now: Date, calendar: Calendar) -> Double {
        let days = calendar.dateComponents([.day], from: lastSeen, to: now).day ?? 0
        if days <= 2 { return 1 }
        return max(0.3, 1 - Double(days) / Double(MealMemory.freshnessDays))
    }

    /// Gaussian-ish proximity to the meal's usual hour. When the user is already in a
    /// specific meal section, time matters less (the section is the strong signal).
    static func timeOfDayScore(typicalHour: Int, nowHour: Int, mealMatched: Bool) -> Double {
        let diff = min(abs(typicalHour - nowHour), 24 - abs(typicalHour - nowHour))   // wrap around midnight
        let base = max(0, 1 - Double(diff) / 6.0)          // full within the hour, ~0 by 6 h off
        return mealMatched ? (0.6 + 0.4 * base) : base     // section context floors it at 0.6
    }

    static func weekdayScore(bias: WeekdayBias, isWeekend: Bool) -> Double {
        switch bias {
        case .any: return 1
        case .weekday: return isWeekend ? 0.5 : 1
        case .weekend: return isWeekend ? 1 : 0.5
        }
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
