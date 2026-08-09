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

    // MARK: - Real boards (derived from logged sessions, not seeded)

    /// The athlete's PR board — the best set (by estimated 1RM) for every lift ever
    /// logged, most recent record first. Real dates, no fabricated entries.
    static func personalRecords(from history: [Workout]) -> [PersonalRecord] {
        struct Best { var e1rm: Double; var weight: Double; var reps: Int; var date: Date }
        var best: [String: Best] = [:]
        for workout in history {
            for logged in workout.exercises {
                for set in logged.sets where set.completed && set.reps > 0 && set.weightLb > 0 {
                    let e = set.estimatedOneRepMax
                    let name = logged.exercise.name
                    if let cur = best[name], cur.e1rm >= e { continue }
                    best[name] = Best(e1rm: e, weight: set.weightLb, reps: set.reps, date: workout.date)
                }
            }
        }
        return best
            .sorted { $0.value.date > $1.value.date }   // freshest PR on top
            .map { name, b in
                PersonalRecord(exerciseName: name, weightLb: b.weight, reps: b.reps,
                               date: b.date.formatted(.dateTime.month(.abbreviated).day()))
            }
    }

    /// The canonical volume-board groups, in display order, with their effective
    /// hypertrophy ranges (sets/week).
    static let muscleGroupOrder = ["Chest", "Back", "Shoulders", "Arms", "Quads", "Hamstrings", "Glutes", "Core"]
    static let optimalRange: [String: (low: Int, high: Int)] = [
        "Chest": (10, 18), "Back": (12, 20), "Shoulders": (10, 18), "Arms": (6, 14),
        "Quads": (10, 18), "Hamstrings": (8, 14), "Glutes": (8, 16), "Core": (6, 12),
    ]

    /// Map a catalog's fine-grained primary muscle to a board group (nil = not a
    /// resistance group we chart, e.g. "Cardiovascular").
    static func muscleGroup(for primary: String) -> String? {
        switch primary {
        case "Chest": return "Chest"
        case "Lats", "Mid Back", "Upper Back", "Traps", "Erectors": return "Back"
        case "Front Delts", "Side Delts", "Rear Delts", "Delts", "Shoulders": return "Shoulders"
        case "Biceps", "Triceps", "Forearms", "Arms": return "Arms"
        case "Quads": return "Quads"
        case "Hamstrings": return "Hamstrings"
        case "Glutes": return "Glutes"
        case "Core", "Abs": return "Core"
        default: return nil
        }
    }

    /// Weekly completed sets per muscle group from real sessions, vs. optimal
    /// ranges — only groups actually trained in the window appear.
    static func muscleVolume(from history: [Workout], days: Int = 7, now: Date = .now) -> [MuscleVolume] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        var counts: [String: Int] = [:]
        for workout in history where workout.date >= cutoff {
            for logged in workout.exercises {
                let done = logged.sets.filter(\.completed).count
                guard done > 0 else { continue }
                let groups = Set(logged.exercise.primaryMuscles.compactMap(muscleGroup(for:)))
                for g in groups { counts[g, default: 0] += done }
            }
        }
        return muscleGroupOrder.compactMap { g in
            guard let sets = counts[g], sets > 0, let range = optimalRange[g] else { return nil }
            return MuscleVolume(muscle: g, sets: sets, optimalLow: range.low, optimalHigh: range.high)
        }
    }

    /// Average sessions per week over the recorded window.
    static func sessionsPerWeek(history: [Workout], days: Int = 28) -> Double {
        guard !history.isEmpty else { return 0 }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let recent = history.filter { $0.date >= cutoff }
        return Double(recent.count) / (Double(days) / 7.0)
    }
}
