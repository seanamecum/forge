import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
        .modelContainer(for: [
            UserRecord.self, GoalRecord.self, WorkoutRecord.self,
            NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self, ScoreRecord.self,
        ])
    }
}
