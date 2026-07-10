import SwiftUI

// MARK: - Dashboard card

/// Compact weekly recap on the command center — verdict, three numbers, and
/// next week's single focus. Tapping opens the full report.
struct WeeklyReportCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let report = app.weeklyReport
        return NavigationLink {
            WeeklyReportView()
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        EyebrowLabel(text: "Your Week · Rolling 7-Day Recap")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.faint)
                    }

                    Text(report.verdict)
                        .font(Theme.display(19))
                        .foregroundStyle(Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 14) {
                        StatTile(label: "Recovery avg",
                                 value: "\(report.recoveryAvg)",
                                 hint: report.recoveryDelta == 0 ? "level"
                                     : (report.recoveryDelta > 0 ? "+\(report.recoveryDelta) vs last wk" : "\(report.recoveryDelta) vs last wk"),
                                 tone: report.recoveryDelta >= 0 ? .green : .amber)
                        StatTile(label: "Sleep avg",
                                 value: String(format: "%.1f", report.sleepAvgHours), unit: "h")
                        StatTile(label: "Sleep debt",
                                 value: String(format: "%.1f", report.sleepDebtHours), unit: "h",
                                 tone: report.sleepDebtHours >= 3 ? .ruby : .neutral)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold)
                            .padding(.top, 2)
                        Text(report.nextFocus)
                            .font(Theme.text(12.5, .medium))
                            .foregroundStyle(Theme.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weekly report. \(report.verdict) \(report.nextFocus)")
    }
}

// MARK: - Full report

struct WeeklyReportView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let report = app.weeklyReport
        ScreenScaffold {
            SectionHeader(eyebrow: "Rolling 7-Day Recap", title: "Your Week",
                          subtitle: "The week in one read: what improved, what slipped, and the single change that pays off most next week.")

            Card(gold: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(report.verdict)
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 14) {
                        StatTile(label: "Recovery",
                                 value: "\(report.recoveryAvg)",
                                 hint: report.recoveryDelta >= 0 ? "+\(report.recoveryDelta) wk/wk" : "\(report.recoveryDelta) wk/wk",
                                 tone: report.recoveryDelta >= 0 ? .green : .amber)
                        StatTile(label: "HRV",
                                 value: report.hrvDelta >= 0 ? "+\(report.hrvDelta)" : "\(report.hrvDelta)",
                                 unit: "ms wk/wk",
                                 tone: report.hrvDelta >= 0 ? .green : .amber)
                        StatTile(label: "Strain avg",
                                 value: String(format: "%.1f", report.strainAvg), unit: "/21")
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    EyebrowLabel(text: "Recovery · 14 days")
                    Sparkline(values: app.recovery.trends.first { $0.name == "Recovery" }?.values ?? [], height: 44)
                    EyebrowLabel(text: "Sleep · 14 days")
                    Sparkline(values: app.recovery.trends.first { $0.name == "Sleep" }?.values ?? [], height: 44)
                    HStack {
                        Chip(text: "Sleep \(report.sleepConsistency)",
                             tone: report.sleepConsistency == "Steady" ? .green : .amber)
                        Chip(text: String(format: "%.1fh debt", report.sleepDebtHours),
                             tone: report.sleepDebtHours >= 3 ? .ruby : .neutral)
                        Spacer()
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    EyebrowLabel(text: "What Went Right", tone: .green)
                    ForEach(report.wins, id: \.self) { win in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.green)
                                .padding(.top, 3)
                            Text(win)
                                .font(Theme.text(13))
                                .foregroundStyle(Theme.creamDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if !report.watchouts.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        EyebrowLabel(text: "Watch-Outs", tone: .amber)
                        ForEach(report.watchouts, id: \.self) { item in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.amber)
                                    .padding(.top, 3)
                                Text(item)
                                    .font(Theme.text(13))
                                    .foregroundStyle(Theme.creamDim)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            Card(gold: true) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "scope")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        EyebrowLabel(text: "Next Week's One Focus")
                        Text(report.nextFocus)
                            .font(Theme.text(14, .medium))
                            .foregroundStyle(Theme.cream)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
