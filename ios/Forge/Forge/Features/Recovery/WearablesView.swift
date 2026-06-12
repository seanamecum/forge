import SwiftUI

struct WearablesView: View {
    @Environment(AppState.self) private var app
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Recover · Hardware", title: "Wearable Hub",
                          subtitle: "Every device feeds one signal stream. Apple Health is the iOS backbone.")

            healthKitCard

            ForEach(app.recovery.wearables) { device in
                WearableRow(device: device)
            }
        }
        .navigationTitle("Wearables")
        .navigationBarTitleDisplayMode(.inline)
    }

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
                            Button("Refresh") { Task { await hk.refresh() } }
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
                        Button("Connect Apple Health") { Task { await hk.connect() } }
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
}

struct WearableRow: View {
    @Environment(AppState.self) private var app
    let device: WearableDevice

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
                    Button(device.connected ? "Sync" : "Pair") {
                        app.recovery.toggleConnection(device)
                    }
                    .buttonStyle(GhostButtonStyle(compact: true))
                }

                if device.connected {
                    FlowChips(options: device.permissions, isSelected: { _ in false }, toggle: { _ in })
                        .opacity(0.85)
                }
            }
        }
    }
}
