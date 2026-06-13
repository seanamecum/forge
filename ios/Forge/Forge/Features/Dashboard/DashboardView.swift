import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                header
                TodaysDirectiveCard()
                ForgeScoreHero()
                metricRow
                TodaysWorkoutCard()
                FuelCard()
                InjuryRiskCard()
                WearableStatusStrip()
                ModulesGrid()
                DisclaimerNote()
            }
            .navigationBarHidden(true)
            .onAppear {
                // Snapshot today's Forge Score so trends build from real history.
                PersistenceService.recordTodayScore(app.forgeScore, context: modelContext)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            NavigationLink { ProfileView() } label: {
                ZStack {
                    Circle().fill(Theme.goldGradient)
                    Text(app.user.initials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.bg)
                }
                .frame(width: 38, height: 38)
            }
            .accessibilityLabel("Profile and settings")

            VStack(alignment: .leading, spacing: 1) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()).uppercased())
                    .font(Theme.eyebrow(9))
                    .kerning(1.6)
                    .foregroundStyle(Theme.faint)
                Text("Good morning, \(app.user.name.split(separator: " ").first.map(String.init) ?? app.user.name)")
                    .font(Theme.display(19))
                    .foregroundStyle(Theme.cream)
            }

            Spacer()

            NavigationLink { NotificationsView() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.creamDim)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.card))
                        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    if app.notifications.unreadCount > 0 {
                        Text("\(app.notifications.unreadCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.cream)
                            .frame(width: 15, height: 15)
                            .background(Circle().fill(Theme.ruby))
                            .offset(x: 3, y: -2)
                    }
                }
            }
            .accessibilityLabel(app.notifications.unreadCount > 0
                ? "Notifications, \(app.notifications.unreadCount) unread"
                : "Notifications")
        }
        .padding(.top, 6)
    }

    private var metricRow: some View {
        let d = app.recovery.today
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricRing(value: d.recovery, label: "Recovery",
                       detail: "HRV \(d.hrv) ms (\(d.hrvDelta >= 0 ? "+" : "")\(d.hrvDelta))",
                       tone: .green)
            MetricRing(value: d.sleepScore, label: "Sleep",
                       detail: String(format: "%.1f h · %.1f deep", d.sleep.hours, d.sleep.deepHours),
                       tone: .royal)
            MetricRing(value: d.readiness.percent, label: "Readiness",
                       detail: d.readiness.rawValue, tone: d.readiness.tone)
            MetricRing(value: max(0, 100 - app.injuries.risk.percent * 2), label: "Resilience",
                       detail: "Injury risk \(app.injuries.risk.percent)%",
                       tone: app.injuries.risk.percent > 35 ? .ruby : .amber)
        }
    }
}
