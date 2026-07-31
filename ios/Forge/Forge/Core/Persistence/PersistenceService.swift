import Foundation
import SwiftData

/// Thin helpers over SwiftData for the write paths views and services use.
/// All operations are local-first and safe offline — no network involved.
enum PersistenceService {

    static let allModels: [any PersistentModel.Type] = [
        UserRecord.self, GoalRecord.self, WorkoutRecord.self,
        NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
        ScoreRecord.self, CheckInRecord.self, WeightRecord.self,
        SupplementRecord.self, BloodworkRecord.self, DiaryEntry.self,
    ]

    /// One container for the whole app — views get it via .modelContainer,
    /// services reach it directly so user actions persist no matter where
    /// they originate. Falls back to in-memory rather than crashing.
    static let container: ModelContainer = {
        let schema = Schema([
            UserRecord.self, GoalRecord.self, WorkoutRecord.self,
            NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
            ScoreRecord.self, CheckInRecord.self, WeightRecord.self,
            SupplementRecord.self, BloodworkRecord.self, DiaryEntry.self, SyncTombstone.self,
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

    /// Erase every locally-stored Forge record + per-day UserDefaults data. Used by
    /// the explicit "delete data on this phone" action. Does NOT touch Apple Health
    /// (Forge only reads it) or the cloud account (that is a separate action).
    @MainActor
    static func deleteAllLocalData() {
        try? context.delete(model: UserRecord.self)
        try? context.delete(model: GoalRecord.self)
        try? context.delete(model: WorkoutRecord.self)
        try? context.delete(model: NutritionEntryRecord.self)
        try? context.delete(model: RecoveryRecord.self)
        try? context.delete(model: SleepRecord.self)
        try? context.delete(model: ScoreRecord.self)
        try? context.delete(model: CheckInRecord.self)
        try? context.delete(model: WeightRecord.self)
        try? context.delete(model: SupplementRecord.self)
        try? context.delete(model: BloodworkRecord.self)
        try? context.delete(model: DiaryEntry.self)
        try? context.delete(model: SyncTombstone.self)
        try? context.save()
        // Data keys only — the auth session (forge.auth.*) is cleared by the
        // separate cloud-account action, so a local wipe leaves you signed in.
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("forge.") && !key.hasPrefix("forge.auth.") {
            defaults.removeObject(forKey: key)
        }
    }

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
                SyncStamp.touch(existing)
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

    /// Data-portability export (GDPR/CCPA + App Store expectation). Fails loudly
    /// rather than handing back a silent "{}".
    enum ExportError: LocalizedError {
        case encodingFailed
        case writeFailed
        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Couldn't assemble your data export. Please try again."
            case .writeFailed:    return "Couldn't save the export file. Free up some space and try again."
            }
        }
    }

    static let exportSchemaVersion = 2

    private static func appVersion() -> String { AppInfo.versionWithBuild }

    /// Everything the athlete owns and Forge stores locally, as one versioned JSON
    /// document with stable field names, units, timezone, and ISO-8601 timestamps.
    /// Throws instead of returning an empty object so the UI can show a real error.
    @MainActor
    static func exportDocument(profile: UserProfile) throws -> Data {
        func iso(_ d: Date) -> String { d.formatted(.iso8601) }

        var doc: [String: Any] = [
            "schema_version": exportSchemaVersion,
            "app": "Forge",
            "app_version": appVersion(),
            "generated_at": iso(.now),
            "timezone": TimeZone.current.identifier,
            "units": ["mass": "lb", "energy": "kcal", "liquid": "oz", "distance": "mi"],
        ]

        // Profile + coached targets (the live, user-owned profile).
        doc["profile"] = [
            "name": profile.name, "age": profile.age, "sex": "\(profile.sex)",
            "sport": profile.sport, "fitness_level": profile.fitnessLevel.rawValue,
            "activity_level": profile.activityLevel.rawValue,
            "experience_years": profile.experienceYears,
            "height_inches": profile.heightInches, "weight_lb": profile.weightLb,
            "diet": "\(profile.diet)", "uses_imperial": profile.usesImperial,
            "primary_goal": profile.primaryGoal.rawValue,
            "goals": profile.goals.map(\.rawValue),
            "targets": ["calories": profile.calorieTarget, "protein_g": profile.proteinTarget,
                        "carbs_g": profile.carbTarget, "fat_g": profile.fatTarget,
                        "water_oz": profile.waterTargetOz],
        ] as [String: Any]

        // User-created goals.
        if let goals = try? context.fetch(FetchDescriptor<GoalRecord>(sortBy: [SortDescriptor(\.createdAt)])) {
            doc["goals_tracked"] = goals.map {
                ["title": $0.title, "unit": $0.unit, "target": $0.targetValue,
                 "current": $0.currentValue, "done": $0.done, "created_at": iso($0.createdAt),
                 "deadline": $0.deadline.map(iso) ?? NSNull()] as [String: Any]
            }
        }

        // Workouts, with per-set detail (weight/reps/rpe/completed) when present.
        if let workouts = try? context.fetch(FetchDescriptor<WorkoutRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["workouts"] = workouts.map { w -> [String: Any] in
                var row: [String: Any] = [
                    "name": w.name, "date": iso(w.date), "duration_min": w.durationMin,
                    "volume_lb": w.totalVolumeLb, "sets": w.setCount, "avg_rpe": w.avgRPE,
                    "summary": w.exerciseSummary, "saved_to_health": w.savedToHealthKit,
                ]
                if !w.exercisesJSON.isEmpty,
                   let detail = try? JSONSerialization.jsonObject(with: Data(w.exercisesJSON.utf8)) {
                    row["exercises_detail"] = detail
                }
                return row
            }
        }

        if let meals = try? context.fetch(FetchDescriptor<NutritionEntryRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["nutrition"] = meals.map {
                ["date": iso($0.date), "meal": $0.meal, "food": $0.name, "calories": $0.calories,
                 "protein_g": $0.protein, "carbs_g": $0.carbs, "fat_g": $0.fat,
                 "servings": $0.servings] as [String: Any]
            }
        }

        if let weighIns = try? context.fetch(FetchDescriptor<WeightRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["weigh_ins"] = weighIns.map { ["date": iso($0.date), "weight_lb": $0.weightLb] as [String: Any] }
        }

        if let supps = try? context.fetch(FetchDescriptor<SupplementRecord>(sortBy: [SortDescriptor(\.createdAt)])) {
            doc["supplements"] = supps.map {
                ["name": $0.name, "dose": $0.dose, "timing": $0.timing, "benefit": $0.benefit,
                 "streak": $0.streak, "last_logged": $0.lastLoggedDate.map(iso) ?? NSNull()] as [String: Any]
            }
        }
        if let labs = try? context.fetch(FetchDescriptor<BloodworkRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["bloodwork"] = labs.map {
                ["name": $0.name, "category": $0.category, "value": $0.value, "unit": $0.unit,
                 "normal_low": $0.normalLow, "normal_high": $0.normalHigh,
                 "optimal_low": $0.optimalLow, "optimal_high": $0.optimalHigh, "date": iso($0.date)] as [String: Any]
            }
        }

        // Hydration (per-day, kept in UserDefaults rather than a model).
        let waterPrefix = "forge.water."
        let hydration = UserDefaults.standard.dictionaryRepresentation()
            .filter { $0.key.hasPrefix(waterPrefix) }
            .compactMap { key, value -> [String: Any]? in
                guard let oz = value as? Double else { return nil }
                return ["date": String(key.dropFirst(waterPrefix.count)), "oz": oz]
            }
        if !hydration.isEmpty { doc["hydration"] = hydration }

        if let scores = try? context.fetch(FetchDescriptor<ScoreRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["forge_scores"] = scores.map { ["date": iso($0.date), "score": $0.score] as [String: Any] }
        }
        if let checkIns = try? context.fetch(FetchDescriptor<CheckInRecord>(sortBy: [SortDescriptor(\.date)])) {
            doc["check_ins"] = checkIns.map {
                ["date": iso($0.date), "sleep_quality": $0.sleepQuality, "soreness": $0.soreness,
                 "energy": $0.energy, "stress": $0.stress] as [String: Any]
            }
        }
        // Recovery/sleep are read live from Apple Health, not stored by Forge, so
        // they aren't in this file; the source is recorded here for honesty.
        doc["health_data_note"] = "Sleep, HRV, heart rate and activity are read live from Apple Health when connected and are not stored in this export."

        guard let data = try? JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted, .sortedKeys])
        else { throw ExportError.encodingFailed }
        return data
    }

    /// Writes the export to a temporary file for `ShareLink`, so large histories
    /// share as a file attachment instead of an in-memory string.
    @MainActor
    static func exportToTemporaryFile(profile: UserProfile) throws -> URL {
        let data = try exportDocument(profile: profile)
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("forge-export-\(stamp).json")
        do { try data.write(to: url, options: .atomic) }
        catch { throw ExportError.writeFailed }
        return url
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

    // MARK: - Daily health snapshots (real HealthKit ingestion → persist + sync)

    /// Upsert today's recovery snapshot (one row per calendar day). Marked
    /// sync-pending on every change so the cloud mirror stays current.
    @MainActor
    static func upsertRecoveryRecord(recovery: Int, hrv: Int, restingHR: Int, strain: Double,
                                     context: ModelContext) {
        let startOfDay = startOfToday()
        var d = FetchDescriptor<RecoveryRecord>(predicate: #Predicate { $0.date >= startOfDay })
        d.fetchLimit = 1
        if let existing = try? context.fetch(d).first {
            existing.recovery = recovery; existing.hrv = hrv
            existing.restingHR = restingHR; existing.strain = strain
            SyncStamp.touch(existing)
        } else {
            context.insert(RecoveryRecord(date: .now, recovery: recovery, hrv: hrv,
                                          restingHR: restingHR, strain: strain))
        }
        try? context.save()
    }

    /// Upsert today's sleep snapshot (one row per calendar day).
    @MainActor
    static func upsertSleepRecord(hours: Double, deepHours: Double, remHours: Double, score: Int,
                                  context: ModelContext) {
        let startOfDay = startOfToday()
        var d = FetchDescriptor<SleepRecord>(predicate: #Predicate { $0.date >= startOfDay })
        d.fetchLimit = 1
        if let existing = try? context.fetch(d).first {
            existing.hours = hours; existing.deepHours = deepHours
            existing.remHours = remHours; existing.score = score
            SyncStamp.touch(existing)
        } else {
            context.insert(SleepRecord(date: .now, hours: hours, deepHours: deepHours,
                                       remHours: remHours, score: score))
        }
        try? context.save()
    }

    /// The athlete's real recovery history (oldest→newest), for their own trend
    /// charts. Real accounts only; demo keeps MockData trends.
    @MainActor
    static func loadRecoveryHistory(days: Int = 30) -> [RecoveryRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: startOfToday()) ?? .distantPast
        let d = FetchDescriptor<RecoveryRecord>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    @MainActor
    static func loadSleepHistory(days: Int = 30) -> [SleepRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: startOfToday()) ?? .distantPast
        let d = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    @MainActor
    static func loadScoreHistory(days: Int = 30) -> [ScoreRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: startOfToday()) ?? .distantPast
        let d = FetchDescriptor<ScoreRecord>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    // MARK: - Body weight (real weigh-in history)

    static func saveWeight(_ pounds: Double, date: Date = .now, context: ModelContext) {
        context.insert(WeightRecord(date: date, weightLb: pounds))
        try? context.save()
    }

    /// The athlete's logged weigh-ins, oldest → newest.
    @MainActor
    static func loadWeights(limit: Int = 120) -> [WeightRecord] {
        var descriptor = FetchDescriptor<WeightRecord>(sortBy: [SortDescriptor(\.date)])
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Supplements (real stack + adherence)

    static func insertSupplement(_ record: SupplementRecord, context: ModelContext) {
        context.insert(record); try? context.save()
    }
    static func deleteSupplement(named name: String, context: ModelContext) {
        let d = FetchDescriptor<SupplementRecord>(predicate: #Predicate { $0.name == name })
        for r in (try? context.fetch(d)) ?? [] {
            SyncEngine.recordDeletion(kind: SupplementRecord.syncKind, syncID: r.syncID, context: context)
            context.delete(r)
        }
        try? context.save()
    }
    static func updateSupplement(named name: String, streak: Int, lastLogged: Date?, context: ModelContext) {
        let d = FetchDescriptor<SupplementRecord>(predicate: #Predicate { $0.name == name })
        if let r = (try? context.fetch(d))?.first {
            r.streak = streak; r.lastLoggedDate = lastLogged
            SyncStamp.touch(r)
            try? context.save()
        }
    }
    @MainActor
    static func loadSupplements() -> [SupplementRecord] {
        (try? context.fetch(FetchDescriptor<SupplementRecord>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
    }

    // MARK: - Bloodwork (real lab entries)

    static func insertBloodwork(_ record: BloodworkRecord, context: ModelContext) {
        context.insert(record); try? context.save()
    }
    @MainActor
    static func loadBloodwork() -> [BloodworkRecord] {
        (try? context.fetch(FetchDescriptor<BloodworkRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    // MARK: - Diary (grams-aware; the current read/write path — Phase 1.3)

    static func insertDiaryEntry(_ entry: DiaryEntry, context: ModelContext) {
        context.insert(entry); try? context.save()
    }

    /// Today's diary, oldest→newest by log time (for the meal timeline).
    @MainActor
    static func loadTodayDiary() -> [DiaryEntry] {
        let start = startOfToday()
        let d = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate { $0.day >= start },
            sortBy: [SortDescriptor(\.loggedAt)])
        return (try? context.fetch(d)) ?? []
    }

    /// The diary for a specific calendar day (past/future logging).
    @MainActor
    static func loadDiary(day: Date) -> [DiaryEntry] {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let d = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate { $0.day >= start && $0.day < end },
            sortBy: [SortDescriptor(\.loggedAt)])
        return (try? context.fetch(d)) ?? []
    }

    static func deleteDiaryEntry(entryID: String, context: ModelContext) {
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == entryID })
        for r in (try? context.fetch(d)) ?? [] {
            SyncEngine.recordDeletion(kind: DiaryEntry.syncKind, syncID: r.syncID, context: context)
            context.delete(r)
        }
        try? context.save()
    }

    /// Edit a logged amount in place, re-scaling nutrition (grams-accurate when a
    /// basis exists, else by ratio). Powers inline quantity editing from the diary.
    static func updateDiaryQuantity(entryID: String, newAmount: Double, context: ModelContext) {
        guard newAmount > 0 else { return }
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == entryID })
        guard let e = (try? context.fetch(d))?.first else { return }
        e.rescale(toAmount: newAmount)
        SyncStamp.touch(e)
        try? context.save()
    }

    /// Replace a logged entry's quantity wholesale (amount + unit + recomputed
    /// nutrition) from the editor. Grams-accurate when the entry has a basis.
    static func updateDiaryQuantity(entryID: String, amount: Double, unitID: String,
                                    unitLabel: String, grams: Double?, gramSource: String,
                                    consumed: NutrientVector, context: ModelContext) {
        guard amount > 0 else { return }
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == entryID })
        guard let e = (try? context.fetch(d))?.first else { return }
        e.amount = amount; e.unitID = unitID; e.unitLabel = unitLabel
        e.grams = grams; e.gramSource = gramSource
        e.consumedJSON = DiaryEntry.encode(consumed)
        SyncStamp.touch(e)
        try? context.save()
    }

    /// Move an entry to another meal (drag between meals). Sync-safe (re-marks dirty).
    static func moveDiaryEntry(entryID: String, toMeal meal: String, context: ModelContext) {
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == entryID })
        guard let e = (try? context.fetch(d))?.first, e.meal != meal else { return }
        e.meal = meal
        SyncStamp.touch(e)
        try? context.save()
    }

    /// Duplicate a logged entry (a fresh id + "now" timestamp) — "eat this again" /
    /// copy. Returns the new entry's id. The copy is its own syncable record.
    @discardableResult
    static func duplicateDiaryEntry(entryID: String, toMeal meal: String? = nil,
                                    at: Date = .now, context: ModelContext) -> String? {
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.entryID == entryID })
        guard let src = (try? context.fetch(d))?.first else { return nil }
        let newID = UUID().uuidString
        let copy = DiaryEntry(
            entryID: newID, day: Calendar.current.startOfDay(for: at), loggedAt: at,
            meal: meal ?? src.meal, foodID: src.foodID, foodName: src.foodName,
            foodBrand: src.foodBrand, foodSource: src.foodSource,
            amount: src.amount, unitID: src.unitID, unitLabel: src.unitLabel,
            grams: src.grams, gramSource: src.gramSource,
            consumedJSON: src.consumedJSON, per100gJSON: src.per100gJSON)
        context.insert(copy); try? context.save()
        return newID
    }

    // MARK: - Legacy nutrition migration → diary

    private static let diaryMigrationKey = "forge.diaryMigrated.v1"

    /// One-time (per device) migration of legacy `NutritionEntryRecord`s to the
    /// grams-aware diary. Idempotent + cross-device-safe via deterministic ids.
    @MainActor
    static func migrateLegacyNutritionIfNeeded(context: ModelContext) {
        guard !isTestRun,
              !UserDefaults.standard.bool(forKey: diaryMigrationKey) else { return }
        migrateLegacyNutrition(context: context)
        UserDefaults.standard.set(true, forKey: diaryMigrationKey)
    }

    /// Convert every legacy entry to a `DiaryEntry` (deterministic id, skipping any
    /// already migrated) and remove the legacy row so it can't double-count or
    /// re-sync. The deletion tombstones propagate; the new diary rows sync forward.
    @MainActor
    @discardableResult
    static func migrateLegacyNutrition(context: ModelContext) -> Int {
        let legacy = (try? context.fetch(FetchDescriptor<NutritionEntryRecord>())) ?? []
        guard !legacy.isEmpty else { return 0 }
        let existing = Set(((try? context.fetch(FetchDescriptor<DiaryEntry>())) ?? []).map(\.entryID))
        var migrated = 0
        for rec in legacy {
            let entry = DiaryMigration.entry(from: rec)   // deterministic "legacy-…" id
            if !existing.contains(entry.entryID) {
                context.insert(entry); migrated += 1
            }
            SyncEngine.recordDeletion(kind: NutritionEntryRecord.syncKind, syncID: rec.syncID, context: context)
            context.delete(rec)
        }
        try? context.save()
        return migrated
    }

    @MainActor
    static func deleteEntry(id: UUID) {
        guard !isTestRun else { return }
        let key = id.uuidString
        let descriptor = FetchDescriptor<NutritionEntryRecord>(
            predicate: #Predicate { $0.entryID == key })
        guard let records = try? context.fetch(descriptor) else { return }
        for record in records {
            SyncEngine.recordDeletion(kind: NutritionEntryRecord.syncKind, syncID: record.syncID, context: context)
            context.delete(record)
        }
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
