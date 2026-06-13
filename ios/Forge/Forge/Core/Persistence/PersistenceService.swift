import Foundation
import SwiftData

/// Thin helpers over SwiftData for the write paths views use.
/// All operations are local-first and safe offline — no network involved.
enum PersistenceService {

    static let allModels: [any PersistentModel.Type] = [
        UserRecord.self, GoalRecord.self, WorkoutRecord.self,
        NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
        ScoreRecord.self, CheckInRecord.self,
    ]

    /// Upsert today's Forge Score snapshot (one record per calendar day).
    static func recordTodayScore(_ score: Int, context: ModelContext) {
        let startOfDay = Calendar.current.startOfDay(for: .now)
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
}
