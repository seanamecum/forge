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
    // Full set detail (JSON) so repeat/ghost-values/analytics survive relaunch.
    var exercisesJSON: String = ""

    init(name: String, date: Date, durationMin: Int, totalVolumeLb: Double,
         setCount: Int, avgRPE: Double, exerciseSummary: String,
         savedToHealthKit: Bool = false, exercisesJSON: String = "") {
        self.name = name
        self.date = date
        self.durationMin = durationMin
        self.totalVolumeLb = totalVolumeLb
        self.setCount = setCount
        self.avgRPE = avgRPE
        self.exerciseSummary = exerciseSummary
        self.savedToHealthKit = savedToHealthKit
        self.exercisesJSON = exercisesJSON
    }
}

@Model
final class NutritionEntryRecord {
    var date: Date
    var meal: String
    var name: String
    var calories: Int
    var protein: Double
    // Added for full-fidelity restore; defaults keep old stores migrating cleanly.
    var entryID: String = ""
    var carbs: Double = 0
    var fat: Double = 0
    var servings: Double = 1

    init(entryID: String = "", date: Date, meal: String, name: String,
         calories: Int, protein: Double, carbs: Double = 0, fat: Double = 0,
         servings: Double = 1) {
        self.entryID = entryID
        self.date = date
        self.meal = meal
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servings = servings
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

/// A logged body-weight measurement — the athlete's real weigh-in history, which
/// feeds the Body screen trend and the adaptive-nutrition weight-trend rule.
@Model
final class WeightRecord {
    var date: Date
    var weightLb: Double

    init(date: Date, weightLb: Double) {
        self.date = date
        self.weightLb = weightLb
    }
}

/// A supplement in the athlete's real stack, with adherence (streak + last-logged).
@Model
final class SupplementRecord {
    var name: String
    var dose: String
    var timing: String
    var benefit: String
    var streak: Int
    var lastLoggedDate: Date?
    var createdAt: Date

    init(name: String, dose: String, timing: String, benefit: String,
         streak: Int = 0, lastLoggedDate: Date? = nil, createdAt: Date = .now) {
        self.name = name; self.dose = dose; self.timing = timing; self.benefit = benefit
        self.streak = streak; self.lastLoggedDate = lastLoggedDate; self.createdAt = createdAt
    }
}

/// A bloodwork marker the athlete entered from a real lab panel. Reference ranges
/// come from the catalog; the value is the user's.
@Model
final class BloodworkRecord {
    var name: String
    var category: String        // BloodworkMarker.Category rawValue
    var value: Double
    var unit: String
    var normalLow: Double
    var normalHigh: Double
    var optimalLow: Double
    var optimalHigh: Double
    var date: Date

    init(name: String, category: String, value: Double, unit: String,
         normalLow: Double, normalHigh: Double, optimalLow: Double, optimalHigh: Double,
         date: Date = .now) {
        self.name = name; self.category = category; self.value = value; self.unit = unit
        self.normalLow = normalLow; self.normalHigh = normalHigh
        self.optimalLow = optimalLow; self.optimalHigh = optimalHigh; self.date = date
    }
}
