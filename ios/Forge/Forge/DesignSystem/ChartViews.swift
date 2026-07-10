import SwiftUI
import Charts

/// Minimal gold sparkline with area fill.
struct Sparkline: View {
    let values: [Double]
    var color: Color = Theme.gold
    var height: CGFloat = 44

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { item in
            LineMark(x: .value("Day", item.offset), y: .value("Value", item.element))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
            AreaMark(x: .value("Day", item.offset), y: .value("Value", item.element))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: [color.opacity(0.22), color.opacity(0.0)],
                                   startPoint: .top, endPoint: .bottom)
                )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .frame(height: height)
        // AreaMark fills toward the zero position, which sits far below a
        // non-zero domain — clip to the frame so the wash can't bleed into
        // whatever is rendered underneath.
        .clipped()
    }

    private var yDomain: ClosedRange<Double> {
        guard let lo = values.min(), let hi = values.max(), hi > lo else { return 0...1 }
        let pad = (hi - lo) * 0.15
        return (lo - pad)...(hi + pad)
    }
}

/// Vertical bar trend (strain, volume, etc.).
struct BarTrend: View {
    let values: [Double]
    var color: Color = Theme.gold
    var height: CGFloat = 56

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { item in
            BarMark(x: .value("Day", item.offset), y: .value("Value", item.element), width: .ratio(0.55))
                .foregroundStyle(color.opacity(0.35 + 0.6 * Double(item.offset) / Double(max(1, values.count))))
                .cornerRadius(2)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}

/// Horizontal stacked sleep-stage bar.
struct SleepStageBar: View {
    let stages: [SleepStageSlice]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 1.5) {
                    ForEach(stages) { s in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(s.stage.color)
                            .frame(width: max(2, geo.size.width * s.fraction(of: total) - 1.5))
                    }
                }
            }
            .frame(height: 36)

            HStack(spacing: 12) {
                legend(.deep); legend(.rem); legend(.light); legend(.awake)
            }
        }
    }

    private var total: Double { stages.reduce(0) { $0 + $1.hours } }

    private func legend(_ stage: SleepStage) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(stage.color).frame(width: 8, height: 8)
            Text(stage.label).font(.system(size: 10)).foregroundStyle(Theme.muted)
        }
    }
}

struct SleepStageSlice: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let hours: Double

    func fraction(of total: Double) -> Double {
        total > 0 ? hours / total : 0
    }
}

enum SleepStage {
    case deep, rem, light, awake

    var color: Color {
        switch self {
        case .deep: return Theme.royal
        case .rem: return Theme.gold.opacity(0.8)
        case .light: return Theme.faint
        case .awake: return Theme.ruby
        }
    }

    var label: String {
        switch self {
        case .deep: return "Deep"
        case .rem: return "REM"
        case .light: return "Light"
        case .awake: return "Awake"
        }
    }
}
