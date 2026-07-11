import SwiftUI

struct RecoverHomeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                SectionHeader(eyebrow: "Recover", title: "Recovery & Sleep",
                              subtitle: "HRV, RHR, sleep stages, debt, strain — synthesized into one readiness call.")

                heroCard
                trendsCard
                sleepCard
                navLinks
            }
            .navigationBarHidden(true)
        }
    }

    /// One dominant number; the story beneath it.
    private var heroCard: some View {
        let d = app.recovery.today
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(d.recovery)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.gold)
                Text("Recovery today · HRV \(d.hrv) ms · sleep \(String(format: "%.1f", d.sleep.hours)) h")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private var ringsRow: some View {
        let d = app.recovery.today
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricRing(value: d.recovery, label: "Recovery", detail: "WHOOP-weighted blend", tone: .green)
            MetricRing(value: d.sleepScore, label: "Sleep Score",
                       detail: String(format: "%.1f h total", d.sleep.hours), tone: .royal)
            MetricRing(value: min(100, Int(Double(d.hrv) / Double(d.hrvBaseline) * 100)),
                       label: "HRV", detail: "\(d.hrv) ms vs \(d.hrvBaseline) baseline", tone: .gold)
            MetricRing(value: d.readiness.percent, label: "Readiness",
                       detail: "\(d.readiness.rawValue) · RHR \(d.restingHR)", tone: d.readiness.tone)
        }
    }

    private var sleepCard: some View {
        let s = app.recovery.today.sleep
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Last Night · \(s.bedtime) – \(s.waketime)")
                    Spacer()
                    Chip(text: String(format: "%.1f h", s.hours), tone: .royal)
                }
                SleepStageBar(stages: s.stages)
                HStack(spacing: 14) {
                    StatTile(label: "Deep", value: String(format: "%.1f", s.deepHours), unit: "h", hint: "target 1.5+")
                    StatTile(label: "REM", value: String(format: "%.1f", s.remHours), unit: "h", hint: "target 1.7+")
                    StatTile(label: "Light", value: String(format: "%.1f", s.lightHours), unit: "h")
                    StatTile(label: "Awake", value: String(format: "%.1f", s.awakeHours), unit: "h")
                }
            }
        }
    }

    private var debtCard: some View {
        let d = app.recovery.today
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    StatTile(label: "Sleep debt · 7d",
                             value: String(format: "%.1f", d.sleepDebtHours), unit: "h",
                             tone: d.sleepDebtHours > 4 ? .ruby : .amber)
                    StatTile(label: "Strain yesterday",
                             value: String(format: "%.1f", d.strainYesterday), unit: "/ 21")
                    StatTile(label: "Strain today",
                             value: String(format: "%.1f", d.strainToday), unit: "/ 21", tone: .green)
                }
                CoachNote(text: "You're 3.1 h behind this week. At 21, your ceiling is 8.5–9 h — that single change moves recovery, HRV, testosterone, and the bench plateau at once. Lights out 22:30.")
            }
        }
    }

    private var trendsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                EyebrowLabel(text: "14-Day Trends")
                ForEach(app.recovery.trends) { trend in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(trend.name).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.creamDim)
                            Spacer()
                            Text("\(String(format: "%g", trend.latest)) \(trend.unit)")
                                .font(.system(size: 11.5)).foregroundStyle(Theme.gold)
                        }
                        Sparkline(values: trend.values,
                                  color: trend.name == "Strain" ? Theme.amber : Theme.gold,
                                  height: 34)
                    }
                }
            }
        }
    }

    private var navLinks: some View {
        VStack(spacing: 10) {
            NavRow(icon: "applewatch.radiowaves.left.and.right", title: "Wearable Hub",
                   subtitle: "\(app.recovery.connectedCount) of \(app.recovery.wearables.count) connected · HealthKit ready") { WearablesView() }
            NavRow(icon: "cross.case.fill", title: "Forge Recovery — Injury & PT",
                   subtitle: "Knee rehab day 12 · risk \(app.injuries.risk.percent)%") { ForgeRecoveryView() }
        }
    }
}
