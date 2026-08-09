import Foundation

/// A daily value in some domain series — recovery, sleep hours, strain, protein,
/// weight, a 0/1 behavior flag. The common currency the unified user model correlates
/// across domains.
struct DayValue: Equatable, Sendable {
    var day: Date            // start-of-day
    var value: Double
}

/// One weekday's outcome relative to the overall average — the answer to "Why do I
/// always feel tired on Thursdays?"
struct WeekdayInsight: Equatable, Sendable {
    var weekday: Int         // 1 = Sunday … 7 = Saturday
    var name: String
    var average: Double
    var deltaPct: Double     // vs the overall average
    var samples: Int
    var notable: Bool
}

/// How a behavior (e.g. "low-carb day", "trained legs", "took creatine") relates to
/// an outcome (recovery, sleep) — the answer to "What habit is hurting my recovery?"
struct BehaviorImpact: Equatable, Sendable {
    var onBehaviorAvg: Double
    var baselineAvg: Double
    var deltaPct: Double
    var behaviorSamples: Int
    var baselineSamples: Int
    var isMeaningful: Bool
}

/// The cross-domain analytical brain of the unified user model: finds honest,
/// explainable relationships between any domains' daily series. Pure + tested. Never
/// fabricates — below the data-sufficiency thresholds it returns nothing rather than a
/// spurious pattern. Every result is designed to carry a plain-language "why".
enum PerformanceCorrelation {
    static let minSamplesPerWeekday = 3
    static let minBehaviorSamples = 3
    static let notableDeltaPct = 5.0
    static let minPairedPoints = 8

    // MARK: - Weekday pattern ("Why Thursdays?")

    static func weekdayPattern(_ series: [DayValue], calendar: Calendar = .current) -> [WeekdayInsight] {
        guard series.count >= minSamplesPerWeekday else { return [] }
        let overall = mean(series.map(\.value))
        guard overall != 0 else { return [] }
        var byWeekday: [Int: [Double]] = [:]
        for d in series { byWeekday[calendar.component(.weekday, from: d.day), default: []].append(d.value) }

        return byWeekday.compactMap { wd, values -> WeekdayInsight? in
            guard values.count >= minSamplesPerWeekday else { return nil }
            let avg = mean(values)
            let delta = (avg - overall) / overall * 100
            return WeekdayInsight(weekday: wd, name: weekdayName(wd, calendar: calendar),
                                  average: avg, deltaPct: delta, samples: values.count,
                                  notable: abs(delta) >= notableDeltaPct)
        }
        .sorted { abs($0.deltaPct) > abs($1.deltaPct) }
    }

    // MARK: - Behavior → outcome ("What habit hurts recovery?")

    /// `behaviorDays` = start-of-day dates the behavior happened. `lagDays` shifts the
    /// outcome forward (lag 1 = "the day AFTER a low-carb day"). Compares the outcome
    /// on behavior-affected days vs all other (baseline) days.
    static func behaviorImpact(behaviorDays: Set<Date>, outcome: [DayValue], lagDays: Int = 0,
                               calendar: Calendar = .current) -> BehaviorImpact? {
        guard !behaviorDays.isEmpty, !outcome.isEmpty else { return nil }
        let behaviorStarts = Set(behaviorDays.map { calendar.startOfDay(for: $0) })
        var onBehavior: [Double] = []; var baseline: [Double] = []
        for d in outcome {
            let anchor = calendar.date(byAdding: .day, value: -lagDays, to: calendar.startOfDay(for: d.day)) ?? d.day
            if behaviorStarts.contains(anchor) { onBehavior.append(d.value) } else { baseline.append(d.value) }
        }
        guard onBehavior.count >= minBehaviorSamples, baseline.count >= minBehaviorSamples else { return nil }
        let on = mean(onBehavior), base = mean(baseline)
        guard base != 0 else { return nil }
        let delta = (on - base) / base * 100
        return BehaviorImpact(onBehaviorAvg: on, baselineAvg: base, deltaPct: delta,
                              behaviorSamples: onBehavior.count, baselineSamples: baseline.count,
                              isMeaningful: abs(delta) >= notableDeltaPct)
    }

    // MARK: - Paired correlation ("What changed before my sleep improved?")

    /// Pearson correlation of two daily series aligned by day. nil below the
    /// minimum paired-point count (no spurious correlation from a handful of days).
    static func correlation(_ a: [DayValue], _ b: [DayValue], calendar: Calendar = .current) -> Double? {
        let bByDay = Dictionary(b.map { (calendar.startOfDay(for: $0.day), $0.value) }, uniquingKeysWith: { x, _ in x })
        var xs: [Double] = []; var ys: [Double] = []
        for d in a {
            if let y = bByDay[calendar.startOfDay(for: d.day)] { xs.append(d.value); ys.append(y) }
        }
        guard xs.count >= minPairedPoints else { return nil }
        return pearson(xs, ys)
    }

    // MARK: - Math

    static func mean(_ xs: [Double]) -> Double { xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count) }

    static func pearson(_ xs: [Double], _ ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count >= 2 else { return nil }
        let mx = mean(xs), my = mean(ys)
        var num = 0.0, dx = 0.0, dy = 0.0
        for i in xs.indices {
            let a = xs[i] - mx, b = ys[i] - my
            num += a * b; dx += a * a; dy += b * b
        }
        guard dx > 0, dy > 0 else { return nil }
        return num / (dx.squareRoot() * dy.squareRoot())
    }

    /// Fixed weekday names (1 = Sunday) — a stable product voice, not locale-dependent.
    private static let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private static func weekdayName(_ wd: Int, calendar: Calendar) -> String {
        (wd >= 1 && wd <= 7) ? weekdayNames[wd - 1] : "Day \(wd)"
    }
}
