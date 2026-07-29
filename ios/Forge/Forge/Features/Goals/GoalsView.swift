import SwiftUI
import SwiftData

/// Goals — fully SwiftData-backed CRUD. Create, log progress, complete, delete;
/// everything survives relaunch.
struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var app
    @Query(sort: \GoalRecord.createdAt, order: .reverse) private var goals: [GoalRecord]
    @State private var showNew = false

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Direction", title: "Goals",
                          subtitle: "Targets with numbers and dates. The Coach references these when planning your week.")

            if goals.isEmpty {
                Card {
                    EmptyStateView(
                        icon: "target",
                        title: "No goals yet",
                        message: "Set the first one — or start from a Forge suggestion below.",
                        actionLabel: "+ New Goal",
                        action: { showNew = true }
                    )
                }
                suggestionCard
            } else {
                ForEach(goals) { goal in
                    GoalCard(goal: goal)
                }
                Button("+ New Goal") { showNew = true }
                    .buttonStyle(GoldButtonStyle())
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNew) { NewGoalSheet() }
    }

    private var suggestionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Forge Suggestions")
                ForEach(GoalSuggestion.all) { s in
                    Button {
                        context.insert(GoalRecord(title: s.title, unit: s.unit,
                                                  targetValue: s.target, currentValue: s.current))
                        try? context.save()
                        app.requestSync()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.title).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Theme.cream)
                                Text(s.why).font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20)).foregroundStyle(Theme.gold)
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct GoalSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let unit: String
    let target: Double
    let current: Double
    let why: String

    static let all: [GoalSuggestion] = [
        GoalSuggestion(title: "Bench Press 225", unit: "lb", target: 225, current: 180,
                       why: "Forecast says November at your current slope."),
        GoalSuggestion(title: "Sleep 8h × 6 nights/week", unit: "nights", target: 6, current: 3,
                       why: "Your single highest-leverage recovery input."),
        GoalSuggestion(title: "Bodyweight 207", unit: "lb", target: 207, current: 200,
                       why: "Lean-bulk endpoint at +0.6 lb/week."),
        GoalSuggestion(title: "Clear knee return-to-sport", unit: "gates", target: 6, current: 3,
                       why: "3 of 6 RTS gates done — clearance is your PT's call."),
    ]
}

struct GoalCard: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var app
    let goal: GoalRecord

    var body: some View {
        Card(gold: goal.done) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(goal.done ? Theme.muted : Theme.cream)
                            .strikethrough(goal.done, color: Theme.muted)
                        if let deadline = goal.deadline {
                            Text("by \(deadline.shortLabel)")
                                .font(.system(size: 11)).foregroundStyle(Theme.faint)
                        }
                    }
                    Spacer()
                    if goal.done {
                        Chip(text: "Achieved", tone: .green)
                    } else {
                        Text("\(Int(goal.progress * 100))%")
                            .font(Theme.display(18)).foregroundStyle(Theme.goldGradient)
                    }
                }

                CapsuleBar(value: goal.currentValue, target: goal.targetValue,
                           tone: goal.done ? .green : .gold, height: 7)
                Text("\(trim(goal.currentValue)) / \(trim(goal.targetValue)) \(goal.unit)")
                    .font(.system(size: 11)).foregroundStyle(Theme.muted)

                HStack(spacing: 8) {
                    if !goal.done {
                        Button("Log progress") {
                            goal.currentValue = min(goal.targetValue, goal.currentValue + max(1, goal.targetValue * 0.05))
                            if goal.currentValue >= goal.targetValue { goal.done = true }
                            SyncStamp.touch(goal)
                            try? context.save()
                            app.requestSync()
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))

                        Button("Mark done") {
                            goal.done = true
                            goal.currentValue = goal.targetValue
                            SyncStamp.touch(goal)
                            try? context.save()
                            app.requestSync()
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))
                    }
                    Spacer()
                    Button {
                        SyncEngine.recordDeletion(kind: GoalRecord.syncKind, syncID: goal.syncID, context: context)
                        context.delete(goal)
                        try? context.save()
                        app.requestSync()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13)).foregroundStyle(Theme.rubyBright.opacity(0.7))
                    }
                }
            }
        }
    }

    private func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

struct NewGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var unit = "lb"
    @State private var target = ""
    @State private var current = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 2, to: .now) ?? .now

    var body: some View {
        AuthSheetShell(title: "New Goal", subtitle: "A number, a unit, and optionally a date.") {
            AuthField(label: "Goal", text: $title)
            HStack(spacing: 10) {
                AuthField(label: "Current", text: $current, keyboard: .decimalPad)
                AuthField(label: "Target", text: $target, keyboard: .decimalPad)
                AuthField(label: "Unit", text: $unit)
            }
            Toggle(isOn: $hasDeadline) {
                Text("Deadline").font(.system(size: 13.5)).foregroundStyle(Theme.cream)
            }
            .tint(Theme.gold)
            if hasDeadline {
                DatePicker("", selection: $deadline, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Theme.gold)
            }
            Button("Create Goal") {
                guard !title.isEmpty, let t = Double(target), t > 0 else { return }
                context.insert(GoalRecord(title: title, unit: unit, targetValue: t,
                                          currentValue: Double(current) ?? 0,
                                          deadline: hasDeadline ? deadline : nil))
                try? context.save()
                app.requestSync()
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(title.isEmpty || Double(target) == nil)
        }
    }
}
