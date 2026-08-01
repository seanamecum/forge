import Foundation

/// One logged food reduced to the signals meal memory needs — a pure input type so
/// the engine is testable without SwiftData. Built from a `DiaryEntry` by the thin
/// adapter below.
struct LoggedFood: Equatable, Sendable {
    var day: Date            // start-of-day
    var loggedAt: Date       // precise time (drives time-of-day learning)
    var meal: String         // MealType raw value
    var foodID: String
    var foodName: String
    var amount: Double
    var unitID: String
    var unitLabel: String
}

/// One food inside a remembered meal, with the user's typical amount+unit.
struct MealItem: Equatable, Hashable, Codable, Sendable {
    var foodID: String
    var foodName: String
    var amount: Double
    var unitID: String
    var unitLabel: String
}

// `WeekdayBias` now lives in the unified personalization core (domain-agnostic).

/// A meal Forge has learned the user eats repeatedly — "3 eggs + sourdough + coffee",
/// the post-workout shake, the usual Chipotle order. Carries how often + when it
/// recurs, so it can be suggested at the right moment with one-tap logging.
struct RememberedMeal: Identifiable, Equatable, Sendable {
    var id: String            // stable signature (the set of foods)
    var meal: String
    var items: [MealItem]
    var occurrences: Int
    var firstSeen: Date
    var lastSeen: Date
    var weekdayBias: WeekdayBias
    var typicalHour: Int

    /// "your usual breakfast", "your usual post-workout shake", etc.
    var label: String { "your usual \(meal.lowercased())" }
}

/// Detects recurring meals and frequent/recent foods from the user's own diary.
/// Pure + tested; `now`/`calendar` are injected so behavior is deterministic.
enum MealMemory {
    /// Times a meal must recur before Forge remembers it (avoids one-off noise).
    static let minOccurrences = 3
    /// A meal not seen within this window is stale and not suggested.
    static let freshnessDays = 21

    // MARK: - Recurring meals

    static func rememberedMeals(from logs: [LoggedFood], now: Date, calendar: Calendar = .current) -> [RememberedMeal] {
        // 1. Group into (day, meal) occurrences → the set of foods eaten together.
        struct Occ { var day: Date; var meal: String; var loggedAt: Date; var items: [MealItem] }
        var occByKey: [String: Occ] = [:]
        for l in logs {
            let key = "\(calendar.startOfDay(for: l.day).timeIntervalSince1970)|\(l.meal)"
            let item = MealItem(foodID: l.foodID, foodName: l.foodName, amount: l.amount,
                                unitID: l.unitID, unitLabel: l.unitLabel)
            if occByKey[key] == nil {
                occByKey[key] = Occ(day: calendar.startOfDay(for: l.day), meal: l.meal, loggedAt: l.loggedAt, items: [item])
            } else {
                occByKey[key]!.items.append(item)
                occByKey[key]!.loggedAt = min(occByKey[key]!.loggedAt, l.loggedAt)
            }
        }

        // 2. Group occurrences by food-set signature.
        func signature(_ items: [MealItem]) -> String {
            Set(items.map(\.foodID)).sorted().joined(separator: "+")
        }
        var groups: [String: [Occ]] = [:]
        for occ in occByKey.values where !occ.items.isEmpty {
            groups["\(occ.meal)|\(signature(occ.items))", default: []].append(occ)
        }

        // 3. Keep recurring, fresh signatures; summarize each.
        let cutoff = calendar.date(byAdding: .day, value: -freshnessDays, to: now) ?? .distantPast
        var out: [RememberedMeal] = []
        for (sigKey, occs) in groups where occs.count >= minOccurrences {
            // Learn the "when/how-often" via the unified habit learner.
            guard let habit = HabitScore.profile(occurrenceTimes: occs.map(\.loggedAt), now: now, calendar: calendar),
                  habit.lastSeen >= cutoff else { continue }
            // For each food in the meal, the amount+unit the user logs most often.
            let allItems = occs.flatMap(\.items)
            var byFood: [String: [MealItem]] = [:]
            for it in allItems { byFood[it.foodID, default: []].append(it) }
            let items: [MealItem] = Set(allItems.map(\.foodID)).sorted().compactMap { fid in
                let variants = byFood[fid] ?? []
                // Most common (amount, unit); ties → first seen.
                let counts = Dictionary(grouping: variants) { "\($0.amount)|\($0.unitID)" }
                return counts.max { $0.value.count < $1.value.count }?.value.first
            }

            out.append(RememberedMeal(
                id: sigKey, meal: occs[0].meal, items: items,
                occurrences: habit.occurrences, firstSeen: habit.firstSeen, lastSeen: habit.lastSeen,
                weekdayBias: habit.weekdayBias, typicalHour: habit.typicalHour))
        }
        // Most-established first.
        return out.sorted { ($0.occurrences, $0.lastSeen) > ($1.occurrences, $1.lastSeen) }
    }

    // MARK: - Frequent / recent foods

    struct FoodFrequency: Equatable, Sendable {
        var foodID: String; var foodName: String; var count: Int; var lastSeen: Date
    }

    /// Foods ranked by how often + how recently the user logs them (the
    /// "frequently eaten" list + a signal source for search ranking).
    static func frequentFoods(from logs: [LoggedFood], now: Date, calendar: Calendar = .current) -> [FoodFrequency] {
        var byID: [String: FoodFrequency] = [:]
        for l in logs {
            if var f = byID[l.foodID] {
                f.count += 1; f.lastSeen = max(f.lastSeen, l.loggedAt); byID[l.foodID] = f
            } else {
                byID[l.foodID] = FoodFrequency(foodID: l.foodID, foodName: l.foodName, count: 1, lastSeen: l.loggedAt)
            }
        }
        return byID.values.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.lastSeen > $1.lastSeen
        }
    }

    /// Distinct foods most-recently logged first (the "recents" list).
    static func recentFoods(from logs: [LoggedFood], limit: Int = 20) -> [FoodFrequency] {
        var seen = Set<String>(); var out: [FoodFrequency] = []
        for l in logs.sorted(by: { $0.loggedAt > $1.loggedAt }) where seen.insert(l.foodID).inserted {
            out.append(FoodFrequency(foodID: l.foodID, foodName: l.foodName, count: 1, lastSeen: l.loggedAt))
            if out.count >= limit { break }
        }
        return out
    }
}
