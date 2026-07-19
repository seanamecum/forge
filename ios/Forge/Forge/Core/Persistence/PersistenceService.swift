import Foundation
import SwiftData

/// Thin helpers over SwiftData for the write paths views and services use.
/// All operations are local-first and safe offline — no network involved.
enum PersistenceService {

    static let allModels: [any PersistentModel.Type] = [
        UserRecord.self, GoalRecord.self, WorkoutRecord.self,
        NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
        ScoreRecord.self, CheckInRecord.self,
    ]

    /// One container for the whole app — views get it via .modelContainer,
    /// services reach it directly so user actions persist no matter where
    /// they originate. Falls back to in-memory rather than crashing.
    static let container: ModelContainer = {
        let schema = Schema([
            UserRecord.self, GoalRecord.self, WorkoutRecord.self,
            NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
            ScoreRecord.self, CheckInRecord.self,
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }()

    /// Unit tests exercise services directly; they must not write into the
    /// simulator's real store or leak state between runs.
    static let isTestRun = NSClassFromString("XCTestCase") != nil

    @MainActor
    static var context: ModelContext { container.mainContext }

    private static func startOfToday() -> Date {
        Calendar.current.startOfDay(for: .now)
    }

    // MARK: - Forge Score

    /// Upsert today's Forge Score snapshot (one record per calendar day).
    static func recordTodayScore(_ score: Int, context: ModelContext) {
        let startOfDay = startOfToday()
        var descriptor = FetchDescriptor<ScoreRecord>(
            predicate: #Predicate { $0.date >= startOfDay }
        )
        descriptor.fetchLimit = 1
        do {
            if let existing = try context.fetch(descriptor).first {
                existing.score = score
            } else {
                context.insert(ScoreRecord(date: .now, score: score))
            }
            try context.save()
        } catch {
            // Persistence is best-effort for the score snapshot; never block the UI.
        }
    }

    /// Every day the app snapshotted a score. Kept for score-history/trends only —
    /// it is NOT the streak source (a snapshot is written just for opening the
    /// app, which would reward showing up rather than doing the work).
    @MainActor
    static func scoreDays() -> [Date] {
        let descriptor = FetchDescriptor<ScoreRecord>(sortBy: [SortDescriptor(\.date)])
        return ((try? context.fetch(descriptor)) ?? []).map(\.date)
    }

    /// Days the athlete took an *intentional* action — completed a workout or
    /// logged a daily check-in. This is the honest streak source: it counts
    /// doing the work, not opening the app.
    @MainActor
    static func activeDays() -> [Date] {
        let workouts = (try? context.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<CheckInRecord>())) ?? []
        return workouts.map(\.date) + checkIns.map(\.date)
    }

    /// Everything the athlete owns, as a shareable JSON document.
    @MainActor
    static func exportJSON() -> String {
        func iso(_ d: Date) -> String { d.formatted(.iso8601) }
        var export: [String: Any] = ["exported_at": iso(.now), "app": "Forge"]
        if let workouts = try? context.fetch(FetchDescriptor<WorkoutRecord>(sortBy: [SortDescriptor(\.date)])) {
            export["workouts"] = workouts.map {
                ["name": $0.name, "date": iso($0.date), "duration_min": $0.durationMin,
                 "volume_lb": $0.totalVolumeLb, "sets": $0.setCount, "avg_rpe": $0.avgRPE,
                 "summary": $0.exerciseSummary] as [String: Any]
            }
        }
        if let meals = try? context.fetch(FetchDescriptor<NutritionEntryRecord>(sortBy: [SortDescriptor(\.date)])) {
            export["nutrition"] = meals.map {
                ["date": iso($0.date), "meal": $0.meal, "food": $0.name, "calories": $0.calories,
                 "protein_g": $0.protein, "carbs_g": $0.carbs, "fat_g": $0.fat,
                 "servings": $0.servings] as [String: Any]
            }
        }
        if let scores = try? context.fetch(FetchDescriptor<ScoreRecord>(sortBy: [SortDescriptor(\.date)])) {
            export["forge_scores"] = scores.map { ["date": iso($0.date), "score": $0.score] as [String: Any] }
        }
        if let checkIns = try? context.fetch(FetchDescriptor<CheckInRecord>(sortBy: [SortDescriptor(\.date)])) {
            export["check_ins"] = checkIns.map {
                ["date": iso($0.date), "sleep_quality": $0.sleepQuality, "soreness": $0.soreness,
                 "energy": $0.energy, "stress": $0.stress] as [String: Any]
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys])
        else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Workouts

    static func saveWorkout(_ record: WorkoutRecord, context: ModelContext) {
        context.insert(record)
        try? context.save()
    }

    static func recentWorkouts(context: ModelContext, limit: Int = 10) -> [WorkoutRecord] {
        var descriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    @MainActor
    static func loadWorkouts(limit: Int = 60) -> [Workout] {
        recentWorkouts(context: context, limit: limit).map { record in
            Workout(name: record.name, date: record.date,
                    durationMin: record.durationMin,
                    exercises: decodeExercises(record.exercisesJSON),
                    avgRPE: record.avgRPE, feel: .fine)
        }
    }

    // MARK: - Workout set detail codec (pure, tested)

    // Full set detail rides along as JSON so "repeat last session", ghost
    // values, and analytics keep working across relaunches.
    private struct SetDTO: Codable {
        var w: Double; var r: Int; var rpe: Double?; var done: Bool
    }
    private struct ExerciseDTO: Codable {
        var id: String; var sets: [SetDTO]
    }

    static func encodeExercises(_ exercises: [LoggedExercise]) -> String {
        let dtos = exercises.map { logged in
            ExerciseDTO(id: logged.exercise.id,
                        sets: logged.sets.map {
                            SetDTO(w: $0.weightLb, r: $0.reps, rpe: $0.rpe, done: $0.completed)
                        })
        }
        guard let data = try? JSONEncoder().encode(dtos) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func decodeExercises(_ json: String) -> [LoggedExercise] {
        guard !json.isEmpty,
              let dtos = try? JSONDecoder().decode([ExerciseDTO].self, from: Data(json.utf8))
        else { return [] }
        return dtos.map { dto in
            LoggedExercise(
                exercise: MockData.exercise(dto.id),
                sets: dto.sets.map {
                    WorkoutSet(weightLb: $0.w, reps: $0.r, rpe: $0.rpe, completed: $0.done)
                })
        }
    }

    // MARK: - Nutrition

    @MainActor
    static func saveEntry(_ entry: FoodEntry) {
        guard !isTestRun else { return }
        context.insert(NutritionEntryRecord(
            entryID: entry.id.uuidString, date: .now, meal: entry.meal.rawValue,
            name: entry.food.name, calories: entry.calories,
            protein: entry.protein, carbs: entry.carbs, fat: entry.fat,
            servings: entry.servings))
        try? context.save()
    }

    @MainActor
    static func deleteEntry(id: UUID) {
        guard !isTestRun else { return }
        let key = id.uuidString
        let descriptor = FetchDescriptor<NutritionEntryRecord>(
            predicate: #Predicate { $0.entryID == key })
        guard let records = try? context.fetch(descriptor) else { return }
        for record in records { context.delete(record) }
        try? context.save()
    }

    /// Today's logged food, rebuilt into the in-memory shape the UI uses.
    @MainActor
    static func loadTodayEntries() -> [FoodEntry] {
        let startOfDay = startOfToday()
        let descriptor = FetchDescriptor<NutritionEntryRecord>(
            predicate: #Predicate { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.date)])
        let records = (try? context.fetch(descriptor)) ?? []
        return records.compactMap { record in
            guard let meal = MealType(rawValue: record.meal) else { return nil }
            let food = Food(id: "logged-\(record.entryID)", name: record.name,
                            serving: "serving",
                            calories: record.servings > 0
                                ? Int((Double(record.calories) / record.servings).rounded())
                                : record.calories,
                            protein: record.servings > 0 ? record.protein / record.servings : record.protein,
                            carbs: record.servings > 0 ? record.carbs / record.servings : record.carbs,
                            fat: record.servings > 0 ? record.fat / record.servings : record.fat)
            return FoodEntry(id: UUID(uuidString: record.entryID) ?? UUID(),
                             meal: meal, food: food,
                             servings: record.servings, time: record.date.formatted(date: .omitted, time: .shortened))
        }
    }

    // MARK: - Water (per-day, UserDefaults — no model needed)

    private static func waterKey(for date: Date = .now) -> String {
        "forge.water." + date.formatted(.iso8601.year().month().day())
    }

    static func saveWater(_ oz: Double) {
        guard !isTestRun else { return }
        UserDefaults.standard.set(oz, forKey: waterKey())
    }

    static func loadTodayWater() -> Double {
        UserDefaults.standard.double(forKey: waterKey())
    }

    // MARK: - Check-in

    @MainActor
    static func loadTodayCheckIn() -> CheckInSnapshot? {
        let startOfDay = startOfToday()
        var descriptor = FetchDescriptor<CheckInRecord>(
            predicate: #Predicate { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let record = try? context.fetch(descriptor).first else { return nil }
        return CheckInSnapshot(sleepQuality: record.sleepQuality, soreness: record.soreness,
                               energy: record.energy, stress: record.stress)
    }
}
