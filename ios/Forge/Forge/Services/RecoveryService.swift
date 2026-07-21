import Foundation
import Observation

@Observable
final class RecoveryService {
    var today: RecoveryData = MockData.today
    var wearables: [WearableDevice] = MockData.wearables

    init() {
        // Resolve the unified stream once at startup so the snapshot honors any
        // persisted preferred-source choices from a previous launch.
        applyUnifiedSignals()
    }

    let trends: [TrendSeries] = [
        TrendSeries(name: "Recovery", unit: "/100", values: MockData.recoveryTrend),
        TrendSeries(name: "HRV", unit: "ms", values: MockData.hrvTrend),
        TrendSeries(name: "Sleep", unit: "h", values: MockData.sleepTrend),
        TrendSeries(name: "Strain", unit: "/21", values: MockData.strainTrend),
    ]

    var forgeScoreTrend: [Double] { MockData.forgeScoreTrend }

    /// Values of a named trend series (Recovery · Sleep · Strain · HRV), or empty.
    /// One accessor instead of `trends.first { $0.name == … }` scattered around.
    func series(_ name: String) -> [Double] {
        trends.first { $0.name == name }?.values ?? []
    }

    /// The athlete's strain baseline — the single source for the acute:chronic
    /// comparisons in the Directive and the workout generator.
    var strainBaseline: Double {
        let s = series("Strain")
        return s.isEmpty ? 0 : s.reduce(0, +) / Double(s.count)
    }

    var connectedCount: Int { wearables.filter(\.connected).count }

    func toggleConnection(_ device: WearableDevice) {
        guard let idx = wearables.firstIndex(where: { $0.id == device.id }) else { return }
        wearables[idx].connected.toggle()
        wearables[idx].lastSync = wearables[idx].connected ? "just now" : nil
        wearables[idx].lastSyncAgeHours = wearables[idx].connected ? 0 : nil
        // Pairing/unpairing changes who wins each metric — re-resolve immediately.
        applyUnifiedSignals()
    }

    // MARK: - Unified data layer state

    /// The connected half of the DataHub — which sources currently feed Forge.
    var connectedSources: Set<DataSource> {
        Set(wearables.filter(\.connected).map(\.source))
    }

    /// User-chosen winner per contested metric (e.g. "sleep comes from WHOOP").
    /// Persisted so the choice survives launches.
    var preferredSources: [MetricKind: DataSource] = RecoveryService.loadPreferred() {
        didSet { Self.persistPreferred(preferredSources) }
    }

    func setPreferred(_ source: DataSource?, for metric: MetricKind) {
        if let source { preferredSources[metric] = source }
        else { preferredSources.removeValue(forKey: metric) }
        applyUnifiedSignals()
    }

    // MARK: - Unified stream → today's snapshot

    /// Live values pushed in from real integrations (HealthKit today; WHOOP/Garmin
    /// OAuth later). These override the demo seeds for the same metric+source.
    private var liveOverrides: [MetricReading] = []

    /// The full unified stream: one seeded set per connected device, with live
    /// readings replacing their seeded counterparts.
    var readings: [MetricReading] {
        let seeded = wearables.filter(\.connected).flatMap { MockData.deviceReadings(for: $0.source) }
            .filter { seed in
                !liveOverrides.contains { $0.kind == seed.kind && $0.source == seed.source }
            }
        return seeded + liveOverrides
    }

    /// Metrics currently backed by a genuine live reading (not a demo seed).
    var liveMetrics: Set<MetricKind> { Set(liveOverrides.map(\.kind)) }

    /// Honest provenance of the recovery snapshot / Forge Score. `.demo` when
    /// nothing is live; `.partial` once any live signal arrives (recovery, strain,
    /// sleep-debt and readiness are still estimated, so it is never fully `.live`).
    var provenance: DataProvenance {
        if !liveMetrics.isEmpty { return .partial }
        if recoveryFromCheckIn { return .partial }   // subjective, but the user's real input
        return .demo
    }

    /// Whether today's headline recovery number was derived from live signals
    /// (vs. the demo seed). Drives the "estimate" labeling in the UI.
    private(set) var recoveryFromLiveSignals = false

    /// Whether today's recovery was derived from the morning check-in (the athlete's
    /// real signal when no wearable is connected). Mutually exclusive with live.
    private(set) var recoveryFromCheckIn = false

    /// Apply the morning check-in as the recovery signal when there is no live
    /// wearable data — so a real user's reported sleep/energy/soreness/stress
    /// actually drives their Recovery number and Forge Score. Live HRV wins.
    func applyCheckIn(_ snapshot: CheckInSnapshot?) {
        guard let ci = snapshot, !recoveryFromLiveSignals else {
            recoveryFromCheckIn = false
            return
        }
        today.recovery = CheckInEngine.recovery(ci)
        today.sleep.score = CheckInEngine.sleepScore(ci.sleepQuality)
        today.readiness = CheckInEngine.readiness(for: today.recovery)
        recoveryFromCheckIn = true
    }

    /// A live signal older than this is treated as stale — it no longer drives a
    /// "live" recovery estimate (matches DataHub's 24h "good" boundary).
    static let staleThresholdHours = 24.0

    /// Ingest a real reading (e.g. from HealthKit) and re-resolve. `ageHours` is how
    /// old the sample is — hardcoding it to 0 (the old behaviour) made a weeks-old
    /// HRV read as fresh.
    func updateReading(_ kind: MetricKind, value: Double, unit: String,
                       source: DataSource, ageHours: Double = 0) {
        liveOverrides.removeAll { $0.kind == kind && $0.source == source }
        liveOverrides.append(MetricReading(kind: kind, value: value, unit: unit,
                                           source: source, ageHours: max(0, ageHours)))
        applyUnifiedSignals()
    }

    /// Age (hours) of the live sample currently feeding a metric — nil when the
    /// value is demo-seeded rather than a genuine live reading.
    func liveAgeHours(_ kind: MetricKind) -> Double? {
        guard let winner = resolved(kind),
              liveOverrides.contains(where: { $0.kind == kind && $0.source == winner.source })
        else { return nil }
        return winner.ageHours
    }

    /// True when any live signal feeding recovery is past the stale threshold.
    var hasStaleLiveSignal: Bool {
        liveMetrics.contains { (liveAgeHours($0) ?? 0) >= Self.staleThresholdHours }
    }

    /// The winning reading for a metric under priority + preference rules.
    func resolved(_ kind: MetricKind) -> MetricReading? {
        DataHub.resolve(kind, readings: readings,
                        connected: connectedSources,
                        preferred: preferredSources[kind])
    }

    /// Push the winning readings into today's snapshot, so the Forge Score,
    /// Directive, and Coach all follow the user's source choices. Sleep score
    /// rescales with hours against the seeded calibration (7.2 h ↔ 81).
    func applyUnifiedSignals() {
        if let sleep = resolved(.sleep) {
            today.sleep.hours = sleep.value
            today.sleep.score = Int((sleep.value * (81.0 / 7.2)).rounded()).clamped(to: 0...100)
        }
        let hrvReading = resolved(.hrv)
        if let hrv = hrvReading { today.hrv = Int(hrv.value) }
        if let rhr = resolved(.restingHR) { today.restingHR = Int(rhr.value) }
        if let steps = resolved(.steps) { today.steps = Int(steps.value) }
        if let cal = resolved(.calories) { today.caloriesOut = Int(cal.value) }

        // Derive the headline recovery from the user's own signals (a disclosed
        // estimate) only when the *winning* HRV is a genuine live reading AND it's
        // fresh — so a connected user never sees the demo athlete's recovery value,
        // and a stale sample doesn't masquerade as today's. Otherwise keep the
        // seeded, demo-labeled value untouched.
        let hrvIsLive = hrvReading.map { winner in
            liveOverrides.contains { $0.kind == .hrv && $0.source == winner.source }
                && winner.ageHours < Self.staleThresholdHours
        } ?? false
        if hrvIsLive {
            today.recovery = RecoveryEstimator.recovery(
                hrv: today.hrv, hrvBaseline: today.hrvBaseline,
                restingHR: today.restingHR, sleepHours: today.sleep.hours)
            recoveryFromLiveSignals = true
            recoveryFromCheckIn = false   // objective HRV supersedes the check-in
        } else {
            recoveryFromLiveSignals = false
        }
    }

    /// The sources actually competing for a metric right now — a picker only
    /// makes sense when more than one connected device reports it.
    func contenders(for metric: MetricKind) -> [DataSource] {
        DataHub.defaultPriority(for: metric).filter { source in
            connectedSources.contains(source)
        }
    }

    /// The source currently winning a metric under the resolution rules.
    func activeSource(for metric: MetricKind) -> DataSource? {
        if let preferred = preferredSources[metric], connectedSources.contains(preferred) {
            return preferred
        }
        return contenders(for: metric).first
    }

    private static let preferredKey = "forge.datahub.preferred.v1"

    private static func loadPreferred() -> [MetricKind: DataSource] {
        guard let raw = UserDefaults.standard.dictionary(forKey: preferredKey) as? [String: String]
        else { return [:] }
        var out: [MetricKind: DataSource] = [:]
        for (k, v) in raw {
            if let metric = MetricKind(rawValue: k), let source = DataSource(rawValue: v) {
                out[metric] = source
            }
        }
        return out
    }

    private static func persistPreferred(_ prefs: [MetricKind: DataSource]) {
        let raw = Dictionary(uniqueKeysWithValues: prefs.map { ($0.key.rawValue, $0.value.rawValue) })
        UserDefaults.standard.set(raw, forKey: preferredKey)
    }
}
