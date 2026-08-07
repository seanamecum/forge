import SwiftUI
import MapKit
import CoreLocation

/// Running — weekly mileage, recent runs, readiness-aware pace guidance,
/// and a REAL GPS run session: live map, distance, pace, and km splits.
struct RunningView: View {
    @Environment(AppState.self) private var app
    @State private var tracker = RunTrackerService()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Train · Endurance", title: "Running",
                          subtitle: runSubtitle)

            switch tracker.state {
            case .idle: startCard
            case .tracking, .paused: activeRunSection
            case .finished: summaryCard
            }

            if tracker.state == .idle {
                if app.isDemoAccount {
                    weeklyCard       // illustrative demo context
                    paceGuidance
                    recentRuns
                } else {
                    realWeekSummary  // real logged runs — honest empty when none
                    realRecentRuns
                }
            }
        }
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tracker.requestPermission()
            tracker.splitLengthMeters = app.user.usesImperial ? 1609.344 : 1000
        }
    }

    // MARK: - Start

    private var runSubtitle: String {
        if let injury = app.injuries.active.first {
            return "Engine work, tuned to your recovery and your \(injury.type.rawValue.lowercased())."
        }
        return "Engine work, tuned to your recovery and goals."
    }

    private var startCard: some View {
        let rec = app.recovery.today.recovery
        let injury = app.injuries.active.first
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Today's call")
                    Spacer()
                    Chip(text: "Recovery \(rec)", tone: rec >= 70 ? .green : .amber)
                }
                Text(rec >= 70 ? "Zone 2 · 25–35 min easy" : "Zone 2 · 20 min very easy")
                    .font(Theme.display(22)).foregroundStyle(Theme.cream)
                CoachNote(text: runGuidance(recovery: rec, injury: injury))
                if tracker.authorization == .denied, let err = tracker.lastError {
                    ErrorBanner(message: err)
                }
                Button("Start GPS Run") {
                    Haptics.success()
                    tracker.start()
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }

    /// Recovery- and injury-aware guidance — real state, never a fixed persona.
    private func runGuidance(recovery: Int, injury: InjuryProfile?) -> String {
        if let injury {
            return "Recovery \(recovery). Keep it flat and conversational — your \(injury.type.rawValue.lowercased()) is flagged, so ease off and stop if pain climbs past 3/10."
        }
        if recovery >= 70 {
            return "Recovery \(recovery) is green — an easy aerobic run is well within range. Keep it conversational and let the pace come to you."
        }
        return "Recovery \(recovery) is on the low side — keep this short and very easy, or swap for a brisk walk. Gentle aerobic work today."
    }

    // MARK: - Live run

    @ViewBuilder
    private var activeRunSection: some View {
        Card {
            VStack(spacing: 16) {
                runMap
                liveStatsRow
                splitChips
                runControls
            }
        }
    }

    private var runMap: some View {
        Map(position: $camera) {
            UserAnnotation()
            if tracker.route.count > 1 {
                MapPolyline(coordinates: tracker.route)
                    .stroke(Theme.gold, lineWidth: 4)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .mapControlVisibility(.hidden)
    }

    private var liveStatsRow: some View {
        let imperial = app.user.usesImperial
        let distance = RunMath.distanceLabel(meters: tracker.distanceMeters, imperial: imperial)
        let pace = RunMath.paceLabel(secPerKm: tracker.paceSecPerKm, imperial: imperial)
        return HStack(spacing: 0) {
            runStat(timeLabel, "Time")
            runStat(distance, imperial ? "Miles" : "Kilometers")
            runStat(pace, imperial ? "Pace /mi" : "Pace /km")
        }
    }

    @ViewBuilder
    private var splitChips: some View {
        if !tracker.splitsSecPerKm.isEmpty {
            let recent = Array(tracker.splitsSecPerKm.suffix(5))
            let offset = tracker.splitsSecPerKm.count - recent.count
            HStack(spacing: 6) {
                ForEach(Array(recent.enumerated()), id: \.offset) { i, split in
                    let unit = app.user.usesImperial ? "mi" : "km"
                    let m = Int(split) / 60, s = Int(split) % 60
                    let label = "\(unit) \(offset + i + 1) · \(m)'\(String(format: "%02d", s))\""
                    Chip(text: label, tone: .neutral)
                }
                Spacer()
            }
        }
    }

    private var runControls: some View {
        HStack(spacing: 10) {
            if tracker.state == .tracking {
                Button("Pause") { Haptics.tap(); tracker.pause() }
                    .buttonStyle(GhostButtonStyle())
            } else {
                Button("Resume") { Haptics.tap(); tracker.resume() }
                    .buttonStyle(GhostButtonStyle())
            }
            Button("Finish") {
                Haptics.success()
                tracker.stop()
                saveRun()
            }
            .buttonStyle(GoldButtonStyle())
        }
    }

    private func runStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.display(26))
                .foregroundStyle(Theme.cream)
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Run complete").font(Theme.display(24)).foregroundStyle(Theme.cream)
                HStack(spacing: 14) {
                    StatTile(label: "Distance",
                             value: RunMath.distanceLabel(meters: tracker.distanceMeters,
                                                          imperial: app.user.usesImperial),
                             unit: app.user.usesImperial ? "mi" : "km", tone: .gold)
                    StatTile(label: "Time", value: timeLabel)
                    StatTile(label: "Avg pace",
                             value: RunMath.paceLabel(secPerKm: tracker.paceSecPerKm,
                                                      imperial: app.user.usesImperial),
                             unit: app.user.usesImperial ? "/mi" : "/km")
                }
                Text(app.healthKit.authState == .authorized
                     ? "Saved to your training history and Apple Health."
                     : "Saved to your training history.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
                if let image = shareCard.rendered() {
                    ShareLink(item: image,
                              preview: SharePreview("Forge run", image: image)) {
                        Label("Share run", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                Button("Done") { tracker.reset() }
                    .buttonStyle(GoldButtonStyle())
            }
        }
    }

    private var shareCard: RunShareCard {
        RunShareCard(
            distance: RunMath.distanceLabel(meters: tracker.distanceMeters,
                                            imperial: app.user.usesImperial),
            distanceUnit: app.user.usesImperial ? "mi" : "km",
            time: timeLabel,
            pace: RunMath.paceLabel(secPerKm: tracker.paceSecPerKm,
                                    imperial: app.user.usesImperial),
            paceUnit: app.user.usesImperial ? "/mi" : "/km",
            date: tracker.startedAt ?? .now)
    }

    private func saveRun() {
        // Training history — the rest of Forge reacts to this run.
        let minutes = max(1, Int(tracker.elapsedSeconds / 60))
        let miles = tracker.distanceMeters / 1609.344
        let workout = Workout(
            name: String(format: "Run · %.2f %@",
                         app.user.usesImperial ? miles : tracker.distanceMeters / 1000,
                         app.user.usesImperial ? "mi" : "km"),
            date: .now, durationMin: minutes, exercises: [],
            avgRPE: 6, feel: .fine)
        app.workouts.finish(workout)

        // Persist locally — the run must still be there after a relaunch.
        PersistenceService.saveWorkout(
            WorkoutRecord(name: workout.name, date: .now, durationMin: minutes,
                          totalVolumeLb: 0, setCount: 0, avgRPE: 6,
                          exerciseSummary: String(format: "%.2f mi GPS run", miles)),
            context: PersistenceService.context)
        app.requestSync()

        // Close the loop: the run's load flows into strain → Forge Score → Directive.
        app.applyTrainingLoad()

        // Mirror to Apple Health as a real running workout.
        if app.healthKit.authState == .authorized, let start = tracker.startedAt {
            let meters = tracker.distanceMeters
            Task {
                await app.healthKit.saveRun(start: start, end: .now, meters: meters,
                                            calories: Double(minutes) * 11)
            }
        }
    }

    private var timeLabel: String {
        let s = Int(tracker.elapsedSeconds)
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Context (idle)

    // MARK: - Real run context (from logged GPS runs)

    /// Real GPS runs saved to training history (saveRun names them "Run · …").
    private var runWorkouts: [Workout] {
        app.workouts.history.filter { $0.name.hasPrefix("Run") }
    }

    private var realWeekSummary: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let week = runWorkouts.filter { $0.date >= cutoff }
        return Card {
            VStack(alignment: .leading, spacing: Space.sm) {
                EyebrowLabel(text: "This week")
                if week.isEmpty {
                    Text("No runs yet this week. Start a GPS run and your weekly log builds here.")
                        .font(Typography.footnote).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    let mins = week.reduce(0) { $0 + $1.durationMin }
                    Text("\(week.count) run\(week.count == 1 ? "" : "s") · \(mins) min")
                        .font(Typography.title3).foregroundStyle(Theme.cream)
                    Text("Distance and pace calibrate as you log more.")
                        .font(Typography.caption).foregroundStyle(Theme.faint)
                }
            }
        }
    }

    private var realRecentRuns: some View {
        Card {
            VStack(alignment: .leading, spacing: Space.sm) {
                EyebrowLabel(text: "Recent runs")
                if runWorkouts.isEmpty {
                    Text("Your logged runs appear here with distance and time — tap Start GPS Run above to log your first.")
                        .font(Typography.footnote).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(runWorkouts.prefix(6)) { run in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(run.name).font(Typography.callout.weight(.medium)).foregroundStyle(Theme.cream)
                                Text(run.date.formatted(.dateTime.weekday().month().day()))
                                    .font(Typography.caption).foregroundStyle(Theme.faint)
                            }
                            Spacer()
                            Text("\(run.durationMin) min")
                                .font(Typography.footnote).foregroundStyle(Theme.muted).monospacedDigit()
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: - Demo context (illustrative)

    private var weeklyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    EyebrowLabel(text: "Weekly mileage")
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
                EyebrowLabel(text: "Training paces · from your 21:42 5K")
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
                EyebrowLabel(text: "Recent runs")
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
