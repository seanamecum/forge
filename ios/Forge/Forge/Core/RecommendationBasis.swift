import Foundation

/// The transparency contract every calculated recommendation exposes: what fed it,
/// what was missing, how confident it is, when it was computed, and the safe
/// fallback taken when data was absent. A charter requirement — Forge never shows
/// an opaque number it can't explain.
struct RecommendationBasis {
    enum Confidence: String {
        case high = "High"
        case moderate = "Moderate"
        case low = "Low"
    }

    /// One-line reasoning summary (reuses the engine's own narrative).
    let summary: String
    /// The signals that fed this recommendation, with values.
    let inputsUsed: [String]
    /// Signals that would sharpen it but aren't available/live right now.
    let inputsMissing: [String]
    let confidence: Confidence
    /// When this was computed (recommendations recompute live from latest signals).
    let asOf: Date
    /// What Forge did in the absence of the missing inputs, if anything.
    let safeFallback: String?

    /// Confidence follows how live the underlying data is (see DataProvenance) and
    /// whether the athlete has logged today's check-in. Pure + tested so every
    /// recommendation rates itself the same way.
    static func confidence(provenance: DataProvenance, hasCheckIn: Bool) -> Confidence {
        switch provenance {
        case .demo:    return .low
        case .partial: return hasCheckIn ? .moderate : .low
        case .live:    return hasCheckIn ? .high : .moderate
        }
    }
}
