import SwiftUI

/// The Connected Ecosystem hub. Forge's strategy made visible: one intelligent
/// layer over every wearable — coverage, conflicts, and gaps handled by the
/// DataHub, with the future Forge Band as a roadmap, never a dependency.
struct WearablesView: View {
    @Environment(AppState.self) private var app
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Connected Ecosystem", title: "Wearable Hub",
                          subtitle: "Every device feeds one signal stream. Forge turns whatever you wear into coaching.")

            coverageCard
            crossDeviceCard
            healthKitCard

            SectionHeader(eyebrow: "Devices", title: "Your stack",
                          subtitle: "Connected devices sync automatically. Each card shows exactly what it contributes.")
            ForEach(app.recovery.wearables) { device in
                WearableRow(device: device)
            }

            preferredSourcesCard
            recommendedStackCard
            forgeBandCard
        }
        .navigationTitle("Ecosystem")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Coverage (what the stack can and can't see)

    private var coverageCard: some View {
        let (covered, missing) = DataHub.coverage(connected: app.connectedSources)
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Data Coverage")
                    Spacer()
                    Chip(text: "\(covered.count) of \(MetricKind.allCases.count) signals",
                         tone: missing.isEmpty ? .green : .gold)
                }
                CapsuleBar(value: Double(covered.count), target: Double(MetricKind.allCases.count),
                           tone: .gold, height: 5)
                if missing.isEmpty {
                    Text("Full coverage — every Forge signal has a live source.")
                        .font(.system(size: 12)).foregroundStyle(Theme.green)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MISSING FROM YOUR STACK")
                            .font(.system(size: 8.5, weight: .semibold)).kerning(1.4)
                            .foregroundStyle(Theme.muted)
                        FlowChips(options: missing.map(\.label), isSelected: { _ in false }, toggle: { _ in })
                            .opacity(0.8)
                        if let suggestion = bestGapFiller() {
                            Text("Connecting \(suggestion.displayName) would add \(DataHub.fillsGap(suggestion, connected: app.connectedSources).map { $0.label.lowercased() }.joined(separator: ", ")).")
                                .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Data coverage: \(covered.count) of \(MetricKind.allCases.count) signals flowing")
    }

    private func bestGapFiller() -> DataSource? {
        let candidates = DataSource.allCases
            .filter { $0 != .forgeBand && !app.connectedSources.contains($0) }
        let best = candidates.max {
            DataHub.fillsGap($0, connected: app.connectedSources).count
                < DataHub.fillsGap($1, connected: app.connectedSources).count
        }
        guard let best, !DataHub.fillsGap(best, connected: app.connectedSources).isEmpty else { return nil }
        return best
    }

    // MARK: - Cross-device intelligence

    private var crossDeviceCard: some View {
        Card {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 15)).foregroundStyle(Theme.gold)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 3) {
                    EyebrowLabel(text: "Cross-Device Read · Today")
                    Text(app.deviceNarrative)
                        .font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Apple Health (the iOS backbone)

    private var healthKitCard: some View {
        let hk = app.healthKit
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill").foregroundStyle(Theme.rubyBright)
                    Text("Apple Health").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.cream)
                    Spacer()
                    healthChip(for: hk.authState)
                }
                Text(hk.statusMessage).font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                if hk.usingMockData && hk.authState != .authorized {
                    Chip(text: "Demo data", tone: .amber)
                }

                if let error = hk.lastError {
                    ErrorBanner(message: error) { hk.lastError = nil }
                }

                HStack(spacing: 14) {
                    StatTile(label: "Steps", value: "\(hk.steps)")
                    StatTile(label: "Heart rate", value: "\(hk.heartRate)", unit: "bpm")
                    StatTile(label: "Resting HR", value: "\(hk.restingHeartRate)", unit: "bpm")
                    StatTile(label: "HRV", value: "\(hk.hrvMs)", unit: "ms")
                }
                HStack(spacing: 14) {
                    StatTile(label: "Energy", value: "\(hk.activeEnergy)", unit: "kcal")
                    StatTile(label: "Sleep", value: String(format: "%.1f", hk.sleepHoursLastNight), unit: "h")
                    StatTile(label: "Weight", value: String(format: "%.0f", hk.bodyMassLb), unit: "lb")
                    StatTile(label: "Workouts", value: "\(hk.workoutsLast7Days)", hint: "last 7 days")
                }

                if hk.isLoading {
                    LoadingStateView(label: "Reading Health data")
                } else {
                    switch hk.authState {
                    case .denied:
                        Button("Open Settings to enable Health access") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))
                    case .authorized:
                        HStack(spacing: 8) {
                            Button("Refresh") {
                                Task {
                                    await hk.refresh()
                                    app.ingestHealthKitSignals()
                                }
                            }
                            .buttonStyle(GhostButtonStyle(compact: true))
                            Button("Save weight to Health") {
                                Task {
                                    if await hk.saveBodyMass(hk.bodyMassLb) {
                                        hk.statusMessage = "Weight saved to Apple Health ✓"
                                    }
                                }
                            }
                            .buttonStyle(GhostButtonStyle(compact: true))
                        }
                    case .unavailable:
                        EmptyView()
                    case .notDetermined:
                        Button("Connect Apple Health") {
                            Task {
                                await hk.connect()
                                app.ingestHealthKitSignals()
                            }
                        }
                        .buttonStyle(GoldButtonStyle(compact: true))
                    }
                }
            }
        }
    }

    private func healthChip(for state: HealthAuthState) -> some View {
        switch state {
        case .authorized: return Chip(text: "Connected", tone: .green)
        case .denied: return Chip(text: "Denied", tone: .ruby)
        case .unavailable: return Chip(text: "Unavailable", tone: .neutral)
        case .notDetermined: return Chip(text: "Connect", tone: .gold)
        }
    }

    // MARK: - Preferred sources (conflict resolution, user-controlled)

    /// Metrics worth arbitrating when devices overlap.
    private static let contestable: [MetricKind] = [.sleep, .hrv, .restingHR, .heartRate]

    @ViewBuilder
    private var preferredSourcesCard: some View {
        let contested = Self.contestable.filter { app.recovery.contenders(for: $0).count > 1 }
        if !contested.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    EyebrowLabel(text: "Preferred Sources")
                    Text("More than one device reports these signals. Pick the winner — Forge falls back to the next source automatically if it stops syncing.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                    ForEach(contested) { metric in
                        PreferredSourceRow(metric: metric)
                    }
                }
            }
        }
    }

    // MARK: - Recommended stack

    private var recommendedStackCard: some View {
        let goal = app.user.primaryGoal
        let stack = DataHub.recommendedStack(for: goal)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Recommended Stack")
                    Spacer()
                    Chip(text: goal.rawValue, tone: .gold)
                }
                ForEach(stack) { source in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: app.connectedSources.contains(source) ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(app.connectedSources.contains(source) ? Theme.green : Theme.gold)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.displayName)
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                            Text(source.pitch)
                                .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                }
                Text("Future partner offers will appear here — Forge stays device-neutral; recommendations follow your goal, not sponsorships.")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
            }
        }
    }

    // MARK: - Forge Band roadmap

    private var forgeBandCard: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "circle.dashed.inset.filled")
                        .font(.system(size: 18)).foregroundStyle(Theme.goldGradient)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Forge Band").font(Theme.display(18)).foregroundStyle(Theme.cream)
                        Text("FUTURE HARDWARE · ROADMAP")
                            .font(.system(size: 8.5, weight: .semibold)).kerning(1.4)
                            .foregroundStyle(Theme.gold)
                    }
                    Spacer()
                    Chip(text: "Concept", tone: .gold)
                }
                Text("A sensor designed around the Forge Score — HRV, sleep, recovery, skin temperature, resting HR, strain, and readiness, tuned for the engine that already runs your day. Your current devices keep working forever; Forge is the layer, not the lock-in.")
                    .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 8) {
                    roadmapPhase(1, "Software layer", "Connect every wearable, unify the data", done: true)
                    roadmapPhase(2, "Trust & intelligence", "Coaching that makes each device more useful", done: true)
                    roadmapPhase(3, "Marketplace & partners", "Curated gear, coaches, and device offers", done: false)
                    roadmapPhase(4, "Forge Band", "Premium option — never a requirement", done: false)
                }
                WaitlistButton(feature: "Forge Band")
            }
        }
    }

    private func roadmapPhase(_ n: Int, _ title: String, _ detail: String, done: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(done ? Theme.gold.opacity(0.16) : Theme.card)
                    .overlay(Circle().stroke(done ? Theme.gold.opacity(0.5) : Theme.hairline, lineWidth: 1))
                    .frame(width: 22, height: 22)
                if done {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.gold)
                } else {
                    Text("\(n)").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.muted)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(done ? Theme.cream : Theme.creamDim)
                Text(detail).font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }
}

// MARK: - Preferred source row

private struct PreferredSourceRow: View {
    @Environment(AppState.self) private var app
    let metric: MetricKind

    var body: some View {
        let contenders = app.recovery.contenders(for: metric)
        let active = app.recovery.activeSource(for: metric)
        HStack(spacing: 10) {
            Image(systemName: metric.icon)
                .font(.system(size: 12)).foregroundStyle(Theme.gold)
                .frame(width: 22)
            Text(metric.label)
                .font(.system(size: 12.5, weight: .medium)).foregroundStyle(Theme.cream)
            Spacer()
            Menu {
                ForEach(contenders) { source in
                    Button {
                        Haptics.selection()
                        app.recovery.setPreferred(source, for: metric)
                    } label: {
                        if source == active {
                            Label(source.displayName, systemImage: "checkmark")
                        } else {
                            Text(source.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(active?.displayName ?? "Auto")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.goldBright)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9)).foregroundStyle(Theme.muted)
                }
            }
            .accessibilityLabel("\(metric.label) source: \(active?.displayName ?? "automatic")")
        }
    }
}

// MARK: - Device row

struct WearableRow: View {
    @Environment(AppState.self) private var app
    let device: WearableDevice
    @State private var showConnectInfo = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: device.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(device.connected ? Theme.gold : Theme.faint)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.gold.opacity(device.connected ? 0.08 : 0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(device.connected ? Theme.gold.opacity(0.3) : Theme.hairline, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        HStack(spacing: 6) {
                            Text(device.brand).font(.system(size: 11)).foregroundStyle(Theme.muted)
                            if let sync = device.lastSync {
                                Text("· synced \(sync)").font(.system(size: 11)).foregroundStyle(Theme.green)
                            }
                            if let battery = device.battery, device.connected {
                                Text("· \(battery)%").font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    Spacer()
                    if device.connected {
                        qualityChip
                    }
                    if device.source == .appleWatch || device.source == .smartScale {
                        // Real path: these flow through Apple Health today.
                        Button(device.connected ? "Sync" : "Pair") {
                            Haptics.tap()
                            app.recovery.toggleConnection(device)
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))
                    } else {
                        Button(device.connected ? "Demo" : "Connect") {
                            showConnectInfo = true
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))
                        .confirmationDialog("\(device.source.displayName) sync", isPresented: $showConnectInfo, titleVisibility: .visible) {
                            Button(device.connected ? "Stop demo preview" : "Preview with demo data") {
                                Haptics.tap()
                                app.recovery.toggleConnection(device)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Direct \(device.source.displayName) sync needs their cloud API and a Forge account — it lands with the backend launch. If \(device.source.displayName) writes to Apple Health, connect Apple Health above and the data flows today.")
                        }
                    }
                }

                if device.connected {
                    contributesRow
                } else {
                    whyConnectRow
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(device.name), \(device.connected ? "connected" : "not connected")")
    }

    private var qualityChip: some View {
        let q = DataHub.quality(ageHours: device.lastSyncAgeHours)
        let tone: Tone = q == .excellent ? .green : (q == .good ? .gold : .amber)
        return Chip(text: q.rawValue, tone: tone)
    }

    /// What this device feeds into the unified stream.
    private var contributesRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("CONTRIBUTES")
                .font(.system(size: 8, weight: .semibold)).kerning(1.3)
                .foregroundStyle(Theme.faint)
            FlowChips(options: device.source.capabilities.map(\.label),
                      isSelected: { _ in false }, toggle: { _ in })
                .opacity(0.85)
        }
    }

    /// The honest pitch: what NEW signals this device would add to the current stack.
    private var whyConnectRow: some View {
        let gaps = DataHub.fillsGap(device.source, connected: app.connectedSources)
        return VStack(alignment: .leading, spacing: 4) {
            Text(device.source.pitch)
                .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if !gaps.isEmpty {
                Text("Adds to your stack: \(gaps.map { $0.label.lowercased() }.joined(separator: ", "))")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.gold)
            }
        }
    }
}
