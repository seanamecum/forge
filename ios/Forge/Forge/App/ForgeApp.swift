import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
                .onChange(of: scenePhase) { _, phase in
                    // Fresh Health data on every return to foreground.
                    guard phase == .active, appState.healthKit.authState == .authorized else { return }
                    Task {
                        await appState.healthKit.refresh()
                        appState.ingestHealthKitSignals()
                        appState.publishWidgetSnapshot()
                    }
                }
        }
        // One shared container: views get it from the environment, services
        // reach it via PersistenceService — same store either way.
        .modelContainer(PersistenceService.container)
    }
}
