import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// The data contract between the app and the home-screen widget.
/// The app publishes a snapshot after every dashboard refresh; the widget
/// renders it read-only. Compiled into BOTH targets — keep it dependency-free.
struct WidgetSnapshot: Codable, Equatable {
    struct Row: Codable, Equatable {
        let icon: String     // SF Symbol
        let label: String
        let value: String
    }

    let forgeScore: Int
    let headline: String
    let priority: String
    let rows: [Row]
    let generatedAt: Date

    /// Fallback content so the widget never renders empty — first install,
    /// unprovisioned app group, or before the app's first launch.
    static let placeholder = WidgetSnapshot(
        forgeScore: 78,
        headline: "Train at moderate intensity.",
        priority: "Open Forge for today's full directive.",
        rows: [
            Row(icon: "dumbbell.fill", label: "Train", value: "Today's session"),
            Row(icon: "fork.knife", label: "Protein", value: "Hit your target"),
            Row(icon: "moon.stars.fill", label: "Sleep", value: "8h target"),
        ],
        generatedAt: .now)
}

enum WidgetBridge {
    /// Shared container for app ↔ widget. Falls back to standard defaults when
    /// the app group isn't provisioned (e.g. simulator without a team) so
    /// nothing ever crashes — the widget just shows its placeholder.
    static let appGroup = "group.com.forge.performance"
    private static let key = "forge.widget.snapshot.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "ForgeDirectiveWidget")
        #endif
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
