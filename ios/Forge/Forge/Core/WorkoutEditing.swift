import Foundation

/// Pure, tested in-session edit operations on the live exercise list — remove,
/// reorder, and set deletion. Kept out of the view so the logger's editing is
/// verifiable and can't silently corrupt a session (which now autosaves — LC-1).
enum WorkoutEditing {

    /// Remove an exercise by id (no-op if absent).
    static func removingExercise(_ list: [LoggedExercise], id: UUID) -> [LoggedExercise] {
        list.filter { $0.id != id }
    }

    /// Move an exercise up (offset -1) or down (+1); clamped, so boundaries no-op.
    static func movingExercise(_ list: [LoggedExercise], id: UUID, by offset: Int) -> [LoggedExercise] {
        guard let i = list.firstIndex(where: { $0.id == id }) else { return list }
        let j = i + offset
        guard list.indices.contains(j) else { return list }
        var out = list
        out.swapAt(i, j)
        return out
    }

    /// Delete one set from an exercise (no-op if absent). Editing the last set is
    /// allowed — an empty exercise can then be removed.
    static func removingSet(_ exercise: LoggedExercise, setID: UUID) -> LoggedExercise {
        var out = exercise
        out.sets.removeAll { $0.id == setID }
        return out
    }
}
