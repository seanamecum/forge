import SwiftUI

/// The command-center centerpiece: one card that tells the user exactly what to
/// do today and why. Sits at the very top of the dashboard.
struct TodaysDirectiveCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let directive = app.dailyDirective
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold)
                        Text("TODAY'S DIRECTIVE")
                            .font(Theme.eyebrow())
                            .kerning(2.2)
                            .foregroundStyle(Theme.gold)
                    }
                    Spacer()
                    Chip(text: directive.workoutName, tone: .neutral)
                }

                Text(directive.headline)
                    .font(Theme.display(24))
                    .foregroundStyle(directive.tone.color)
                    .fixedSize(horizontal: false, vertical: true)

                Text(directive.rationale)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.creamDim)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(Theme.hairline)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PRIORITY")
                            .font(.system(size: 8.5, weight: .semibold))
                            .kerning(1.4)
                            .foregroundStyle(Theme.muted)
                        Text(directive.priorityAction)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.cream)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's directive. \(directive.headline) \(directive.rationale) Priority: \(directive.priorityAction)")
    }
}
