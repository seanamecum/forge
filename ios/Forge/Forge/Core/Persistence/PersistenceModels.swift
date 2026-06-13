import Foundation
import SwiftData

// SwiftData records — user-generated data that must survive relaunch.
// Mock data remains the demo read-model; everything the user *does* lands here.

@Model
final class UserRecord {
    var name: String
    var weightLb: Double
    var heightInches: Double
    var primaryGoal: String
    var updatedAt: Date

    init(name: String, weightLb: Double, heightInches: Double, primaryGoal: String) {
        self.name = name
        self.weightLb = weightLb
        self.heightInches = heightInches
        self.primaryGoal = primaryGoal
        self.updatedAt = .now
    }
}

@Model
final class GoalRecord {
    var title: String
    var unit: String
    var targetValue: Double
    var currentValue: Double
    var deadline: Date?
    var done: Bool
    var createdAt: Date

    init(title: String, unit: String, targetValue: Double, currentValue: Double = 0, deadline: Date? = nil) {
        self.title = title
        self.unit = unit
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.deadline = deadline
        self.done = false
        self.createdAt = .now
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1, currentValue / targetValue)
    }
}

@Model
final class WorkoutRecord {
    var name: String
    var date: Date
    var durationMin: Int
    var totalVolumeLb: Double
    var setCount: Int
    var avgRPE: Double
    var exerciseSummary: String   // "Bench 180×5 · Row 155×8 · …"
    var savedToHealthKit: Bool

    init(name: String, date: Date, durationMin: Int, totalVolumeLb: Double,
         setCount: Int, avgRPE: Double, exerciseSummary: String, savedToHealthKit: Bool = false) {
        self.name = name
        self.date = date
        self.durationMin = durationMin
        self.totalVolumeLb = totalVolumeLb
        self.setCount = setCount
        self.avgRPE = avgRPE
        self.exerciseSummary = exerciseSummary
        self.savedToHealthKit = savedToHealthKit
    }
}

@Model
final class NutritionEntryRecord {
    var date: Date
    var meal: String
    var name: String
    var calories: Int
    var protein: Double

    init(date: Date, meal: String, name: String, calories: Int, protein: Double) {
        self.date = date
        self.meal = meal
        self.name = name
        self.calories = calories
        self.protein = protein
    }
}

@Model
final class RecoveryRecord {
    var date: Date
    var recovery: Int
    var hrv: Int
    var restingHR: Int
    var strain: Double

    init(date: Date, recovery: Int, hrv: Int, restingHR: Int, strain: Double) {
        self.date = date
        self.recovery = recovery
        self.hrv = hrv
        self.restingHR = restingHR
        self.strain = strain
    }
}

@Model
final class SleepRecord {
    var date: Date
    var hours: Double
    var deepHours: Double
    var remHours: Double
    var score: Int

    init(date: Date, hours: Double, deepHours: Double, remHours: Double, score: Int) {
        self.date = date
        self.hours = hours
        self.deepHours = deepHours
        self.remHours = remHours
        self.score = score
    }
}

@Model
final class ScoreRecord {
    var date: Date
    var score: Int

    init(date: Date, score: Int) {
        self.date = date
        self.score = score
    }
}

@Model
final class CheckInRecord {
    var date: Date
    var sleepQuality: Int   // 1–5
    var soreness: Int       // 0–10
    var energy: Int         // 1–5
    var stress: Int         // 1–5

    init(date: Date, sleepQuality: Int, soreness: Int, energy: Int, stress: Int) {
        self.date = date
        self.sleepQuality = sleepQuality
        self.soreness = soreness
        self.energy = energy
        self.stress = stress
    }
}
