import SwiftUI

struct DeficienciesView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Fuel · AI Detection", title: "Deficiencies",
                          subtitle: "Cross-referenced against intake, training load, bloodwork, and sleep — only real signal surfaces here.")

            ForEach(app.nutrition.deficiencies) { d in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(d.nutrient).font(Theme.display(19)).foregroundStyle(Theme.cream)
                            Spacer()
                            Chip(text: d.severity.rawValue, tone: d.severity.tone)
                        }
                        HStack(spacing: 16) {
                            StatTile(label: "Current avg", value: d.current, tone: d.severity.tone)
                            StatTile(label: "Target", value: d.target)
                            StatTile(label: "Days low", value: "\(d.daysLow)", tone: d.daysLow > 7 ? .ruby : .amber)
                        }
                        CoachNote(text: d.recommendation)
                    }
                }
            }

            DisclaimerNote(text: "Deficiency detection is educational guidance from logged intake — not a diagnosis. Confirm with bloodwork and consult a dietitian or physician before major supplementation, especially alongside medication.")
        }
        .navigationTitle("Deficiencies")
        .navigationBarTitleDisplayMode(.inline)
    }
}
