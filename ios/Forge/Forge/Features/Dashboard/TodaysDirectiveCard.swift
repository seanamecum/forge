import SwiftUI

/// The command-center centerpiece: one card that tells the user exactly what to
/// do today, the prescribed plan to do it, and why. Sits at the very top of the
/// dashboard. This is "turn data into decisions" made literal.
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
                    Chip(text: dayLabel(directive.tone), tone: chipTone(directive.tone))
                }

                Text(directive.headline)
                    .font(Theme.display(24))
                    .foregroundStyle(directive.tone.color)
                    .fixedSize(horizontal: false, vertical: true)

                Text(directive.rationale)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.creamDim)
                    .fixedSize(horizontal: false, vertical: true)

                // The prescribed plan — concrete, checkable targets for today.
                if !directive.actions.isEmpty {
                    Divider().overlay(Theme.hairline)
                    Text("YOUR PLAN TODAY")
                        .font(.system(size: 8.5, weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    VStack(spacing: 0) {
                        ForEach(directive.actions) { action in
                            DirectiveActionRow(action: action)
                            if action.id != directive.actions.last?.id {
                                Divider().overlay(Theme.hairline.opacity(0.45))
                            }
                        }
                    }
                }

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
        .accessibilityLabel(accessibilityText(directive))
    }

    private func dayLabel(_ tone: Tone) -> String {
        switch tone {
        case .green:  return "Green Day"
        case .gold:   return "Moderate Day"
        case .ruby:   return "Recovery Day"
        case .amber:  return "Caution Day"
        default:      return "Today"
        }
    }
    private func chipTone(_ tone: Tone) -> Tone { tone == .ruby ? .ruby : .gold }

    private func accessibilityText(_ d: DailyDirective) -> String {
        let plan = d.actions.map { "\($0.label): \($0.value)" }.joined(separator: ", ")
        return "Today's directive. \(d.headline) \(d.rationale) Plan: \(plan). Priority: \(d.priorityAction)"
    }
}

/// One row of the prescribed plan — icon, label, target value.
private struct DirectiveActionRow: View {
    let action: DirectiveAction

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: action.icon)
                .font(.system(size: 12))
                .foregroundStyle(action.tone.color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(action.tone.color.opacity(0.14)))
            VStack(alignment: .leading, spacing: 1) {
                Text(action.label.uppercased())
                    .font(.system(size: 8.5, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Theme.muted)
                Text(action.value)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.cream)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
    }
}
