import SwiftUI
import SwiftData

/// Live session logger: sets, weight, reps, RPE/RIR, rest timer, completion, volume.
/// Finishing persists to SwiftData and (when authorized) writes to Apple Health.
struct WorkoutLoggerView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let plan: GeneratedWorkout
    @State private var logged: [LoggedExercise] = []
    @State private var startedAt = Date.now
    @State private var restRemaining = 0
    @State private var restTotal = 0
    @State private var showExercisePicker = false
    @State private var finished = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScreenScaffold {
            header
            if restRemaining > 0 { restBanner }
            ForEach($logged) { $exercise in
                ExerciseLogCard(logged: $exercise, onSetCompleted: startRest)
            }
            Button {
                showExercisePicker = true
            } label: {
                Label("Add Exercise", systemImage: "plus")
            }
            .buttonStyle(GhostButtonStyle())

            Button("Finish Workout") { finish() }
                .buttonStyle(GoldButtonStyle())
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgElevated, for: .navigationBar)
        .onAppear { seed() }
        .onReceive(timer) { _ in
            if restRemaining > 0 { restRemaining -= 1 }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                logged.append(LoggedExercise(exercise: exercise,
                                             sets: [WorkoutSet(weightLb: 0, reps: 0)]))
            }
        }
        .alert("Session saved", isPresented: $finished) {
            Button("Done") { dismiss() }
        } message: {
            Text("\(Int(totalVolume).formatted()) lb total volume · \(durationMin) min. PRs are flagged automatically.")
        }
    }

    private var header: some View {
        Card(gold: true) {
            HStack {
                StatTile(label: "Duration", value: "\(durationMin)", unit: "min")
                StatTile(label: "Volume", value: Int(totalVolume).formatted(), unit: "lb")
                StatTile(label: "Sets done", value: "\(completedSets)/\(totalSets)")
            }
        }
    }

    private var restBanner: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Theme.gold.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: restTotal > 0 ? CGFloat(restRemaining) / CGFloat(restTotal) : 0)
                        .stroke(Theme.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(restLabel).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.goldBright)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("REST").font(Theme.eyebrow(9)).kerning(2).foregroundStyle(Theme.gold)
                    Text("Next set when the ring closes").font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Button("Skip") { restRemaining = 0 }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.muted)
            }
        }
    }

    // MARK: - Logic

    private func seed() {
        guard logged.isEmpty else { return }
        for block in plan.blocks where block.label.hasPrefix("Main") || block.label.hasPrefix("Accessory") {
            for item in block.items {
                guard let id = item.exerciseID else { continue }
                let exercise = MockData.exercise(id)
                logged.append(LoggedExercise(
                    exercise: exercise,
                    sets: (0..<3).map { _ in WorkoutSet(weightLb: defaultWeight(for: exercise), reps: 0) }
                ))
            }
        }
    }

    private func defaultWeight(for exercise: Exercise) -> Double {
        guard let max = exercise.userOneRepMaxLb else { return 0 }
        return (max * 0.75 / 5).rounded() * 5
    }

    private func startRest(_ seconds: Int) {
        restTotal = seconds
        restRemaining = seconds
    }

    private var restLabel: String {
        String(format: "%d:%02d", restRemaining / 60, restRemaining % 60)
    }

    private var durationMin: Int {
        max(1, Int(Date.now.timeIntervalSince(startedAt) / 60))
    }

    private var totalVolume: Double {
        logged.reduce(0) { $0 + $1.volumeLb }
    }

    private var totalSets: Int { logged.reduce(0) { $0 + $1.sets.count } }
    private var completedSets: Int { logged.reduce(0) { $0 + $1.sets.filter(\.completed).count } }

    private func finish() {
        let completed = logged.filter { $0.sets.contains(where: \.completed) }
        let workout = Workout(name: plan.name, date: .now, durationMin: durationMin,
                              exercises: completed, avgRPE: averageRPE, feel: .fine)
        app.workouts.finish(workout)

        // Persist locally (SwiftData) — survives relaunch, works offline.
        let summary = completed
            .map { "\($0.exercise.name) ×\($0.sets.filter(\.completed).count)" }
            .joined(separator: " · ")
        let record = WorkoutRecord(name: plan.name, date: .now, durationMin: durationMin,
                                   totalVolumeLb: totalVolume, setCount: completedSets,
                                   avgRPE: averageRPE, exerciseSummary: summary)
        PersistenceService.saveWorkout(record, context: modelContext)

        // Mirror to Apple Health when connected (best-effort, never blocks the UI).
        if app.healthKit.authState == .authorized {
            let start = startedAt
            let estimatedCalories = Double(durationMin) * 7.5
            Task {
                let saved = await app.healthKit.saveWorkout(
                    start: start, end: .now, calories: estimatedCalories)
                record.savedToHealthKit = saved
            }
        }

        finished = true
    }

    private var averageRPE: Double {
        let rpes = logged.flatMap(\.sets).compactMap(\.rpe)
        guard !rpes.isEmpty else { return 7.5 }
        return rpes.reduce(0, +) / Double(rpes.count)
    }
}

// MARK: - Per-exercise card

struct ExerciseLogCard: View {
    @Binding var logged: LoggedExercise
    let onSetCompleted: (Int) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(logged.exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                    Spacer()
                    Text(logged.exercise.primaryMuscles.joined(separator: " · "))
                        .font(.system(size: 10)).foregroundStyle(Theme.faint)
                }

                // Column labels
                HStack(spacing: 8) {
                    Text("SET").frame(width: 28, alignment: .leading)
                    Text("LB").frame(maxWidth: .infinity)
                    Text("REPS").frame(maxWidth: .infinity)
                    Text("RPE").frame(maxWidth: .infinity)
                    Text("RIR").frame(maxWidth: .infinity)
                    Text("").frame(width: 34)
                }
                .font(.system(size: 8.5, weight: .semibold))
                .kerning(1)
                .foregroundStyle(Theme.faint)

                ForEach($logged.sets) { $set in
                    SetRow(set: $set, index: indexOf(set: set)) {
                        onSetCompleted(logged.restSeconds)
                    }
                }

                Button {
                    let last = logged.sets.last
                    logged.sets.append(WorkoutSet(weightLb: last?.weightLb ?? 0,
                                                  reps: last?.reps ?? 0))
                } label: {
                    Label("Add set", systemImage: "plus")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }

    private func indexOf(set: WorkoutSet) -> Int {
        (logged.sets.firstIndex { $0.id == set.id } ?? 0) + 1
    }
}

struct SetRow: View {
    @Binding var set: WorkoutSet
    let index: Int
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(set.completed ? Theme.green : Theme.muted)
                .frame(width: 28, alignment: .leading)

            NumberField(value: $set.weightLb)
            IntField(value: $set.reps)
            OptionalRPEField(value: $set.rpe)
            OptionalIntField(value: $set.rir)

            Button {
                set.completed.toggle()
                if set.completed { onComplete() }
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(set.completed ? Theme.green : Theme.faint.opacity(0.5))
            }
            .frame(width: 34)
        }
    }
}

// MARK: - Numeric fields

struct NumberField: View {
    @Binding var value: Double

    var body: some View {
        TextField("0", text: Binding(
            get: { value > 0 ? String(Int(value)) : "" },
            set: { value = Double($0) ?? 0 }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.cream)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bg.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
    }
}

struct IntField: View {
    @Binding var value: Int

    var body: some View {
        TextField("0", text: Binding(
            get: { value > 0 ? String(value) : "" },
            set: { value = Int($0) ?? 0 }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.cream)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bg.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
    }
}

struct OptionalRPEField: View {
    @Binding var value: Double?

    var body: some View {
        TextField("–", text: Binding(
            get: { value.map { String(format: "%g", $0) } ?? "" },
            set: { value = Double($0) }
        ))
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .font(.system(size: 13))
        .foregroundStyle(Theme.creamDim)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bg.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
    }
}

struct OptionalIntField: View {
    @Binding var value: Int?

    var body: some View {
        TextField("–", text: Binding(
            get: { value.map(String.init) ?? "" },
            set: { value = Int($0) }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.system(size: 13))
        .foregroundStyle(Theme.creamDim)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bg.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
    }
}

// MARK: - Exercise picker

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (Exercise) -> Void
    @State private var query = ""

    private var results: [Exercise] {
        query.isEmpty ? MockData.exercises
                      : MockData.exercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(results) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.cream)
                        Text(exercise.primaryMuscles.joined(separator: " · "))
                            .font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
