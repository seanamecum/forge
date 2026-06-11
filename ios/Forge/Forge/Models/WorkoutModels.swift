import Foundation

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let category: Category
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let difficulty: FitnessLevel
    let instructions: [String]
    let commonMistakes: [String]
    let coachingTips: [String]
    let alternatives: [String]
    var contraindications: [InjuryType] = []
    var userOneRepMaxLb: Double? = nil

    enum Category: String, CaseIterable {
        case compound = "Compound"
        case isolation = "Isolation"
        case core = "Core"
        case cardio = "Cardio"
        case mobility = "Mobility"
    }
}

struct WorkoutSet: Identifiable {
    let id = UUID()
    var weightLb: Double
    var reps: Int
    var rpe: Double? = nil
    var rir: Int? = nil
    var completed = false
    var isPR = false

    /// Epley estimated 1RM.
    var estimatedOneRepMax: Double {
        guard reps > 0, weightLb > 0 else { return 0 }
        return weightLb * (1 + Double(reps) / 30)
    }
}

struct LoggedExercise: Identifiable {
    let id = UUID()
    var exercise: Exercise
    var sets: [WorkoutSet]
    var restSeconds: Int = 150
    var note: String? = nil

    var volumeLb: Double {
        sets.filter(\.completed).reduce(0) { $0 + $1.weightLb * Double($1.reps) }
    }
}

struct Workout: Identifiable {
    let id = UUID()
    var name: String
    var date: Date
    var durationMin: Int
    var exercises: [LoggedExercise]
    var avgRPE: Double
    var feel: Feel

    enum Feel: String, CaseIterable {
        case fresh = "Fresh", fine = "Fine", tired = "Tired", destroyed = "Destroyed"
    }

    var totalVolumeLb: Double {
        exercises.reduce(0) { $0 + $1.volumeLb }
    }
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weightLb: Double
    let reps: Int
    let date: String
}

struct MuscleVolume: Identifiable {
    let id = UUID()
    let muscle: String
    let sets: Int
    let optimalLow: Int
    let optimalHigh: Int

    var inOptimal: Bool { sets >= optimalLow && sets <= optimalHigh }
}

// MARK: - Generator output

struct GeneratedWorkout: Identifiable {
    let id = UUID()
    let name: String
    let rationale: String
    let estMinutes: Int
    let blocks: [GeneratedBlock]
}

struct GeneratedBlock: Identifiable {
    let id = UUID()
    let label: String
    let note: String
    let items: [GeneratedItem]
}

struct GeneratedItem: Identifiable {
    let id = UUID()
    let exerciseID: String?
    let name: String
    let scheme: String   // "4 × 8 @ 185 lb · RPE 8 · rest 2:30"
    let note: String
}

struct ProgramEnrollment: Identifiable {
    let id = UUID()
    let name: String
    let coach: String
    let week: Int
    let totalWeeks: Int
    let daysPerWeek: Int
    let focus: String
}
