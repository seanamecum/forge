import SwiftUI

/// Pure ring geometry — extracted so the fill/over logic is testable without a
/// live view. Views below read straight from this; nothing else computes fill.
enum RingMath {
    /// Fraction of the ring to fill for `value` of `target`, clamped to [0, 1].
    /// A zero/negative target reads as empty (we never fabricate a full ring).
    static func fill(_ value: Int, of target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(max(Double(value) / Double(target), 0), 1)
    }

    /// True when intake has passed the target (so the ring can warn in amber).
    static func isOver(_ value: Int, target: Int) -> Bool {
        target > 0 && value > target
    }
}

/// The hero of the nutrition screen — a big calorie ring with the remaining
/// calories counting up in its center, and three macro dials (protein, carbs,
/// fat) that sweep to fill on appear in a staggered cascade. This is the
/// 30-second-screen-recording moment: motion, gradient sweep, glow, live number.
struct MacroRings: View {
    let calories: Int
    let calorieTarget: Int
    let protein: Int
    let proteinTarget: Int
    let carbs: Int
    let carbTarget: Int
    let fat: Int
    let fatTarget: Int

    var body: some View {
        VStack(spacing: 20) {
            CalorieRing(calories: calories, target: calorieTarget)
            HStack(spacing: 10) {
                MacroDial(label: "Protein", value: protein, target: proteinTarget, tone: .green, delay: 0.08)
                MacroDial(label: "Carbs", value: carbs, target: carbTarget, tone: .gold, delay: 0.15)
                MacroDial(label: "Fat", value: fat, target: fatTarget, tone: .amber, delay: 0.22)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calorie ring

/// Big gold ring. Center shows how many calories are LEFT (what people actually
/// act on), counting up on appear; over-target flips to amber and "kcal over".
struct CalorieRing: View {
    let calories: Int
    let target: Int
    var delay: Double = 0

    @State private var shownProgress: Double = 0
    @State private var shownNumber: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remaining: Int { target - calories }
    private var over: Bool { RingMath.isOver(calories, target: target) }
    private var progress: Double { RingMath.fill(calories, of: target) }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.gold.opacity(0.08), lineWidth: 14)

            Circle()
                .trim(from: 0, to: shownProgress)
                .stroke(
                    AngularGradient(
                        colors: over ? [Theme.amber.opacity(0.55), Theme.amber]
                                     : [Theme.goldDeep, Theme.gold, Theme.goldBright],
                        center: .center, startAngle: .degrees(0), endAngle: .degrees(345)),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: (over ? Theme.amber : Theme.gold).opacity(0.5), radius: 8)

            VStack(spacing: 3) {
                CountingNumber(value: shownNumber)
                    .font(Theme.display(44))
                    .foregroundStyle(over ? AnyShapeStyle(Theme.amber) : AnyShapeStyle(Theme.goldGradient))
                    .monospacedDigit()
                Text(over ? "KCAL OVER" : "KCAL LEFT")
                    .font(.system(size: 10, weight: .semibold)).kerning(1.6)
                    .foregroundStyle(Theme.muted)
                Text("\(calories) / \(target)")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint).monospacedDigit()
            }
        }
        .frame(width: 208, height: 208)
        .onAppear { reveal() }
        .onChange(of: calories) { _, _ in reveal() }
        .onChange(of: target) { _, _ in reveal() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(over ? "\(abs(remaining)) calories over target"
                                 : "\(remaining) calories left of \(target)")
    }

    private func reveal() {
        let number = Double(abs(remaining))
        guard !reduceMotion else { shownProgress = progress; shownNumber = number; return }
        withAnimation(.easeOut(duration: 0.95).delay(delay)) {
            shownProgress = progress
            shownNumber = number
        }
    }
}

// MARK: - Macro dial

/// A compact macro ring — grams in the center, name + target beneath — that
/// sweeps to fill on appear and warns amber when you've gone over.
struct MacroDial: View {
    let label: String
    let value: Int
    let target: Int
    var tone: Tone = .gold
    var delay: Double = 0

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { RingMath.fill(value, of: target) }
    private var over: Bool { RingMath.isOver(value, target: target) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(tone.color.opacity(0.10), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(
                        AngularGradient(colors: [tone.color.opacity(0.55), tone.color],
                                        center: .center, startAngle: .degrees(0), endAngle: .degrees(330)),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tone.color.opacity(0.4), radius: 4)

                VStack(spacing: -1) {
                    Text("\(value)")
                        .font(Theme.display(18))
                        .foregroundStyle(over ? Theme.amber : Theme.cream)
                        .monospacedDigit()
                    Text("g").font(.system(size: 8.5, weight: .semibold)).foregroundStyle(Theme.faint)
                }
            }
            .frame(width: 76, height: 76)

            VStack(spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold)).kerning(1.1)
                    .foregroundStyle(Theme.muted)
                Text("\(value) / \(target)g")
                    .font(.system(size: 9.5)).foregroundStyle(Theme.faint).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { reveal() }
        .onChange(of: value) { _, _ in reveal() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) of \(target) grams")
    }

    private func reveal() {
        guard !reduceMotion else { shown = progress; return }
        withAnimation(.easeOut(duration: 0.85).delay(delay)) { shown = progress }
    }
}

// MARK: - Counting number

/// An odometer number that SwiftUI interpolates frame-by-frame while its value
/// animates — the count-up in the calorie ring's center.
private struct CountingNumber: View, Animatable {
    var value: Double
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    var body: some View {
        Text("\(Int(value.rounded()))")
    }
}
