import SwiftUI

struct WearablesView: View {
    @Environment(AppState.self) private var app

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
                    Chip(text: hk.isAuthorized ? "Connected" : "Connect",
                         tone: hk.isAuthorized ? .green : .gold)
                }
                Text(hk.statusMessage).font(.system(size: 11.5)).foregroundStyle(Theme.muted)

                HStack(spacing: 14) {
                    StatTile(label: "Steps", value: "\(hk.steps)")
                    StatTile(label: "Heart rate", value: "\(hk.heartRate)", unit: "bpm")
                    StatTile(label: "Energy", value: "\(hk.activeEnergy)", unit: "kcal")
                    StatTile(label: "Weight", value: String(format: "%.0f", hk.weightLb), unit: "lb")
                }

                Button(hk.isAuthorized ? "Refresh from Health" : "Connect Apple Health") {
                    Task {
                        if hk.isAuthorized { await hk.refresh() } else { await hk.connect() }
                    }
                }
                .buttonStyle(GhostButtonStyle(compact: true))
            }
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
