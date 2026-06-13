import SwiftUI

// Xcode canvas previews for the reusable design-system primitives.
// These need no AppState or SwiftData, so they render instantly and verify
// the brand look in isolation. Feature screens carry their own #Preview blocks
// with `.environment(AppState())` where state is required.

#Preview("Cards & Buttons") {
    ScreenScaffold {
        SectionHeader(eyebrow: "Design System", title: "Forge UI Kit",
                      subtitle: "Obsidian / gold / cream — the premium athletic language.")
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Gold Card")
                Text("Today is a controlled day.")
                    .font(Theme.display(20)).foregroundStyle(Theme.cream)
                CoachNote(text: "The coach note style — used for AI guidance throughout the app.")
            }
        }
        Card {
            VStack(alignment: .leading, spacing: 12) {
                EyebrowLabel(text: "Standard Card")
                HStack(spacing: 8) {
                    Chip(text: "Gold", tone: .gold)
                    Chip(text: "Good", tone: .green)
                    Chip(text: "Warn", tone: .amber)
                    Chip(text: "Alert", tone: .ruby)
                }
                LabeledBar(label: "Protein", valueText: "142 / 200 g", value: 142, target: 200, tone: .gold)
                LabeledBar(label: "Recovery", valueText: "78 / 100", value: 78, target: 100, tone: .green)
                Button("Primary Action") {}.buttonStyle(GoldButtonStyle())
                Button("Secondary Action") {}.buttonStyle(GhostButtonStyle())
            }
        }
    }
    .background(Theme.bg)
    .preferredColorScheme(.dark)
}

#Preview("Score Rings") {
    HStack(spacing: 16) {
        ScoreRing(value: 78, label: "Forge", size: 120)
        ScoreRing(value: 64, label: "Recovery", size: 120, tone: .green)
        ScoreRing(value: 28, label: "Risk", size: 120, tone: .ruby)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.bg)
    .preferredColorScheme(.dark)
}

#Preview("State Views") {
    ScreenScaffold {
        Card { LoadingStateView(label: "Reading Health data") }
        Card {
            EmptyStateView(icon: "target", title: "No goals yet",
                           message: "Set the first one to start tracking.",
                           actionLabel: "+ New Goal", action: {})
        }
        ErrorBanner(message: "Couldn't save workout — check your connection.", onDismiss: {})
    }
    .background(Theme.bg)
    .preferredColorScheme(.dark)
}
