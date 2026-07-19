import Foundation

/// A single completed training session, reduced to what training-load maths needs.
/// Kept free of SwiftData/HealthKit so the engine stays pure and testable.
struct TrainingSession {
    let date: Date
    let durationMin: Int
    let avgRPE: Double
}

/// Turns completed training into a "strain" figure (0–21, a WHOOP-style scale)
/// that feeds Recovery, the Forge Score's Training Load component, and — through
/// it — the Daily Directive. This is the seam that makes logging a workout
/// actually move the intelligence layer instead of just filling a history list.
///
/// v1 is intentionally transparent and explainable: a session's load scales with
/// its **duration** and its reported **intensity (RPE)**. Heart-rate/volume-based
/// refinements can layer in later without changing callers. Not a clinical model.
enum TrainingLoadEngine {
    static let maxStrain = 21.0

    /// One session's strain. Duration in hours × intensity (from RPE, floored so any
    /// logged effort counts and capped at all-out), scaled onto the 0–21 range.
    static func sessionStrain(durationMin: Int, avgRPE: Double) -> Double {
        guard durationMin > 0 else { return 0 }
        let hours = Double(durationMin) / 60.0
        let intensity = (avgRPE / 10.0).clamped(to: 0.4...1.0)
        return (hours * intensity * 10.0).clamped(to: 0...maxStrain)
    }

    /// A day's total strain from its sessions, capped at the scale maximum.
    static func dayStrain(_ sessions: [TrainingSession]) -> Double {
        let total = sessions.reduce(0.0) {
            $0 + sessionStrain(durationMin: $1.durationMin, avgRPE: $1.avgRPE)
        }
        return min(maxStrain, total)
    }
}
