import SwiftUI

/// The consistent "why should I trust this?" surface for any Forge recommendation.
/// Collapsed, it shows confidence + freshness; expanded, the inputs it used, what
/// was missing, and the safe fallback. Reusable across the Forge Score, Directive,
/// and any future recommendation so they all explain themselves the same way.
struct RecommendationBasisView: View {
    let basis: RecommendationBasis
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").font(.system(size: 11)).foregroundStyle(Theme.muted)
                    Text("Confidence: \(basis.confidence.rawValue)")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(confidenceColor)
                    Text("· as of \(basis.asOf.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10)).foregroundStyle(Theme.faint)
                    Spacer(minLength: 0)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9)).foregroundStyle(Theme.faint)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Why this recommendation. Confidence \(basis.confidence.rawValue).")
            .accessibilityHint(expanded ? "Collapses the details" : "Expands inputs used and missing")

            if expanded {
                if !basis.inputsUsed.isEmpty {
                    labeledRow("Based on", basis.inputsUsed.joined(separator: " · "), tone: Theme.creamDim)
                }
                if !basis.inputsMissing.isEmpty {
                    labeledRow("Missing", basis.inputsMissing.joined(separator: " · "), tone: Theme.amber)
                }
                if let fallback = basis.safeFallback {
                    Text(fallback)
                        .font(.system(size: 10.5)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var confidenceColor: Color {
        switch basis.confidence {
        case .high:     return Theme.green
        case .moderate: return Theme.gold
        case .low:      return Theme.amber
        }
    }

    private func labeledRow(_ title: String, _ value: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .semibold)).kerning(1).foregroundStyle(Theme.faint)
            Text(value)
                .font(.system(size: 10.5)).foregroundStyle(tone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
