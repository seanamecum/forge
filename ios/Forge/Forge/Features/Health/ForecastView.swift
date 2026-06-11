import SwiftUI

struct ForecastView: View {
    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Digital Twin", title: "Forecast",
                          subtitle: "Your trajectory, run forward. Current surplus, progression rate, recovery, and rehab phase — extrapolated with confidence bands.")

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
                                Text("confidence").font(.system(size: 8.5)).foregroundStyle(Theme.faint)
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

            DisclaimerNote(text: "Forecasts are model estimates from current trends — direction, not destiny. Adherence, biology, and life all bend the curve.")
        }
        .navigationTitle("Digital Twin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
