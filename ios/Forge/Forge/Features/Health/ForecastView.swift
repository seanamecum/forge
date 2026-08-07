import SwiftUI

struct ForecastView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Digital Twin", title: "Forecast", subtitle: subtitle)

            // The illustrative sample projections are demo-only. Real users never
            // see fabricated forecasts — they get an honest "building" state.
            if app.isDemoAccount {
                sampleForecasts
            } else {
                buildingState
            }
        }
        .navigationTitle("Digital Twin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subtitle: String {
        app.isDemoAccount
            ? "A preview of the trajectory view. These are illustrative sample projections."
            : "Personalized 12-week projections from your own logged history — building as you train, eat, and recover."
    }

    // MARK: - Real users: honest building state

    private var buildingState: some View {
        let logged = app.workouts.history.count
        return VStack(spacing: 12) {
            Card(gold: true) {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack(spacing: Space.md) {
                        ZStack {
                            Circle().fill(Theme.gold.opacity(0.12))
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: IconSize.lg)).foregroundStyle(Theme.gold)
                        }
                        .frame(width: 46, height: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            EyebrowLabel(text: "Your Digital Twin")
                            Text("Forecasts build as you log").font(Typography.title3).foregroundStyle(Theme.cream)
                        }
                    }
                    Text("Once Forge has a few weeks of your real training, weight, and recovery, it projects where your strength, body composition, and endurance are trending — direction, not destiny. No sample numbers until they're yours.")
                        .font(Typography.footnote).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if logged > 0 {
                        Text("So far: \(logged) session\(logged == 1 ? "" : "s") logged — keep going and your first projections unlock.")
                            .font(Typography.caption).foregroundStyle(Theme.faint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Demo: illustrative sample

    private var sampleForecasts: some View {
        VStack(spacing: 12) {
            HStack {
                Chip(text: "Sample data — not from your history", tone: .amber)
                Spacer()
            }
            ForEach(MockData.forecasts) { f in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        EyebrowLabel(text: f.metric)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(f.current).font(Theme.display(20)).foregroundStyle(Theme.creamDim)
                            Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(Theme.faint)
                            Text(f.projected).font(Theme.display(24)).foregroundStyle(Theme.goldGradient)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Int(f.confidence * 100))%")
                                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                                Text("sample confidence").font(Typography.eyebrow).foregroundStyle(Theme.faint)
                            }
                        }
                        HStack {
                            Chip(text: f.eta, tone: .gold)
                            Spacer()
                        }
                        CapsuleBar(value: f.confidence, target: 1, tone: .gold, height: 4)
                        Text(f.rationale).font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                }
            }
            DisclaimerNote(text: "These are illustrative examples, not a prediction from your data yet. Real forecasts will show direction, not destiny — adherence and biology bend the curve.")
        }
    }
}
