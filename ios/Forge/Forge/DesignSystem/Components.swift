import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    var gold = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(gold ? Theme.gold.opacity(0.22) : Theme.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.display(28))
                .foregroundStyle(Theme.cream)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
            }
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EyebrowLabel: View {
    let text: String
    var tone: Tone = .gold

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tone == .gold ? Theme.creamDim : tone.color)
    }
}

// MARK: - Chip

struct Chip: View {
    let text: String
    var tone: Tone = .neutral

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(tone == .neutral ? Theme.creamDim : tone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tone == .neutral ? Color.white.opacity(0.06) : tone.color.opacity(0.10)))
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let label: String
    let value: String
    var unit: String? = nil
    var hint: String? = nil
    var tone: Tone = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.display(24))
                    .foregroundStyle(tone == .neutral ? Theme.cream : tone.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
            if let hint {
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.faint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Buttons

struct GoldButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .kerning(0.8)
            .foregroundStyle(Theme.bg)
            .padding(.vertical, compact ? 9 : 13)
            .padding(.horizontal, compact ? 16 : 22)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(Capsule().fill(Theme.goldGradient))
            .shadow(color: Theme.gold.opacity(0.18), radius: 8, y: 2)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 14, weight: .medium))
            .foregroundStyle(Theme.cream)
            .padding(.vertical, compact ? 9 : 13)
            .padding(.horizontal, compact ? 16 : 22)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.10 : 0.05)))
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

// MARK: - Progress bar

struct CapsuleBar: View {
    let value: Double
    let target: Double
    var tone: Tone = .gold
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.gold.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(colors: [tone.color.opacity(0.9), tone.color.opacity(0.55)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, geo.size.width * progress))
                    .shadow(color: tone.color.opacity(0.4), radius: 4)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.6), value: value)
    }

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(1, value / target))
    }
}

struct LabeledBar: View {
    let label: String
    let valueText: String
    let value: Double
    let target: Double
    var tone: Tone = .gold

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 12)).foregroundStyle(Theme.muted)
                Spacer()
                Text(valueText).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.creamDim)
            }
            CapsuleBar(value: value, target: target, tone: tone, height: 7)
        }
    }
}

// MARK: - Rows & notes

struct InfoRow: View {
    let label: String
    let value: String
    var valueTone: Tone = .neutral

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(valueTone.color)
        }
        .padding(.vertical, 6)
        .overlay(Rectangle().fill(Theme.gold.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }
}

struct CoachNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Theme.gold)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.creamDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.gold.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.gold.opacity(0.18), lineWidth: 1))
    }
}

struct DisclaimerNote: View {
    var text = "Forge provides educational guidance, not medical advice. For serious symptoms — chest pain, neurological signs, severe pain or swelling, inability to bear weight, or any head injury — see a licensed physician or physical therapist."

    var body: some View {
        Text(text)
            .font(.system(size: 10.5))
            .foregroundStyle(Theme.faint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
    }
}

// MARK: - Screen scaffold

struct ScreenScaffold<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 110) // clear the floating tab bar
        }
        .background(Theme.bg)
        .scrollContentBackground(.hidden)
    }
}
