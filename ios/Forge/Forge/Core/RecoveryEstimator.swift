import Foundation

/// A transparent recovery estimate (0–100) computed from *live* signals, used
/// only when Forge actually has real HealthKit data — so a connected user sees a
/// number driven by their own HRV/RHR/sleep instead of the demo athlete's value.
///
/// This is a **disclosed heuristic, not a validated clinical or readiness model**:
/// HRV vs the user's own baseline (50%), resting-HR elevation (20%), and sleep
/// against an 8-hour need (30%). The UI always labels the result an "estimate" and
/// never implies medical precision. When no live data exists, callers keep the
/// clearly-labeled demo value instead of calling this.
enum RecoveryEstimator {
    static func recovery(hrv: Int, hrvBaseline: Int, restingHR: Int, sleepHours: Double) -> Int {
        let hrvScore = (Double(hrv) / Double(max(1, hrvBaseline)) * 80).clamped(to: 0...100)
        let rhrScore = Double(100 - max(0, restingHR - 50) * 3).clamped(to: 0...100)
        let sleepScore = (sleepHours / 8.0 * 100).clamped(to: 0...100)
        let blended = 0.5 * hrvScore + 0.2 * rhrScore + 0.3 * sleepScore
        return Int(blended.rounded()).clamped(to: 0...100)
    }
}

/// Where the numbers feeding the Forge Score / recovery currently come from.
/// `.live` is deliberately unreachable today — strain, sleep-debt and readiness
/// are not yet sourced from HealthKit — so a connected score is honestly `.partial`.
enum DataProvenance: Equatable {
    case demo       // no live signals — everything is seeded demo data
    case partial    // some live signals; recovery/strain still estimated
    case live       // every score input is live (not yet achievable)

    var label: String {
        switch self {
        case .demo:    return "Demo data"
        case .partial: return "Partial · estimated"
        case .live:    return "Live"
        }
    }

    var isFullyLive: Bool { self == .live }
}
