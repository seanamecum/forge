import SwiftUI

struct NameStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading) {
            StepHeading(title: "What's your name?", subtitle: "Forge speaks to you directly. It should know who it's talking to.")
            AuthField(label: "Name", text: $draft.name)
        }
    }
}

struct AgeStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading) {
            StepHeading(title: "How old are you?", subtitle: "Recovery targets and heart-rate zones depend on it.")
            NumberDial(value: $draft.age, range: 13...90, unit: "years")
        }
    }
}

struct SexStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "Biological sex", subtitle: "Used for calorie, body-composition, and bloodwork baselines.")
            ForEach(Sex.allCases) { option in
                SelectableRow(title: option.rawValue, selected: draft.sex == option) {
                    draft.sex = option
                }
            }
        }
    }
}

struct HeightStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading) {
            StepHeading(title: "How tall are you?", subtitle: "Currently \(draft.heightLabel).")
            let binding = Binding<Int>(
                get: { Int(draft.heightInches) },
                set: { draft.heightInches = Double($0) }
            )
            NumberDial(value: binding, range: 48...90, unit: "inches")
        }
    }
}

struct WeightStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading) {
            StepHeading(title: "Current weight", subtitle: "Your smart scale will keep this honest later.")
            let binding = Binding<Int>(
                get: { Int(draft.weightLb) },
                set: { draft.weightLb = Double($0) }
            )
            NumberDial(value: binding, range: 70...400, unit: "lb")
        }
    }
}

struct PickerStep<Option: Identifiable & Hashable & RawRepresentable>: View where Option.RawValue == String {
    let title: String
    let subtitle: String
    let options: [Option]
    @Binding var selection: Option
    let detail: (Option) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: title, subtitle: subtitle)
            ForEach(options) { option in
                SelectableRow(title: option.rawValue, detail: detail(option),
                              selected: selection == option) {
                    selection = option
                }
            }
        }
    }
}

struct GoalStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "What are you forging?", subtitle: "Pick up to three. The first is primary.")
            ForEach(Goal.allCases) { goal in
                SelectableRow(title: goal.rawValue, icon: goal.icon,
                              selected: draft.goals.contains(goal)) {
                    if draft.goals.contains(goal) {
                        draft.goals.removeAll { $0 == goal }
                    } else if draft.goals.count < 3 {
                        draft.goals.append(goal)
                    }
                }
            }
        }
    }
}

struct ExperienceStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading) {
            StepHeading(title: "Years of training", subtitle: "Structured training, not just gym visits.")
            NumberDial(value: $draft.experienceYears, range: 0...40, unit: "years")
        }
    }
}

struct InjuryStep: View {
    @Binding var selected: Set<InjuryType>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "Anything tweaky?",
                        subtitle: "Forge blocks aggravating movements automatically and queues a rehab protocol. Skip if healthy.")
            FlowChips(options: InjuryType.allCases.map(\.rawValue),
                      isSelected: { selected.contains(InjuryType(rawValue: $0) ?? .knee) },
                      toggle: { name in
                          guard let type = InjuryType(rawValue: name) else { return }
                          if selected.contains(type) { selected.remove(type) } else { selected.insert(type) }
                      })
            DisclaimerNote()
                .padding(.top, 10)
        }
    }
}

struct EquipmentStep: View {
    @Binding var draft: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "What can you train with?", subtitle: "The generator builds around your reality.")
            ForEach(Equipment.allCases) { eq in
                SelectableRow(title: eq.rawValue, selected: draft.equipment.contains(eq)) {
                    if draft.equipment.contains(eq) {
                        draft.equipment.removeAll { $0 == eq }
                    } else {
                        draft.equipment.append(eq)
                    }
                }
            }
        }
    }
}

struct WearableStep: View {
    @Binding var selected: Set<String>
    private let devices = ["Apple Watch", "WHOOP", "Oura Ring", "Garmin", "Fitbit", "Polar", "Smart Scale"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "Connect your hardware",
                        subtitle: "Pick what you wear — pairing happens inside the app.")
            ForEach(devices, id: \.self) { device in
                SelectableRow(title: device, selected: selected.contains(device)) {
                    if selected.contains(device) { selected.remove(device) } else { selected.insert(device) }
                }
            }
        }
    }
}

struct NotificationStep: View {
    @Environment(AppState.self) private var app
    @State private var asked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeading(title: "Smart nudges",
                        subtitle: "Recovery drops, protein gaps, PT sessions due, streaks at risk — Forge tells you only what moves the needle.")

            Card(gold: true) {
                VStack(alignment: .leading, spacing: 10) {
                    NudgePreview(icon: "sparkles", text: "Increase bench to 185 today — progression intact.")
                    NudgePreview(icon: "exclamationmark.triangle.fill", text: "Magnesium low 6 days. 400 mg tonight.")
                    NudgePreview(icon: "flame.fill", text: "23-day streak. Today's session is ready.")
                }
            }

            Button(asked ? (app.notifications.permissionGranted ? "Notifications enabled ✓" : "Continue without notifications") : "Enable notifications") {
                guard !asked else { return }
                Task {
                    let granted = await app.notifications.requestPermission()
                    if granted {
                        let dir = app.dailyDirective
                        await app.notifications.setMorningDirective(
                            true, headline: dir.headline, priority: dir.priorityAction)
                    }
                    asked = true
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
    }
}

private struct NudgePreview: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(Theme.gold)
            Text(text).font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
        }
    }
}

// MARK: - Shared inputs

struct NumberDial: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(value)")
                    .font(Theme.display(64))
                    .foregroundStyle(Theme.goldGradient)
                Text(unit)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 18) {
                DialButton(symbol: "minus") { if value > range.lowerBound { value -= 1 } }
                Slider(value: Binding(get: { Double(value) },
                                      set: { value = Int($0) }),
                       in: Double(range.lowerBound)...Double(range.upperBound))
                    .tint(Theme.gold)
                DialButton(symbol: "plus") { if value < range.upperBound { value += 1 } }
            }
        }
        .padding(.vertical, 10)
    }
}

private struct DialButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.gold.opacity(0.07)))
                .overlay(Circle().stroke(Theme.gold.opacity(0.3), lineWidth: 1))
        }
    }
}

/// Wrapping chip selector.
struct FlowChips: View {
    let options: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let on = isSelected(option)
                Button { toggle(option) } label: {
                    Text(option)
                        .font(.system(size: 13, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? Theme.goldBright : Theme.creamDim)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(on ? Theme.gold.opacity(0.12) : Theme.card))
                        .overlay(Capsule().stroke(on ? Theme.gold.opacity(0.5) : Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
