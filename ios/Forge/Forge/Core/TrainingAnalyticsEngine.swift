import Foundation

/// One session's best effort on a lift — the unit of strength progression.
struct LiftTrendPoint: Equatable {
    let date: Date
    let bestE1RM: Double
    let topSetRPE: Double?
}

/// A lift that has stopped moving — with the diagnosis and the fix.
struct PlateauFinding: Equatable, Identifiable {
    var id: String { exerciseName }
    let exerciseName: String
    let sessions: Int
    let bestE1RM: Double
    let avgTopRPE: Double
    let recommendation: String
}

/// Training analytics — plateau detection and weak-point analysis, pure and
/// unit-tested. The difference from a tracker's charts: these return verdicts.
enum TrainingAnalyticsEngine {

    /// Per-session best estimated 1RM for a lift, oldest → newest.
    static func liftTrend(exerciseName: String, history: [Workout]) -> [LiftTrendPoint] {
        history
            .compactMap { workout -> LiftTrendPoint? in
                guard let logged = workout.exercises.first(where: { $0.exercise.name == exerciseName })
                else { return nil }
                let done = logged.sets.filter { $0.completed && $0.reps > 0 && $0.weightLb > 0 }
                guard let best = done.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax })
                else { return nil }
                return LiftTrendPoint(date: workout.date,
                                      bestE1RM: best.estimatedOneRepMax,
                                      topSetRPE: best.rpe)
            }
            .sorted { $0.date < $1.date }
    }

    /// A lift is plateaued when its best e1RM hasn't improved ≥1.5% across the
    /// last `minSessions` sessions. The recommendation depends on WHY:
    /// grinding top sets (high RPE) → recovery-limited, back off;
    /// easy top sets → stimulus-limited, push load or volume.
    static func plateaus(history: [Workout], minSessions: Int = 3) -> [PlateauFinding] {
        // Every lift that appears in enough sessions.
        let names = Set(history.flatMap { $0.exercises.map(\.exercise.name) })
        var findings: [PlateauFinding] = []

        for name in names.sorted() {
            let trend = liftTrend(exerciseName: name, history: history)
            guard trend.count >= minSessions else { continue }
            let window = Array(trend.suffix(minSessions))
            guard let first = window.first, first.bestE1RM > 0 else { continue }
            let best = window.map(\.bestE1RM).max() ?? 0
            let improvement = (best - first.bestE1RM) / first.bestE1RM
            guard improvement < 0.015 else { continue }

            let rpes = window.compactMap(\.topSetRPE)
            let avgRPE = rpes.isEmpty ? 0 : rpes.reduce(0, +) / Double(rpes.count)
            let recommendation: String
            if avgRPE >= 8.8 {
                recommendation = "Top sets are grinding (avg RPE \(String(format: "%.1f", avgRPE))) — this stall is recovery-limited, not strength-limited. Two weeks at RPE 8 with a paused back-off set, then retest."
            } else {
                recommendation = "Top sets still have room (avg RPE \(String(format: "%.1f", avgRPE))) — the stimulus stalled, not you. Add a set or a 2.5 lb microload next session."
            }
            findings.append(PlateauFinding(
                exerciseName: name, sessions: window.count,
                bestE1RM: best, avgTopRPE: avgRPE,
                recommendation: recommendation))
        }
        return findings
    }

    /// Muscle groups training below their effective-volume floor.
    static func weakPoints(volume: [MuscleVolume]) -> [MuscleVolume] {
        volume.filter { $0.sets < $0.optimalLow }
    }

    /// Average sessions per week over the recorded window.
    static func sessionsPerWeek(history: [Workout], days: Int = 28) -> Double {
        guard !history.isEmpty else { return 0 }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let recent = history.filter { $0.date >= cutoff }
        return Double(recent.count) / (Double(days) / 7.0)
    }
}
