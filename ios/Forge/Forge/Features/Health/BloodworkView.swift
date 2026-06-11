import SwiftUI

struct BloodworkView: View {
    private var grouped: [(BloodworkMarker.Category, [BloodworkMarker])] {
        BloodworkMarker.Category.allCases.compactMap { category in
            let items = MockData.bloodwork.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Health", title: "Bloodwork",
                          subtitle: "14 markers, interpreted in the context of your training, sleep, and intake — not just flagged.")

            DisclaimerNote(text: "Bloodwork interpretation is educational context, not diagnosis or treatment. Review results and any intervention with your physician.")

            ForEach(grouped, id: \.0) { category, markers in
                VStack(alignment: .leading, spacing: 10) {
                    EyebrowLabel(text: category.rawValue)
                    ForEach(markers) { marker in
                        MarkerCard(marker: marker)
                    }
                }
            }

            Button("Upload New Panel (placeholder)") {}
                .buttonStyle(GhostButtonStyle())
        }
        .navigationTitle("Bloodwork")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MarkerCard: View {
    let marker: BloodworkMarker

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marker.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text(marker.takenAt).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(String(format: "%g", marker.value))
                                .font(Theme.display(20)).foregroundStyle(Theme.goldGradient)
                            Text(marker.unit).font(.system(size: 9.5)).foregroundStyle(Theme.muted)
                        }
                        if let delta = marker.delta {
                            Text(delta).font(.system(size: 10.5)).foregroundStyle(Theme.green)
                        }
                    }
                }

                RangeBar(marker: marker)

                HStack {
                    Chip(text: marker.status, tone: marker.statusTone)
                    Spacer()
                    Text("Optimal \(String(format: "%g", marker.optimalLow))–\(String(format: "%g", marker.optimalHigh)) \(marker.unit)")
                        .font(.system(size: 10)).foregroundStyle(Theme.faint)
                }

                CoachNote(text: marker.aiNote)
            }
        }
    }
}

/// Normal range track with the optimal band highlighted and a value marker.
struct RangeBar: View {
    let marker: BloodworkMarker

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let span = max(0.001, marker.normalHigh - marker.normalLow)
            let optStart = (marker.optimalLow - marker.normalLow) / span
            let optWidth = (marker.optimalHigh - marker.optimalLow) / span
            let pos = ((marker.value - marker.normalLow) / span).clamped01

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.gold.opacity(0.07)).frame(height: 8)
                Capsule()
                    .fill(Theme.green.opacity(0.22))
                    .frame(width: max(0, width * optWidth), height: 8)
                    .offset(x: width * optStart.clamped01)
                Circle()
                    .fill(marker.statusTone.color)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                    .offset(x: width * pos - 6.5)
                    .shadow(color: marker.statusTone.color.opacity(0.6), radius: 4)
            }
        }
        .frame(height: 14)
    }
}

private extension Double {
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }
}
