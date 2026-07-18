import SwiftUI

/// Circular 0–100 score ring with gradient stroke and glow.
struct ScoreRing: View {
    let value: Int
    var label: String? = nil
    var sublabel: String? = nil
    var size: CGFloat = 120
    var lineWidth: CGFloat = 9
    var tone: Tone = .gold
    var animated = true

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.gold.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: shown / 100)
                .stroke(
                    AngularGradient(colors: [tone.color.opacity(0.5), tone.color],
                                    center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(330)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tone.color.opacity(0.5), radius: 6)

            VStack(spacing: 1) {
                Text("\(value)")
                    .font(Theme.display(size * 0.30))
                    .foregroundStyle(tone.color)
                if let label {
                    Text(label.uppercased())
                        .font(.system(size: max(8, size * 0.075), weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: max(8, size * 0.07)))
                        .foregroundStyle(Theme.faint)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated && !reduceMotion {
                withAnimation(.easeOut(duration: 0.9).delay(0.1)) { shown = Double(value) }
            } else {
                shown = Double(value)
            }
        }
        .onChange(of: value) { _, newValue in
            if reduceMotion {
                shown = Double(newValue)
            } else {
                withAnimation(.easeOut(duration: 0.5)) { shown = Double(newValue) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label ?? "Score"): \(value) out of 100")
    }
}

/// Small ring + caption combo used in metric rows.
struct MetricRing: View {
    let value: Int
    let label: String
    let detail: String
    var tone: Tone = .gold

    var body: some View {
        Card {
            HStack(spacing: 12) {
                ScoreRing(value: value, size: 62, lineWidth: 6, tone: tone)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.3)
                        .foregroundStyle(Theme.muted)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.creamDim)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
