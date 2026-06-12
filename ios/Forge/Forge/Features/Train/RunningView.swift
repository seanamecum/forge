import SwiftUI

/// Running — weekly mileage, recent runs, readiness-aware pace guidance,
/// and a live (simulated) run session with timer.
struct RunningView: View {
    @Environment(AppState.self) private var app
    @State private var running = false
    @State private var elapsed = 0
    @State private var distance = 0.0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Train · Endurance", title: "Running",
                          subtitle: "Engine work, tuned to your recovery and the knee.")

            if running { activeRunCard } else { startCard }
            weeklyCard
            paceGuidance
            recentRuns
        }
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard running else { return }
            elapsed += 1
            distance += 0.0023 // ~8:50/mi simulated pace
        }
    }

    private var startCard: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Today's Call")
                    Spacer()
                    Chip(text: "Knee: bike preferred", tone: .amber)
                }
                Text("Zone 2 · 25 min easy").font(Theme.display(21)).foregroundStyle(Theme.cream)
                CoachNote(text: "Recovery 78 allows a run, but the patellar tendon is mid-rehab — keep it flat, conversational pace, and stop if pain passes 3/10. The bike covers conditioning with zero tendon cost if the knee talks.")
                Button("Start Run") {
                    running = true
                    elapsed = 0
                    distance = 0
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }

    private var activeRunCard: some View {
        Card(gold: true) {
            VStack(spacing: 14) {
                EyebrowLabel(text: "Run in progress · GPS simulated")
                HStack(spacing: 24) {
                    StatTile(label: "Time", value: timeLabel, tone: .gold)
                    StatTile(label: "Distance", value: String(format: "%.2f", distance), unit: "mi")
                    StatTile(label: "Pace", value: paceLabel, unit: "/mi")
                    StatTile(label: "HR", value: "\(142 + (elapsed % 9))", unit: "bpm", tone: .green)
                }
                Button("End Run") {
                    running = false
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private var weeklyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    EyebrowLabel(text: "Weekly Mileage")
                    Spacer()
                    Chip(text: "12.4 mi this week", tone: .gold)
                }
                Sparkline(values: [8.2, 11.5, 9.8, 14.1, 12.6, 10.2, 12.4], height: 52)
                Text("Held flat on purpose — mileage resumes its build once the knee clears phase 3.")
                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }

    private var paceGuidance: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                EyebrowLabel(text: "Training Paces · from your 21:42 5K")
                InfoRow(label: "Zone 2 / easy", value: "9:40–10:20 /mi", valueTone: .green)
                InfoRow(label: "Tempo", value: "7:55–8:10 /mi", valueTone: .gold)
                InfoRow(label: "Intervals (800s)", value: "6:55 /mi", valueTone: .amber)
                InfoRow(label: "Hockey shift sim (bike)", value: "30s on / 30s off × 10", valueTone: .neutral)
            }
        }
    }

    private var recentRuns: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Recent Runs")
                ForEach(RunLog.recent) { run in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(run.name).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Theme.cream)
                            Text(run.when).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(String(format: "%.1f", run.miles)) mi · \(run.pace)/mi")
                                .font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
                            Text("avg \(run.avgHR) bpm").font(.system(size: 10.5)).foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var timeLabel: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    private var paceLabel: String {
        guard distance > 0.01 else { return "–:––" }
        let secPerMile = Double(elapsed) / distance
        return String(format: "%d:%02d", Int(secPerMile) / 60, Int(secPerMile) % 60)
    }
}

struct RunLog: Identifiable {
    let id = UUID()
    let name: String
    let when: String
    let miles: Double
    let pace: String
    let avgHR: Int

    static let recent: [RunLog] = [
        RunLog(name: "Easy shake-out", when: "Yesterday · 7:02 AM", miles: 3.1, pace: "9:52", avgHR: 138),
        RunLog(name: "Z2 base", when: "Tue · 6:48 AM", miles: 4.6, pace: "9:44", avgHR: 141),
        RunLog(name: "Strides + easy", when: "Sun · 8:15 AM", miles: 4.7, pace: "9:31", avgHR: 145),
    ]
}
