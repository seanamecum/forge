import SwiftUI

struct GeneratorView: View {
    @Environment(AppState.self) private var app

    @State private var goal: Goal = .buildMuscle
    @State private var minutes = 60
    @State private var equipment: Equipment = .fullGym
    @State private var injuries: Set<InjuryType> = [.knee]
    @State private var generated: GeneratedWorkout?
    @State private var thinking = false

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Train · AI Generator", title: "Build My Session",
                          subtitle: "Built from your goal, recovery \(app.recovery.today.recovery), equipment, time, and injury flags.")

            Card {
                VStack(alignment: .leading, spacing: 14) {
                    pickerSection(title: "Goal") {
                        FlowChips(options: Goal.allCases.map(\.rawValue),
                                  isSelected: { $0 == goal.rawValue },
                                  toggle: { if let g = Goal(rawValue: $0) { goal = g } })
                    }
                    pickerSection(title: "Time Available") {
                        FlowChips(options: ["30", "45", "60", "75", "90"].map { "\($0) min" },
                                  isSelected: { $0 == "\(minutes) min" },
                                  toggle: { minutes = Int($0.replacingOccurrences(of: " min", with: "")) ?? 60 })
                    }
                    pickerSection(title: "Equipment") {
                        FlowChips(options: Equipment.allCases.map(\.rawValue),
                                  isSelected: { $0 == equipment.rawValue },
                                  toggle: { if let e = Equipment(rawValue: $0) { equipment = e } })
                    }
                    pickerSection(title: "Injury Flags") {
                        FlowChips(options: InjuryType.allCases.map(\.rawValue),
                                  isSelected: { injuries.contains(InjuryType(rawValue: $0) ?? .knee) },
                                  toggle: { name in
                                      guard let t = InjuryType(rawValue: name) else { return }
                                      if injuries.contains(t) { injuries.remove(t) } else { injuries.insert(t) }
                                  })
                    }

                    HStack {
                        EyebrowLabel(text: "Live inputs", tone: .neutral)
                        Spacer()
                        Chip(text: "Recovery \(app.recovery.today.recovery)", tone: .green)
                        Chip(text: app.user.fitnessLevel.rawValue, tone: .neutral)
                    }
                }
            }

            Button(thinking ? "Building…" : "✦ Generate Workout") {
                thinking = true
                generated = nil
                Task {
                    try? await Task.sleep(for: .milliseconds(900))
                    generated = app.workouts.generate(goal: goal, minutes: minutes,
                                                      equipment: equipment,
                                                      recovery: app.recovery.today.recovery,
                                                      injuries: Array(injuries),
                                                      level: app.user.fitnessLevel)
                    thinking = false
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(thinking)

            if let plan = generated {
                GeneratedPlanCard(plan: plan)
            }
        }
        .navigationTitle("Generator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pickerSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: title)
            content()
        }
    }
}

struct GeneratedPlanCard: View {
    let plan: GeneratedWorkout

    var body: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(plan.name).font(Theme.display(20)).foregroundStyle(Theme.cream)
                    Spacer()
                    Chip(text: "~\(plan.estMinutes) min", tone: .gold)
                }
                CoachNote(text: plan.rationale)

                ForEach(plan.blocks) { block in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(block.label.uppercased())
                                .font(.system(size: 9, weight: .semibold)).kerning(1.3)
                                .foregroundStyle(Theme.gold)
                            Spacer()
                            Text(block.note).font(.system(size: 10)).foregroundStyle(Theme.faint)
                        }
                        ForEach(block.items) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Theme.cream)
                                Text(item.scheme).font(.system(size: 11)).foregroundStyle(Theme.muted)
                                Text("✦ \(item.note)").font(.system(size: 10.5)).foregroundStyle(Theme.gold.opacity(0.75))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                NavigationLink { WorkoutLoggerView(plan: plan) } label: {
                    Text("Use This Session")
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }
}
