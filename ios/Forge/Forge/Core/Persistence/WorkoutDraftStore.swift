import Foundation

/// A serializable snapshot of an in-progress workout. It's autosaved continuously
/// so a live session survives backgrounding, navigating away, or a relaunch — the
/// fix for LC-1, where logged sets were only written at "Finish" and anything
/// before that was silently lost. Single active session; cleared on finish/discard.

struct DraftSet: Codable, Equatable {
    var weightLb: Double
    var reps: Int
    var rpe: Double?
    var rir: Int?
    var completed: Bool
    var isPR: Bool
}

struct DraftExercise: Codable, Equatable {
    var exerciseID: String
    var sets: [DraftSet]
    var restSeconds: Int
    var note: String?
}

struct WorkoutDraft: Codable, Equatable {
    var name: String
    var startedAt: Date
    var exercises: [DraftExercise]
    var savedAt: Date

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.completed).count }
    }

    /// Worth offering to resume only once a set is actually completed — seeded
    /// prefill (weights from last time) isn't progress and shouldn't nag.
    var hasProgress: Bool { completedSets > 0 }

    var totalVolumeLb: Double {
        exercises.reduce(0) { acc, ex in
            acc + ex.sets.filter(\.completed).reduce(0) { $0 + $1.weightLb * Double($1.reps) }
        }
    }

    /// Snapshot the live session.
    static func from(name: String, startedAt: Date, exercises: [LoggedExercise], savedAt: Date) -> WorkoutDraft {
        WorkoutDraft(
            name: name, startedAt: startedAt,
            exercises: exercises.map { le in
                DraftExercise(
                    exerciseID: le.exercise.id,
                    sets: le.sets.map {
                        DraftSet(weightLb: $0.weightLb, reps: $0.reps, rpe: $0.rpe,
                                 rir: $0.rir, completed: $0.completed, isPR: $0.isPR)
                    },
                    restSeconds: le.restSeconds, note: le.note)
            },
            savedAt: savedAt)
    }

    /// Rebuild the live session, resolving each exercise id through `catalog`.
    func restore(catalog: (String) -> Exercise) -> [LoggedExercise] {
        exercises.map { de in
            LoggedExercise(
                exercise: catalog(de.exerciseID),
                sets: de.sets.map {
                    WorkoutSet(weightLb: $0.weightLb, reps: $0.reps, rpe: $0.rpe,
                               rir: $0.rir, completed: $0.completed, isPR: $0.isPR)
                },
                restSeconds: de.restSeconds, note: de.note)
        }
    }

    /// A minimal plan that re-opens the logger for this draft — the logger restores
    /// the logged sets on appear, so no blocks are needed.
    func asPlan() -> GeneratedWorkout {
        GeneratedWorkout(name: name, rationale: "Resuming your in-progress session.",
                         estMinutes: 45, blocks: [])
    }
}

/// Persists the single active workout draft on-device (local only, not synced).
enum WorkoutDraftStore {
    private static let key = "forge.workout.draft.v1"

    static func save(_ draft: WorkoutDraft, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(defaults: UserDefaults = .standard) -> WorkoutDraft? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WorkoutDraft.self, from: data)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// A draft worth offering to resume (has at least one completed set).
    static func resumable(defaults: UserDefaults = .standard) -> WorkoutDraft? {
        guard let d = load(defaults: defaults), d.hasProgress else { return nil }
        return d
    }
}
