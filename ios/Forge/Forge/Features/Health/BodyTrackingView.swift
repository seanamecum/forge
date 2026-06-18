import SwiftUI
import Charts

struct BodyTrackingView: View {
    private let history = MockData.bodyHistory

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Health", title: "Body Tracking",
                          subtitle: "Lean bulk in progress: +6.5 lb over 90 days, 68% of it lean mass.")

            statRow
            weightChart
            measurementsCard
            photosCard
            comparisonCard
        }
        .navigationTitle("Body")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statRow: some View {
        Card(gold: true) {
            HStack(spacing: 14) {
                StatTile(label: "Weight", value: "200.0", unit: "lb", hint: "+1.8 / 30d", tone: .gold)
                StatTile(label: "Body Fat", value: "14.1", unit: "%", hint: "+0.2 / 30d")
                StatTile(label: "Lean Mass", value: "171.8", unit: "lb", hint: "+1.2 / 30d", tone: .green)
            }
        }
    }

    private var weightChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                EyebrowLabel(text: "Weight · 14 Days")
                Sparkline(values: MockData.weightTrend, height: 64)
                HStack {
                    Text("196.8 lb").font(.system(size: 10)).foregroundStyle(Theme.faint)
                    Spacer()
                    Text("trend +0.6 lb/wk — on plan").font(.system(size: 10)).foregroundStyle(Theme.green)
                    Spacer()
                    Text("200.0 lb").font(.system(size: 10)).foregroundStyle(Theme.faint)
                }
            }
        }
    }

    private var measurementsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Measurements")
                    Spacer()
                    ComingSoonButton("Log", feature: "Weight logging")
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(MockData.measurements) { m in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name.uppercased())
                                .font(.system(size: 8.5, weight: .semibold)).kerning(1)
                                .foregroundStyle(Theme.muted)
                            Text(m.value).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.cream)
                            if let delta = m.delta30d {
                                Text("\(delta) /30d").font(.system(size: 9.5)).foregroundStyle(Theme.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var photosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Progress Photos")
                    Spacer()
                    ComingSoonButton("Add", feature: "Progress photos")
                }
                HStack(spacing: 8) {
                    ForEach(history) { snap in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.bgElevated)
                                .frame(height: 110)
                                .overlay(
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 30))
                                        .foregroundStyle(Theme.gold.opacity(0.25))
                                )
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                            Text(snap.date).font(.system(size: 9.5)).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
    }

    private var comparisonCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "90-Day Comparison")
                ForEach(history) { snap in
                    HStack {
                        Text(snap.date).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            .frame(width: 56, alignment: .leading)
                        Text("\(String(format: "%.1f", snap.weightLb)) lb")
                            .font(.system(size: 12.5, weight: .medium)).foregroundStyle(Theme.cream)
                        Spacer()
                        Text("\(String(format: "%.1f", snap.bodyFatPct))% bf")
                            .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        Spacer()
                        Text("LM \(String(format: "%.1f", snap.leanMassLb))")
                            .font(.system(size: 12)).foregroundStyle(Theme.green)
                    }
                    .padding(.vertical, 3)
                }
                CoachNote(text: "Before/after share card unlocks at the 12-week mark — June 24. Lean-mass fraction of gain is 68%, which is excellent for a 280-calorie surplus.")
            }
        }
    }
}
