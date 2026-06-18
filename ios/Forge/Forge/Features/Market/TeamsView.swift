import SwiftUI

struct TeamsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Forge Teams", title: "Squad Dashboards",
                          subtitle: "Schools, gyms, sports teams, businesses — coach view with recovery and compliance at a glance.")

            ForEach(app.social.teams) { team in
                Card {
                    VStack(alignment: .leading, spacing: 11) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(team.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.cream)
                                Text("\(team.kind) · \(team.members) athletes")
                                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Chip(text: "Avg Forge \(team.avgForgeScore)", tone: .gold)
                        }

                        LabeledBar(label: "Team compliance · 30d", valueText: "\(team.compliancePct)%",
                                   value: Double(team.compliancePct), target: 100,
                                   tone: team.compliancePct >= 85 ? .green : .amber)

                        HStack(spacing: 10) {
                            teamStat("At risk", "\(team.atRisk)", tone: team.atRisk > 5 ? .ruby : .amber)
                            teamStat("In rehab", "\(team.inRehab)", tone: .amber)
                            teamStat("PRs this wk", "\(team.prsThisWeek)", tone: .green)
                        }

                        HStack(spacing: 10) {
                            ComingSoonButton("Coach view", feature: "Coach dashboards")
                            ComingSoonButton("Team challenge", feature: "Team challenges")
                            Spacer()
                        }
                    }
                }
            }

            ComingSoonButton("+ Create a Team", feature: "Team creation", compact: false, gold: true)
        }
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func teamStat(_ label: String, _ value: String, tone: Tone) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.display(17)).foregroundStyle(tone.color)
            Text(label.uppercased()).font(.system(size: 7.5, weight: .semibold)).kerning(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgElevated))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
    }
}
