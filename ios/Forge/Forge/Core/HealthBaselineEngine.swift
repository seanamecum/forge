import Foundation

/// Derives the athlete's OWN physiological baselines from their HealthKit history,
/// so a connected user's recovery is computed against their own numbers — not the
/// demo athlete's seeded 62 ms HRV baseline / 3.1 h sleep debt.
///
/// Pure + fully tested. Every function needs a minimum amount of real history and
/// returns nil below it, so the caller keeps the clearly-labeled demo value rather
/// than fabricating a baseline from one or two samples. This is a **disclosed
/// heuristic, not a clinical model.**
enum HealthBaselineEngine {
    /// HRV is noisy day to day; a stable personal baseline needs a couple of weeks.
    static let minBaselineDays = 14

    /// The athlete's resting HRV baseline (ms) from daily HRV averages. Uses the
    /// **median** so an occasional spike or a bad reading doesn't move it. Returns
    /// nil until there are at least `minDays` real daily values.
    static func hrvBaseline(fromDailyHRV samples: [Double], minDays: Int = minBaselineDays) -> Int? {
        let valid = samples.filter { $0 > 0 }
        guard valid.count >= minDays else { return nil }
        return Int(median(valid).rounded())
    }

    /// Cumulative sleep debt (h) over the most recent `window` nights: the sum of
    /// each night's shortfall against `need`. A well-slept night contributes 0 (a
    /// surplus doesn't erase another night's deficit — debt only accrues). Clamped
    /// to a sane 0…40 h. Returns nil with no real nights logged.
    static func sleepDebt(recentNights: [Double], need: Double = 8.0, window: Int = 7) -> Double? {
        let nights = recentNights.filter { $0 >= 0 }.suffix(window)
        guard !nights.isEmpty else { return nil }
        let debt = nights.reduce(0.0) { $0 + max(0, need - $1) }
        return min(40, max(0, debt))
    }

    /// The athlete's typical night length (h) — the median of recent nights — used
    /// as the sleep-need reference when the user hasn't set one. nil below `minDays`.
    static func sleepNeed(fromNights nights: [Double], minDays: Int = 7, fallback: Double = 8.0) -> Double {
        let valid = nights.filter { $0 > 0 }
        guard valid.count >= minDays else { return fallback }
        // Bound to a physiologically reasonable 6–9 h so a run of short nights
        // doesn't normalize chronic deprivation into the "need".
        return min(9, max(6, median(valid)))
    }

    // MARK: - Helpers

    static func median(_ xs: [Double]) -> Double {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        let mid = s.count / 2
        return s.count % 2 == 0 ? (s[mid - 1] + s[mid]) / 2 : s[mid]
    }
}
