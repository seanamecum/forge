import SwiftUI

/// The ambient intelligence surface — one calm, subtle line at the top of Home that
/// says the right thing at the right time ("Your usual breakfast?", "You're 35 g short
/// of protein"). Tap to see the "why"; dismiss to make it quiet (persisted). Never
/// more than one at a time here; never nags.
struct AmbientInsightCard: View {
    @Environment(AppState.self) private var app
    @State private var insights: [AmbientInsight] = []
    @State private var dismissedIDs: Set<String> = []
    @State private var expanded = false

    private var top: AmbientInsight? { insights.first { !dismissedIDs.contains($0.id) } }

    var body: some View {
        Group {
            if let insight = top { card(insight) }
        }
        .onAppear { insights = app.ambientInsights() }
    }

    private func card(_ insight: AmbientInsight) -> some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: expanded ? 8 : 0) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 14)).foregroundStyle(Theme.gold)
                    Text(insight.title)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button {
                        Haptics.soft()
                        app.dismissInsight(id: insight.id)
                        withAnimation(Motion.snappy) { _ = dismissedIDs.insert(insight.id) }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.muted)
                    }
                    .accessibilityLabel("Dismiss")
                }
                if expanded {
                    Text(insight.reason)
                        .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(Motion.snappy) { expanded.toggle() } }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
