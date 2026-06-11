import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(AppState.self) private var app
    @State private var query = ""
    @State private var category: Exercise.Category? = nil

    private var results: [Exercise] {
        app.workouts.exercises.filter { exercise in
            (category == nil || exercise.category == category) &&
            (query.isEmpty
             || exercise.name.localizedCaseInsensitiveContains(query)
             || exercise.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Train · Library", title: "Exercise Database",
                          subtitle: "Instructions, mistakes, coaching tips, alternatives — plus your estimated 1RM.")

            TextField("Search exercise or muscle…", text: $query)
                .font(.system(size: 14))
                .foregroundStyle(Theme.cream)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 11).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.hairline, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryPill(label: "All", selected: category == nil) { category = nil }
                    ForEach(Exercise.Category.allCases, id: \.self) { c in
                        CategoryPill(label: c.rawValue, selected: category == c) { category = c }
                    }
                }
            }

            ForEach(results) { exercise in
                NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                    ExerciseRow(exercise: exercise)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CategoryPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.goldBright : Theme.muted)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(Capsule().fill(selected ? Theme.gold.opacity(0.12) : Theme.card))
                .overlay(Capsule().stroke(selected ? Theme.gold.opacity(0.5) : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.cream)
                    Text(exercise.primaryMuscles.joined(separator: " · "))
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                    HStack(spacing: 6) {
                        Chip(text: exercise.category.rawValue)
                        Chip(text: exercise.difficulty.rawValue)
                        if !exercise.contraindications.isEmpty {
                            Chip(text: "⚠ \(exercise.contraindications.map(\.rawValue).joined(separator: ", "))", tone: .ruby)
                        }
                    }
                }
                Spacer()
                if let max = exercise.userOneRepMaxLb {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(max))").font(Theme.display(19)).foregroundStyle(Theme.goldGradient)
                        Text("e1RM lb").font(.system(size: 8.5)).foregroundStyle(Theme.faint)
                    }
                }
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Theme.faint)
            }
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 6) {
                EyebrowLabel(text: "\(exercise.category.rawValue) · \(exercise.difficulty.rawValue)")
                Text(exercise.name).font(Theme.display(28)).foregroundStyle(Theme.cream)
                if !exercise.contraindications.isEmpty {
                    Chip(text: "Avoid with: \(exercise.contraindications.map(\.rawValue).joined(separator: ", "))", tone: .ruby)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Primary muscles", value: exercise.primaryMuscles.joined(separator: ", "))
                    InfoRow(label: "Secondary", value: exercise.secondaryMuscles.isEmpty ? "—" : exercise.secondaryMuscles.joined(separator: ", "))
                    InfoRow(label: "Equipment", value: exercise.equipment.joined(separator: ", "))
                    if let max = exercise.userOneRepMaxLb {
                        InfoRow(label: "Your estimated 1RM", value: "\(Int(max)) lb", valueTone: .gold)
                    }
                }
            }

            DetailList(title: "Instructions", items: exercise.instructions, symbol: "circle.fill", tone: .gold, numbered: true)
            DetailList(title: "Coaching Tips", items: exercise.coachingTips, symbol: "sparkles", tone: .green)
            DetailList(title: "Common Mistakes", items: exercise.commonMistakes, symbol: "xmark", tone: .ruby)

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    EyebrowLabel(text: "Alternatives")
                    FlowChips(options: exercise.alternatives, isSelected: { _ in false }, toggle: { _ in })
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailList: View {
    let title: String
    let items: [String]
    let symbol: String
    let tone: Tone
    var numbered = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                EyebrowLabel(text: title, tone: tone)
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .top, spacing: 8) {
                        if numbered {
                            Text("\(i + 1).")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(tone.color.opacity(0.8))
                        } else {
                            Image(systemName: symbol)
                                .font(.system(size: 9))
                                .foregroundStyle(tone.color)
                                .padding(.top, 4)
                        }
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.creamDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
