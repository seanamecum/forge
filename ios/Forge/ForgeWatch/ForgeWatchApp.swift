import SwiftUI
import WatchConnectivity

// Forge for Apple Watch: the Daily Directive on your wrist. The iPhone pushes
// a snapshot over WatchConnectivity whenever the dashboard refreshes; the
// watch renders the last-known state and never shows an empty screen.

@main
struct ForgeWatchApp: App {
    @State private var store = WatchSessionStore()

    var body: some Scene {
        WindowGroup {
            WatchDirectiveView(snapshot: store.snapshot)
                .onAppear { store.activate() }
        }
    }
}

// MARK: - Connectivity

/// Receives directive snapshots from the paired iPhone. Last-known context is
/// read back on activation, so relaunches show data without waiting for a push.
@Observable
final class WatchSessionStore: NSObject, WCSessionDelegate {
    var snapshot: WidgetSnapshot = .placeholder

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        apply(session.receivedApplicationContext)
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return }
        Task { @MainActor in self.snapshot = decoded }
    }

    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }
}

// MARK: - Theme (self-contained, matches the brand)

enum WatchTheme {
    static let bg = Color(red: 0.020, green: 0.024, blue: 0.031)
    static let cream = Color(red: 0.957, green: 0.925, blue: 0.847)
    static let creamDim = Color(red: 0.812, green: 0.769, blue: 0.659)
    static let muted = Color(red: 0.545, green: 0.576, blue: 0.659)
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldBright = Color(red: 0.961, green: 0.863, blue: 0.478)
}

// MARK: - View

struct WatchDirectiveView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(snapshot.forgeScore)")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(WatchTheme.goldBright)
                    Text("FORGE")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.6)
                        .foregroundStyle(WatchTheme.muted)
                    Spacer()
                }

                Text(snapshot.headline)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(WatchTheme.cream)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(WatchTheme.gold.opacity(0.25))

                ForEach(snapshot.rows, id: \.label) { row in
                    HStack(spacing: 6) {
                        Image(systemName: row.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(WatchTheme.gold)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(row.label.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .kerning(0.8)
                                .foregroundStyle(WatchTheme.muted)
                            Text(row.value)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(WatchTheme.creamDim)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 0)
                    }
                }

                Text(snapshot.priority)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(WatchTheme.gold)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 2)
        }
        .background(WatchTheme.bg)
    }
}
