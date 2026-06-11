import SwiftUI

struct SupplementsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Fuel · Stack", title: "Supplements",
                          subtitle: "Streaks build the habit. Forge ties gaps here to your sleep, HRV, and fatigue.")

            ForEach(app.nutrition.supplements) { s in
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.cream)
                                Text("\(s.dose) · \(s.timing)").font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Button {
                                app.nutrition.toggleSupplement(s)
                            } label: {
                                Image(systemName: s.loggedToday ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 26))
                                    .foregroundStyle(s.loggedToday ? Theme.green : Theme.faint.opacity(0.5))
                            }
                        }
                        Text(s.benefit).font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        HStack {
                            Image(systemName: "flame.fill").font(.system(size: 10)).foregroundStyle(Theme.gold)
                            Text("\(s.streak)-day streak")
                                .font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.gold)
                            Spacer()
                            if !s.loggedToday {
                                Text("Pending today").font(.system(size: 10.5)).foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Supplements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
