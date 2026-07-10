import Foundation

/// The unified data layer. Pure logic — no I/O — so every rule here is unit-tested:
/// which device wins when two report the same metric, what happens when the
/// preferred source goes missing, and what a given stack still can't see.
///
/// Strategy note: Forge is the software layer that makes EVERY wearable more
/// useful. Device priority is about data quality per metric, never brand loyalty.
enum DataHub {

    // MARK: - Source priority

    /// Default winner order per metric when multiple connected devices report it.
    /// Ordered by measurement quality for that specific signal (e.g. WHOOP and
    /// Oura beat a wrist watch on sleep staging; the scale owns body composition).
    static func defaultPriority(for metric: MetricKind) -> [DataSource] {
        switch metric {
        case .sleep:            return [.whoop, .oura, .appleWatch, .garmin, .fitbit]
        case .hrv:              return [.whoop, .oura, .polar, .appleWatch, .garmin]
        case .recovery:         return [.whoop, .oura, .garmin]
        case .strain:           return [.whoop]
        case .trainingLoad:     return [.garmin, .polar, .whoop]
        case .heartRate:        return [.polar, .appleWatch, .garmin, .whoop, .fitbit]
        case .restingHR:        return [.whoop, .oura, .appleWatch, .garmin]
        case .steps:            return [.appleWatch, .garmin, .fitbit, .oura]
        case .calories:         return [.appleWatch, .garmin, .fitbit]
        case .workouts:         return [.appleWatch, .garmin, .polar]
        case .vo2Max:           return [.garmin, .appleWatch]
        case .respiratoryRate:  return [.whoop, .oura]
        case .temperature:      return [.oura, .whoop]
        case .weight, .bodyFat, .leanMass: return [.smartScale]
        }
    }

    // MARK: - Conflict resolution

    /// Resolve one metric from the unified stream.
    /// Rules, in order:
    ///  1. Only readings from connected sources count.
    ///  2. Duplicates from the same source collapse to the freshest reading.
    ///  3. A user-preferred source wins whenever it has data.
    ///  4. Otherwise the default priority order decides.
    ///  5. A priority-listed source with no data falls through to the next (missing-data fallback).
    static func resolve(_ metric: MetricKind,
                        readings: [MetricReading],
                        connected: Set<DataSource>,
                        preferred: DataSource? = nil) -> MetricReading? {
        let candidates = readings.filter { $0.kind == metric && connected.contains($0.source) }
        guard !candidates.isEmpty else { return nil }

        // Freshest reading per source (duplicate handling).
        var bySource: [DataSource: MetricReading] = [:]
        for r in candidates {
            if let existing = bySource[r.source], existing.ageHours <= r.ageHours { continue }
            bySource[r.source] = r
        }

        if let preferred, let winner = bySource[preferred] { return winner }

        for source in defaultPriority(for: metric) {
            if let winner = bySource[source] { return winner }
        }
        // Reading from a source not in the priority table (future integrations) — still usable.
        return bySource.values.min { $0.ageHours < $1.ageHours }
    }

    // MARK: - Coverage & gaps

    /// Which metrics a stack can and cannot see. Drives the "Missing data" card
    /// and the device recommendations.
    static func coverage(connected: Set<DataSource>) -> (covered: [MetricKind], missing: [MetricKind]) {
        let covered = MetricKind.allCases.filter { metric in
            connected.contains { $0.capabilities.contains(metric) }
        }
        let missing = MetricKind.allCases.filter { !covered.contains($0) }
        return (covered, missing)
    }

    /// The NEW metrics this device would add on top of the current stack —
    /// the honest answer to "why should I connect this?"
    static func fillsGap(_ source: DataSource, connected: Set<DataSource>) -> [MetricKind] {
        let (covered, _) = coverage(connected: connected)
        return source.capabilities.filter { !covered.contains($0) }
    }

    /// Freshness → quality band for the sync-status badges.
    static func quality(ageHours: Double?) -> DataQuality {
        guard let age = ageHours else { return .missing }
        if age < 1 { return .excellent }
        if age < 24 { return .good }
        return .stale
    }

    // MARK: - Recommended stacks

    /// The curated device stack per goal — powers the hub recommendation and the
    /// marketplace's "recommended for you" rail (future partner placements slot here).
    static func recommendedStack(for goal: Goal) -> [DataSource] {
        switch goal {
        case .injuryRecovery:        return [.whoop, .oura, .appleWatch]
        case .endurance:             return [.garmin, .appleWatch, .polar]
        case .loseFat, .buildMuscle: return [.smartScale, .appleWatch, .whoop]
        case .athletic:              return [.appleWatch, .whoop, .garmin]
        case .strength:              return [.appleWatch, .whoop, .smartScale]
        case .health:                return [.appleWatch, .smartScale]
        }
    }

    // MARK: - Multi-device narrative

    /// The cross-device sentence the coach and the hub speak — every clause names
    /// the source that measured it, so users see their stack working together.
    static func narrative(connected: Set<DataSource>,
                          hrvDeltaPct: Int,
                          sleepHours: Double,
                          loadRatio: Double,
                          volumeAdjustPct: Int) -> String {
        var clauses: [String] = []
        let hrvSource = defaultPriority(for: .hrv).first(where: connected.contains)
        let sleepSource = defaultPriority(for: .sleep).first(where: connected.contains)
        let loadSource = defaultPriority(for: .trainingLoad).first(where: connected.contains)

        if let s = hrvSource, hrvDeltaPct != 0 {
            clauses.append("\(s.displayName) HRV \(hrvDeltaPct < 0 ? "dropped" : "rose") \(abs(hrvDeltaPct))%")
        }
        if let s = loadSource, loadRatio > 1.15 {
            clauses.append("\(s.displayName) training load is up")
        }
        if let s = sleepSource, sleepHours < 7.5 {
            clauses.append("\(s.displayName) sleep was short (\(String(format: "%.1f", sleepHours))h)")
        }
        guard !clauses.isEmpty else {
            return "All connected signals are steady — today's plan runs at full prescription."
        }
        let joined: String
        switch clauses.count {
        case 1: joined = clauses[0]
        case 2: joined = clauses[0] + " and " + clauses[1]
        default: joined = clauses.dropLast().joined(separator: ", ") + ", and " + clauses.last!
        }
        if volumeAdjustPct < 0 {
            return joined + ". Today's workout has been reduced \(abs(volumeAdjustPct))%."
        }
        return joined + ". Intensity is capped until the signals recover."
    }
}
