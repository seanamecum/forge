import Foundation

/// Which Forge feature a personalization signal belongs to — so ONE engine powers
/// every domain (nutrition today; training, recovery, sleep, hydration, supplements,
/// check-ins, rehab, habits, coaching over time) instead of separate recommenders.
enum PersonalizationDomain: String, Codable, CaseIterable, Sendable {
    case nutrition, training, recovery, sleep, hydration
    case supplements, checkin, rehab, habits, coaching
}

/// Weekday vs weekend behavior — a domain-agnostic habit dimension.
enum WeekdayBias: String, Codable, Sendable { case weekday, weekend, any }

/// A learned behavioral profile for a subject (a meal, an exercise, a supplement, a
/// habit) — computed identically from any timestamped history. This is the shared
/// shape every domain's learning produces.
struct HabitProfile: Equatable, Sendable {
    var occurrences: Int
    var firstSeen: Date
    var lastSeen: Date
    var typicalHour: Int
    var weekdayBias: WeekdayBias
    /// Recency-weighted occurrence mass (exponential decay). This — not the raw
    /// `occurrences` — drives ranking, so recent behavior dominates and stale habits
    /// fade while long-term routines still carry weight.
    var recencyWeightedCount: Double
}

/// An explainable, ranked suggestion any domain can emit — the unified output type.
/// `reason` is the transparent "why" (Forge never suggests without saying why, and
/// never fabricates). Domains may also use richer typed suggestions (e.g. nutrition's
/// `MealSuggestion`) that carry this same contract.
struct PersonalizationSuggestion: Identifiable, Equatable, Sendable {
    var id: String
    var domain: PersonalizationDomain
    var title: String
    var reason: String
    var score: Double            // 0–1 confidence
    var subjectID: String
}

/// User control + privacy contract. Personalization is on-device, per-user, and never
/// leaves the device except through the normal per-user RLS sync of the underlying
/// data. Each domain can be turned off; suggestions are always explainable and
/// dismissible. (Storage wiring lands with the surfaces that use it.)
struct PersonalizationSettings: Codable, Equatable, Sendable {
    /// Domains the user has opted OUT of (default: personalization on everywhere).
    var disabledDomains: Set<PersonalizationDomain> = []
    func isEnabled(_ domain: PersonalizationDomain) -> Bool { !disabledDomains.contains(domain) }
    static let allOn = PersonalizationSettings()
}

/// The reusable habit-scoring math — frequency × recency × time-of-day × weekday —
/// extracted from Smart Meal Memory so EVERY domain learns and scores habits
/// identically. Pure + tested; the shared heart of the unified engine.
enum HabitScore {
    static let defaultFreshnessDays = 21
    /// Half-life for recency weighting — an occurrence ~2 weeks old counts half as
    /// much as today's. Long enough to honor real routines, short enough to adapt.
    static let recencyHalfLifeDays = 14.0

    /// Summarize a subject's occurrence times into a `HabitProfile` (the generalized
    /// "when/how-often" learner). Empty history → nil.
    static func profile(occurrenceTimes times: [Date], now: Date, calendar: Calendar = .current) -> HabitProfile? {
        guard !times.isEmpty else { return nil }
        let hours = times.map { calendar.component(.hour, from: $0) }.sorted()
        let weekend = times.filter { calendar.isDateInWeekend($0) }.count
        let frac = Double(weekend) / Double(times.count)
        let bias: WeekdayBias = frac >= 0.75 ? .weekend : (frac <= 0.25 ? .weekday : .any)
        // Exponential decay by age so recent behavior outweighs old (adaptive, not sticky).
        let lambda = log(2) / recencyHalfLifeDays
        let weighted = times.reduce(0.0) { acc, t in
            let ageDays = max(0, now.timeIntervalSince(t) / 86_400)
            return acc + exp(-lambda * ageDays)
        }
        return HabitProfile(occurrences: times.count,
                            firstSeen: times.min()!, lastSeen: times.max()!,
                            typicalHour: hours[hours.count / 2], weekdayBias: bias,
                            recencyWeightedCount: weighted)
    }

    /// How established a habit is (0–1) from raw count — log-scaled. Prefer
    /// `weightedFrequency` for ranking (recency-aware); this is kept for display.
    static func frequency(_ occurrences: Int) -> Double {
        min(1, log(Double(max(0, occurrences)) + 1) / log(20))   // ~1.0 near 19
    }

    /// How established a habit is from its recency-weighted mass (0–1) — the ranking
    /// signal. A run of recent logs scores high; the same count spread long ago fades.
    static func weightedFrequency(_ weightedCount: Double) -> Double {
        min(1, log(max(0, weightedCount) + 1) / log(20))
    }

    /// How recent (0–1). Fresh within 2 days; fades to 0.3 by the freshness window.
    static func recency(lastSeen: Date, now: Date, calendar: Calendar = .current,
                        freshnessDays: Int = defaultFreshnessDays) -> Double {
        let days = calendar.dateComponents([.day], from: lastSeen, to: now).day ?? 0
        if days <= 2 { return 1 }
        return max(0.3, 1 - Double(days) / Double(freshnessDays))
    }

    /// Proximity (0–1) to the habit's usual hour, wrapping around midnight. When the
    /// user is already in a strong context (e.g. the matching meal section) time
    /// matters less, so it's floored.
    static func timeOfDay(typicalHour: Int, nowHour: Int, strongContext: Bool) -> Double {
        let raw = abs(typicalHour - nowHour)
        let diff = min(raw, 24 - raw)
        let base = max(0, 1 - Double(diff) / 6.0)
        return strongContext ? (0.6 + 0.4 * base) : base
    }

    /// Weekday/weekend fit (0–1).
    static func weekday(bias: WeekdayBias, isWeekend: Bool) -> Double {
        switch bias {
        case .any: return 1
        case .weekday: return isWeekend ? 0.5 : 1
        case .weekend: return isWeekend ? 1 : 0.5
        }
    }
}
