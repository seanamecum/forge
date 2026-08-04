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
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Theme.creamDim)
                                    .frame(width: 118, alignment: .leading)
                                CapsuleBar(value: Double(min(item.percentOfTarget, 150)), target: 150,
                                           tone: item.tone, height: 5)
                                Text("\(item.percentOfTarget)%")
                                    .font(Typography.footnote.weight(.semibold))
                                    .foregroundStyle(item.tone.color)
                                    .frame(width: 42, alignment: .trailing)
                            }
                        }
                    }
                }
            }

            coaching
        }
        .navigationTitle("Micronutrients")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { app.refreshMicronutrients() }
    }

    /// Honest, data-driven coaching. Demo keeps its narrative; a real account gets
    /// its actual lowest micros plus a note on why coverage may look low.
    @ViewBuilder
    private var coaching: some View {
        if app.isDemoAccount {
            CoachNote(text: "Magnesium (52%), Vitamin D (41%), and Omega-3 (34%) are your three real gaps — everything else is noise. See Deficiencies for the fix list.")
        } else if !app.nutrition.nutrientGroups.isEmpty {
            let gaps = MicronutrientEngine.gaps(in: app.nutrition.nutrientGroups)
            if !gaps.isEmpty {
                CoachNote(text: "Lowest right now: " +
                          gaps.prefix(3).map { "\($0.name) (\($0.percentOfTarget)%)" }.joined(separator: ", ") +
                          ". Foods rich in these help close the gap.")
            }
            Text("Averaged over foods with known values — coverage fills in as more logged foods carry full labels.")
                .font(Typography.caption)
                .foregroundStyle(Theme.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
