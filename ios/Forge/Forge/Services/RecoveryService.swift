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

    /// Ingest a real reading (e.g. from HealthKit) and re-resolve.
    func updateReading(_ kind: MetricKind, value: Double, unit: String, source: DataSource) {
        liveOverrides.removeAll { $0.kind == kind && $0.source == source }
        liveOverrides.append(MetricReading(kind: kind, value: value, unit: unit,
                                           source: source, ageHours: 0))
        applyUnifiedSignals()
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
        if let hrv = resolved(.hrv) { today.hrv = Int(hrv.value) }
        if let rhr = resolved(.restingHR) { today.restingHR = Int(rhr.value) }
        if let steps = resolved(.steps) { today.steps = Int(steps.value) }
        if let cal = resolved(.calories) { today.caloriesOut = Int(cal.value) }
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
