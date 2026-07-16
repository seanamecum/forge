import SwiftUI

struct FormAnalysisView: View {
    @State private var lift = "Squat"
    @State private var analyzing = false
    @State private var analyzed = false

    private let lifts = ["Squat", "Bench Press", "Deadlift"]

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Train · Vision AI", title: "Form Analysis",
                          subtitle: "Live video scoring is in development. Preview the report format with sample data below.")

            FlowChips(options: lifts,
                      isSelected: { $0 == lift },
                      toggle: { lift = $0; analyzed = false })

            uploadCard

            if analyzing { analyzingCard }
            if analyzed, let result = FormResult.results[lift] {
                FormResultCard(result: result)
            }

            DisclaimerNote(text: "The report below is SAMPLE DATA showing what form analysis will look like — it is not scoring your lifts yet. Sharp pain during a lift means stop.")
        }
        .navigationTitle("Form Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var uploadCard: some View {
        Card {
            VStack(spacing: 12) {
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.gold.opacity(0.7))
                Text("Video analysis — in development")
                    .font(Theme.display(17)).foregroundStyle(Theme.cream)
                Text("When live: side angle · 2–5 reps · good lighting")
                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                Button(analyzing ? "Loading sample…" : "See a sample \(lift.lowercased()) report") {
                    analyzed = false
                    analyzing = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(1500))
                        analyzing = false
                        analyzed = true
                    }
                }
                .buttonStyle(GoldButtonStyle(compact: true))
                .disabled(analyzing)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private var analyzingCard: some View {
        Card {
            HStack(spacing: 10) {
                ProgressView().tint(Theme.gold)
                Text("Loading sample report…")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FormResult {
    let score: Int
    let good: [String]
    let mistakes: [String]
    let corrections: [String]

    static let results: [String: FormResult] = [
        "Squat": FormResult(
            score: 87,
            good: ["Depth to parallel ✓", "Back angle consistent ✓", "Heels planted throughout ✓"],
            mistakes: ["Slight right-knee cave at the bottom (~6°)"],
            corrections: ["Cue 'spread the floor' through the ascent",
                          "Pre-activate glute med: 2 × 15 clamshells before main sets",
                          "Worth noting given the patellar tendon — keep tempo controlled at the turn"]),
        "Bench Press": FormResult(
            score: 82,
            good: ["Bar path stacked over shoulders ✓", "Elbow angle ~60° — textbook ✓"],
            mistakes: ["Leg drive weak — hips active on only 2 of 5 reps"],
            corrections: ["Set feet before unrack and drive the floor away on every rep",
                          "Think 'push yourself into the bench', not just 'push the bar'",
                          "This is likely worth 5–10 lb at your top end — relevant to the plateau"]),
        "Deadlift": FormResult(
            score: 90,
            good: ["Bar path vertical over mid-foot ✓", "Lockout strong, no hitch ✓"],
            mistakes: ["Slight low-back rounding on the final rep"],
            corrections: ["End sets one rep before brace failure",
                          "Re-set breath and wedge between every rep on top sets"]),
    ]
}

struct FormResultCard: View {
    let result: FormResult

    var body: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    ScoreRing(value: result.score, label: "Form", size: 84, lineWidth: 8)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.score >= 88 ? "Excellent" : result.score >= 80 ? "Strong" : "Needs work")
                            .font(Theme.display(20)).foregroundStyle(Theme.cream)
                        Text("Sample report — video scoring in development")
                            .font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                }

                resultSection("What you did well", items: result.good, tone: .green, symbol: "checkmark")
                resultSection("Mistakes", items: result.mistakes, tone: .ruby, symbol: "xmark")
                resultSection("Corrections", items: result.corrections, tone: .gold, symbol: "sparkles")
            }
        }
    }

    private func resultSection(_ title: String, items: [String], tone: Tone, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            EyebrowLabel(text: title, tone: tone)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(tone.color)
                        .padding(.top, 3)
                    Text(item)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.creamDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
