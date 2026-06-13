import SwiftUI
import SwiftData

/// A 10-second morning check-in. Cheap subjective input that personalizes the
/// directive and the coach for the rest of the day. Persists to SwiftData for
/// trends; mirrors an in-memory snapshot into AppState so the directive can read it
/// without a model context.
struct CheckInSnapshot: Equatable {
    var sleepQuality: Int   // 1–5
    var soreness: Int       // 0–10
    var energy: Int         // 1–5
    var stress: Int         // 1–5

    var coachNote: String {
        "Morning check-in — sleep quality \(sleepQuality)/5, soreness \(soreness)/10, energy \(energy)/5, stress \(stress)/5."
    }
}

struct MorningCheckInView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var sleepQuality = 3
    @State private var soreness = 2
    @State private var energy = 3
    @State private var stress = 2

    var body: some View {
        ZStack {
            Theme.bgElevated.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule().fill(Theme.faint.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 4) {
                        EyebrowLabel(text: "10 seconds")
                        Text("Morning Check-In")
                            .font(Theme.display(28)).foregroundStyle(Theme.cream)
                        Text("How you actually feel tunes today's directive and the coach.")
                            .font(.system(size: 13)).foregroundStyle(Theme.muted)
                    }

                    scale("Sleep quality", value: $sleepQuality, range: 1...5,
                          low: "Awful", high: "Perfect", invert: false)
                    scale("Soreness", value: $soreness, range: 0...10,
                          low: "None", high: "Severe", invert: true)
                    scale("Energy", value: $energy, range: 1...5,
                          low: "Drained", high: "Wired", invert: false)
                    scale("Stress", value: $stress, range: 1...5,
                          low: "Calm", high: "Maxed", invert: true)

                    Button("Save Check-In") { save() }
                        .buttonStyle(GoldButtonStyle())
                        .padding(.top, 4)

                    DisclaimerNote(text: "Subjective check-ins are signals, not diagnoses. Persistent fatigue, pain, or low mood deserves a conversation with a clinician.")
                }
                .padding(20)
            }
        }
        .presentationDetents([.large])
    }

    private func scale(_ label: String, value: Binding<Int>, range: ClosedRange<Int>,
                       low: String, high: String, invert: Bool) -> some View {
        let v = value.wrappedValue
        let frac = Double(v - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        let good = invert ? (1 - frac) : frac
        let tone: Tone = good >= 0.66 ? .green : (good >= 0.33 ? .amber : .ruby)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.cream)
                Spacer()
                Text("\(v)").font(Theme.display(18)).foregroundStyle(tone.color)
            }
            Slider(value: Binding(get: { Double(v) }, set: { value.wrappedValue = Int($0.rounded()) }),
                   in: Double(range.lowerBound)...Double(range.upperBound),
                   step: 1)
                .tint(tone.color)
            HStack {
                Text(low).font(.system(size: 10)).foregroundStyle(Theme.faint)
                Spacer()
                Text(high).font(.system(size: 10)).foregroundStyle(Theme.faint)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 13).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.hairline, lineWidth: 1))
    }

    private func save() {
        let snap = CheckInSnapshot(sleepQuality: sleepQuality, soreness: soreness,
                                   energy: energy, stress: stress)
        app.checkIn = snap
        context.insert(CheckInRecord(date: .now, sleepQuality: sleepQuality,
                                     soreness: soreness, energy: energy, stress: stress))
        try? context.save()
        dismiss()
    }
}
