import SwiftUI

struct TrainHomeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                SectionHeader(eyebrow: "Train", title: "Workouts",
                              subtitle: "Tuned daily for recovery \(app.recovery.today.recovery) and the knee.")

                quickActions
                todayCard
                programCard
                volumeCard
                prCard
                historyList
            }
            .navigationBarHidden(true)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickAction(icon: "wand.and.stars", label: "Generate") { GeneratorView() }
            QuickAction(icon: "books.vertical.fill", label: "Exercises") { ExerciseLibraryView() }
            QuickAction(icon: "camera.viewfinder", label: "Form AI") { FormAnalysisView() }
        }
    }

    private var todayCard: some View {
        let plan = app.workouts.todaysPlan
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Today")
                    Spacer()
                    Chip(text: "~\(plan.estMinutes) min", tone: .gold)
                }
                Text(plan.name).font(Theme.display(21)).foregroundStyle(Theme.cream)
                CoachNote(text: plan.rationale)

                ForEach(plan.blocks) { block in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(block.label.uppercased())
                                .font(.system(size: 9, weight: .semibold)).kerning(1.3)
                                .foregroundStyle(Theme.gold)
                            Spacer()
                            Text(block.note).font(.system(size: 10)).foregroundStyle(Theme.faint)
                        }
                        ForEach(block.items) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Theme.cream)
                                    Text(item.scheme).font(.system(size: 11)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 4)
                }

                NavigationLink { WorkoutLoggerView(plan: plan) } label: {
                    Text("Start Logging")
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }

    private var programCard: some View {
        let p = app.workouts.enrolledProgram
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    EyebrowLabel(text: "Active Program")
                    Spacer()
                    Chip(text: "Week \(p.week)/\(p.totalWeeks)", tone: .green)
                }
                Text(p.name).font(Theme.display(18)).foregroundStyle(Theme.cream)
                Text("\(p.coach) · \(p.daysPerWeek) days/wk · \(p.focus)")
                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                CapsuleBar(value: Double(p.week), target: Double(p.totalWeeks), tone: .gold, height: 6)
            }
        }
    }

    private var volumeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Weekly Volume by Muscle")
                ForEach(app.workouts.muscleVolume) { m in
                    HStack(spacing: 10) {
                        Text(m.muscle).font(.system(size: 11.5)).foregroundStyle(Theme.creamDim)
                            .frame(width: 80, alignment: .leading)
                        CapsuleBar(value: Double(m.sets), target: Double(m.optimalHigh),
                                   tone: m.inOptimal ? .green : .amber, height: 5)
                        Text("\(m.sets) / \(m.optimalLow)–\(m.optimalHigh)")
                            .font(.system(size: 10)).foregroundStyle(Theme.faint)
                            .frame(width: 54, alignment: .trailing)
                    }
                }
                Text("Quads intentionally under target — knee rehab block.")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
            }
        }
    }

    private var prCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Personal Records")
                ForEach(app.workouts.personalRecords) { pr in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pr.exerciseName).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.cream)
                            Text(pr.date).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                        }
                        Spacer()
                        Text("\(Int(pr.weightLb)) lb × \(pr.reps)")
                            .font(Theme.display(16))
                            .foregroundStyle(Theme.goldGradient)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: "Recent Sessions")
            ForEach(app.workouts.history) { workout in
                WorkoutHistoryRow(workout: workout)
            }
        }
    }
}

struct QuickAction<Destination: View>: View {
    let icon: String
    let label: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Theme.gold)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.creamDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 13).fill(Theme.cardGradient))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text("\(workout.date.formatted(.dateTime.month().day())) · \(workout.durationMin) min · RPE \(String(format: "%.1f", workout.avgRPE)) · felt \(workout.feel.rawValue.lowercased())")
                            .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    Text("\(Int(workout.totalVolumeLb).formatted()) lb")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.gold)
                }
                ForEach(workout.exercises) { logged in
                    HStack {
                        Text(logged.exercise.name).font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        Spacer()
                        Text(setSummary(logged))
                            .font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private func setSummary(_ logged: LoggedExercise) -> String {
        logged.sets.map { set in
            let pr = set.isPR ? " ★" : ""
            return set.weightLb > 0 ? "\(Int(set.weightLb))×\(set.reps)\(pr)" : "\(set.reps) rds"
        }
        .joined(separator: " · ")
    }
}
