import SwiftUI

struct MicronutrientsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Fuel · Micros", title: "Micronutrients",
                          subtitle: "13 vitamins · 13 minerals · 9 advanced — 7-day rolling averages vs. targets.")

            ForEach(app.nutrition.nutrientGroups) { group in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        EyebrowLabel(text: group.name)
                        ForEach(group.items) { item in
                            HStack(spacing: 10) {
                                Text(item.name)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.creamDim)
                                    .frame(width: 118, alignment: .leading)
                                CapsuleBar(value: Double(min(item.percentOfTarget, 150)), target: 150,
                                           tone: item.tone, height: 5)
                                Text("\(item.percentOfTarget)%")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(item.tone.color)
                                    .frame(width: 42, alignment: .trailing)
                            }
                        }
                    }
                }
            }

            CoachNote(text: "Magnesium (52%), Vitamin D (41%), and Omega-3 (34%) are your three real gaps — everything else is noise. See Deficiencies for the fix list.")
        }
        .navigationTitle("Micronutrients")
        .navigationBarTitleDisplayMode(.inline)
    }
}
