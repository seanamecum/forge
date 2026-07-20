import Foundation

/// Consecutive-day streak over a set of *action* dates (workouts + check-ins,
/// via PersistenceService.activeDays) — days the athlete did the work, not days
/// they opened the app. Pure, timezone-normalized, and tested.
enum StreakEngine {
    /// Days ending today (or yesterday — today isn't over) that form an
    /// unbroken run. Dates may arrive unordered or duplicated.
    static func streak(days: [Date], today: Date = .now, calendar: Calendar = .current) -> Int {
        let uniqueDays = Set(days.map { calendar.startOfDay(for: $0) })
        guard !uniqueDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: today)
        // A streak survives until a full day is missed: if today has no
        // entry yet, start counting from yesterday.
        if !uniqueDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  uniqueDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while uniqueDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
