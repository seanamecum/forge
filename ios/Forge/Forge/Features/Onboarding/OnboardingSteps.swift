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
            StepHeading(title: "Current weight", subtitle: "Sets your starting targets — you can update it anytime.")
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
    @Environment(AppState.self) private var app
    @Binding var selected: Set<String>
    @State private var connecting = false
    private let devices = ["Apple Watch", "iPhone only", "Smart scale (writes to Health)", "Other device that syncs to Apple Health"]

    /// Any choice other than "iPhone only" means something writes to Apple Health,
    /// so connecting now has clear value — the right moment to offer it.
    private var wantsHealth: Bool { selected.contains { $0 != "iPhone only" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeading(title: "Your health data",
                        subtitle: "Forge runs on Apple Health — anything that writes there feeds your score. Connecting is optional, and you can do it anytime.")
            ForEach(devices, id: \.self) { device in
                SelectableRow(title: device, selected: selected.contains(device)) {
                    if selected.contains(device) { selected.remove(device) } else { selected.insert(device) }
                }
            }
            if wantsHealth {
                connectRow.padding(.top, Space.xs).transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Motion.snappy, value: wantsHealth)
    }

    @ViewBuilder private var connectRow: some View {
        if app.healthKit.authState == .authorized {
            Label("Apple Health connected", systemImage: "checkmark.seal.fill")
                .font(Typography.footnote.weight(.semibold)).foregroundStyle(Theme.green)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    connecting = true
                    Haptics.tap()
                    Analytics.log(.onboardingHealthKitRequested)
                    Task {
                        await app.healthKit.connect()
                        app.ingestHealthKitSignals()
                        connecting = false
                    }
                } label: {
                    Label(connecting ? "Connecting…" : "Connect Apple Health", systemImage: "heart.fill")
                }
                .buttonStyle(GoldButtonStyle(compact: true))
                .disabled(connecting)
                Text("Optional — you can skip and connect later from the dashboard.")
                    .font(Typography.caption).foregroundStyle(Theme.faint)
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
            Text(text).font(Typography.subheadline).foregroundStyle(Theme.creamDim)
        }
    }
}

// MARK: - Welcome intro (explains Forge in under 30 seconds)

/// The first thing a new user sees. Says what Forge is, that it adapts with or
/// without a wearable, and that setup is quick — then gets out of the way.
struct WelcomeIntro: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Space.xxl)
            VStack(spacing: Space.md) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44)).foregroundStyle(Theme.goldGradient)
                Text("Forge")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.cream)
                Text("Your operating system for human performance.")
                    .font(Typography.callout).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, Space.xxl)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: Space.lg) {
                valueRow("gauge.with.dots.needle.67percent", "One score, every day",
                         "Recovery, training, sleep, and nutrition become a single Forge Score.")
                valueRow("sparkles", "Coaching that adapts",
                         "Targets adjust to your training and recovery — explained, never silent.")
                valueRow("applewatch", "Works with or without a wearable",
                         "Forge runs on your check-ins and logs. Connect Apple Health for automatic HRV, sleep, and activity — optional, anytime.")
            }
            .padding(.horizontal, Space.xxl)

            Spacer(minLength: Space.xxl)

            Button("Get Started", action: onStart)
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, Space.xxl)
            Text("Takes about a minute.")
                .font(Typography.caption).foregroundStyle(Theme.faint)
                .padding(.top, Space.md).padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func valueRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: Space.md) {
            Image(systemName: icon)
                .font(.system(size: IconSize.xl)).foregroundStyle(Theme.gold)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Typography.body.weight(.semibold)).foregroundStyle(Theme.cream)
                Text(detail).font(Typography.footnote).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }
}

// MARK: - Personalized plan (the finish — not a generic success page)

/// The last screen: the real starting targets Forge just computed from the
/// user's own inputs. Personal, honest, and framed as adaptive.
struct PlanStep: View {
    let draft: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            StepHeading(title: "Your starting plan",
                        subtitle: "Computed from what you just told us — Forge tunes it as you log.")
            Card(gold: true) {
                VStack(alignment: .leading, spacing: Space.md) {
                    planRow("flame.fill", "Daily calories", "\(draft.calorieTarget.formatted()) kcal")
                    planRow("fork.knife", "Protein", "\(draft.proteinTarget) g")
                    planRow("drop.fill", "Water", "\(draft.waterTargetOz) oz")
                    if let goal = draft.goals.first {
                        planRow(goal.icon, "Primary goal", goal.rawValue)
                    }
                }
            }
            Text("These adapt to your training, recovery, and weight trend — never silently.")
                .font(Typography.footnote).foregroundStyle(Theme.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: Space.md) {
            Image(systemName: icon)
                .font(.system(size: IconSize.md)).foregroundStyle(Theme.gold).frame(width: 26)
            Text(label).font(Typography.body).foregroundStyle(Theme.creamDim)
            Spacer()
            Text(value).font(Typography.body.weight(.semibold)).foregroundStyle(Theme.cream).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
