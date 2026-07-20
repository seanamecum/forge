import Foundation

/// Pure Forge Score maths — the weighted blend of the eight signal components and
/// the 0–100 clamp. Extracted from `AppState` so the flagship metric is directly
/// unit-tested and its weights live in exactly one place instead of inline in a
/// view-model. Behavior-preserving: `AppState` delegates to this.
enum ForgeScoreEngine {

    /// The eight weighted components (weights sum to 1.0 — the single source of
    /// truth). Values are the individual 0–100 signal scores.
    static func breakdown(sleep: Int, recovery: Int, nutrition: Int, hydration: Int,
                          trainingLoad: Int, activity: Int, stress: Int, injury: Int) -> [ScoreComponent] {
        [
            ScoreComponent(label: "Sleep",          value: sleep,        weight: 0.18),
            ScoreComponent(label: "Recovery (HRV)", value: recovery,     weight: 0.18),
            ScoreComponent(label: "Nutrition",      value: nutrition,    weight: 0.14),
            ScoreComponent(label: "Hydration",      value: hydration,    weight: 0.08),
            ScoreComponent(label: "Training Load",  value: trainingLoad, weight: 0.14),
            ScoreComponent(label: "Activity",       value: activity,     weight: 0.08),
            ScoreComponent(label: "Stress",         value: stress,       weight: 0.10),
            ScoreComponent(label: "Injury Status",  value: injury,       weight: 0.10),
        ]
    }

    /// Weighted, clamped 0–100 index from a breakdown. A single out-of-range
    /// component can never push the headline past the bounds.
    static func score(_ breakdown: [ScoreComponent]) -> Int {
        ForgeScoreBounds.clamp(breakdown.reduce(0.0) { $0 + Double($1.value) * $1.weight })
    }

    /// Plain-language "what's dragging / lifting" the score — the trust surface
    /// users read. Pure over the breakdown.
    static func narrative(_ breakdown: [ScoreComponent]) -> String {
        let sorted = breakdown.sorted { $0.value < $1.value }
        guard let lowest = sorted.first, let highest = sorted.last else { return "" }
        let second = sorted.dropFirst().first
        let drags: String
        if let second, second.value < 75 {
            drags = "\(lowest.label) (\(lowest.value)) and \(second.label) (\(second.value))"
        } else {
            drags = "\(lowest.label) (\(lowest.value))"
        }
        return "Held back by \(drags). Lifted by \(highest.label) (\(highest.value))."
    }

    /// The single component with the most recoverable points (gap × weight) — what
    /// to fix first. Pure over the breakdown.
    static func lever(_ breakdown: [ScoreComponent]) -> String {
        guard let c = breakdown.max(by: {
            Double(100 - $0.value) * $0.weight < Double(100 - $1.value) * $1.weight
        }) else { return "" }
        let gain = Int((Double(100 - c.value) * c.weight).rounded())
        guard gain > 0 else { return "Every input is dialed — hold the line." }
        return "\(c.label) is your biggest lever — up to +\(gain) points on the table."
    }
}
