import SwiftUI

struct MicronutrientsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Fuel · Micros", title: "Micronutrients",
                          subtitle: "7-day rolling averages vs. targets, derived from your logged intake.")

            if app.nutrition.nutrientGroups.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No micronutrient data yet",
                    message: "Micronutrient averages build from your logged meals and bloodwork. Keep logging intake and add your labs, and your vitamin and mineral coverage fills in here.")
            }

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

            // The narrative gap-callout is demo-only — it references Sean's fixed
            // mock micronutrient data. A real account's coaching comes from the
            // Deficiencies screen, derived from its own bloodwork.
            if app.isDemoAccount {
                CoachNote(text: "Magnesium (52%), Vitamin D (41%), and Omega-3 (34%) are your three real gaps — everything else is noise. See Deficiencies for the fix list.")
            }
        }
        .navigationTitle("Micronutrients")
        .navigationBarTitleDisplayMode(.inline)
    }
}
