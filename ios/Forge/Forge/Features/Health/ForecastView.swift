import SwiftUI

struct ForecastView: View {
    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Digital Twin", title: "Forecast",
                          subtitle: "A preview of the trajectory view. These are illustrative sample projections — personalized forecasting from your own logged history is coming.")

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
                                Text("sample confidence").font(.system(size: 8.5)).foregroundStyle(Theme.faint)
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
        .navigationTitle("Digital Twin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
