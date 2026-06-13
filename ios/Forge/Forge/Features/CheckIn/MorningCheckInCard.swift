import SwiftUI

/// Dashboard entry point for the morning check-in. Prompts when not yet done
/// today; collapses to a one-line summary once completed.
struct MorningCheckInCard: View {
    @Environment(AppState.self) private var app
    @State private var showSheet = false

    var body: some View {
        Group {
            if let c = app.checkIn {
                Card {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18)).foregroundStyle(Theme.green)
                        VStack(alignment: .leading, spacing: 2) {
                            EyebrowLabel(text: "Morning Check-In · done", tone: .green)
                            Text("Sleep \(c.sleepQuality)/5 · soreness \(c.soreness)/10 · energy \(c.energy)/5 · stress \(c.stress)/5")
                                .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        }
                        Spacer()
                        Button("Redo") { showSheet = true }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.gold)
                    }
                }
            } else {
                Button { showSheet = true } label: {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "sun.horizon.fill")
                                .font(.system(size: 20)).foregroundStyle(Theme.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start your morning check-in")
                                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                                Text("10 seconds — tunes today's directive and the coach.")
                                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12)).foregroundStyle(Theme.faint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showSheet) { MorningCheckInView() }
    }
}
