import SwiftUI

/// Reusable loading / empty / error states — consistent across every feature.

struct LoadingStateView: View {
    var label = "Loading"

    var body: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Theme.gold)
            Text(label.uppercased())
                .font(Theme.eyebrow(9))
                .kerning(2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Theme.gold.opacity(0.5))
            Text(title)
                .font(Theme.display(20))
                .foregroundStyle(Theme.cream)
            Text(message)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(GoldButtonStyle(compact: true))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

/// A secondary action whose backend isn't in this build yet. Replaces dead
/// no-op buttons with one honest, consistent affordance — no silent taps,
/// no "(placeholder)" labels. Self-contained so it needs no per-view state.
struct ComingSoonButton: View {
    let title: String
    let feature: String
    var compact = true
    var gold = false
    @State private var show = false

    init(_ title: String, feature: String, compact: Bool = true, gold: Bool = false) {
        self.title = title
        self.feature = feature
        self.compact = compact
        self.gold = gold
    }

    var body: some View {
        button
            .alert("Available at launch", isPresented: $show) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("\(feature) activates when you connect your Forge account. It's on the launch roadmap.")
            }
            .accessibilityHint("\(feature) is coming at launch")
    }

    @ViewBuilder private var button: some View {
        if gold {
            Button(title) { show = true }.buttonStyle(GoldButtonStyle())
        } else {
            Button(title) { show = true }.buttonStyle(GhostButtonStyle(compact: compact))
        }
    }
}

/// Persistent local interest capture — the pre-backend waitlist. Joining flips
/// once, survives launches, and syncs to the server when accounts ship.
enum Waitlist {
    static func key(_ feature: String) -> String {
        "forge.waitlist." + feature.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    static func isJoined(_ feature: String) -> Bool {
        UserDefaults.standard.bool(forKey: key(feature))
    }
    static func join(_ feature: String) {
        UserDefaults.standard.set(true, forKey: key(feature))
    }
    static func leave(_ feature: String) {
        UserDefaults.standard.removeObject(forKey: key(feature))
    }
}

/// One-tap waitlist button: joins locally, confirms with state + haptic, and
/// never dead-ends. Distinct from ComingSoonButton — this one records intent.
struct WaitlistButton: View {
    let feature: String
    @State private var joined: Bool

    init(feature: String) {
        self.feature = feature
        _joined = State(initialValue: Waitlist.isJoined(feature))
    }

    var body: some View {
        if joined {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12)).foregroundStyle(Theme.green)
                Text("You're on the list")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.green)
            }
            .accessibilityLabel("On the \(feature) waitlist")
        } else {
            Button("Join the waitlist") {
                Haptics.success()
                Waitlist.join(feature)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { joined = true }
            }
            .buttonStyle(GoldButtonStyle(compact: true))
            .accessibilityHint("Registers your interest in \(feature)")
        }
    }
}

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.rubyBright)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.creamDim)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let onDismiss {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 11).fill(Theme.ruby.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.ruby.opacity(0.35), lineWidth: 1))
    }
}
