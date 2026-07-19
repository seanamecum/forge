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
}
