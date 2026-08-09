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

/// A proactive suggestion: log (or finish) a remembered meal with one tap. Carries a
/// required, concrete `reason` — Forge never surfaces an unexplained recommendation.
struct MealSuggestion: Identifiable, Equatable, Sendable {
    var meal: RememberedMeal
    var score: Double                 // 0–1 confidence
    var missingItems: [MealItem]      // items not yet logged today (partial-match)
    var reason: String                // the explainable "why" (tap-to-see)
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

            // Nutrition is one consumer of the unified habit-scoring engine. Ranking
            // uses the recency-weighted mass so a changed routine adapts (not sticky).
            var score = 0.35 + 0.4 * HabitScore.weightedFrequency(meal.recencyWeight)
            score *= HabitScore.recency(lastSeen: meal.lastSeen, now: context.now,
                                        calendar: cal, freshnessDays: MealMemory.freshnessDays)
            score *= HabitScore.timeOfDay(typicalHour: meal.typicalHour, nowHour: hour,
                                          strongContext: context.meal != nil)
            score *= HabitScore.weekday(bias: meal.weekdayBias, isWeekend: isWeekend)

            guard score >= minScore else { return nil }
            return MealSuggestion(meal: meal, score: min(1, score), missingItems: missing,
                                  reason: reason(for: meal, now: context.now, calendar: cal))
        }
        .sorted { $0.score > $1.score }
    }

    // MARK: - Explainability (never an unexplained recommendation)

    /// A concrete, honest "why" built from the meal's own learned habit — e.g.
    /// "You've logged this 18× in the last 21 days, usually on weekday mornings."
    /// Domain-specific factors (protein gap, post-leg-day, low HRV) are appended by
    /// the callers that have those signals; this is the habit foundation.
    static func reason(for meal: RememberedMeal, now: Date, calendar: Calendar = .current) -> String {
        let elapsed = calendar.dateComponents([.day], from: meal.firstSeen, to: now).day ?? 0
        let window = max(1, min(elapsed, MealMemory.freshnessDays))
        let timing: String
        switch meal.weekdayBias {
        case .weekday: timing = "on weekday \(daypart(meal.typicalHour))s"
        case .weekend: timing = "on weekend \(daypart(meal.typicalHour))s"
        case .any:     timing = "around \(hourLabel(meal.typicalHour))"
        }
        return "You've logged this \(meal.occurrences)× in the last \(window) days, usually \(timing)."
    }

    static func daypart(_ hour: Int) -> String {
        switch hour {
        case ..<11: return "morning"
        case ..<16: return "afternoon"
        case ..<21: return "evening"
        default:    return "night"
        }
    }

    static func hourLabel(_ hour: Int) -> String {
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return "\(h12) \(hour < 12 ? "am" : "pm")"
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
