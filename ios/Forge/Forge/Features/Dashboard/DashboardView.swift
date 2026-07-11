import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                header
                MorningCheckInCard()
                heroCard
                todayCard
                ModulesGrid()
                DisclaimerNote()
            }
            .navigationBarHidden(true)
            .onAppear {
                app.refreshFuelPlan()
                app.publishWidgetSnapshot()
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
                Text("Good \(Daypart.now.lowercased()), \(app.user.name.split(separator: " ").first.map(String.init) ?? app.user.name)")
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

    /// The one number that matters, dominating the screen.
    private var heroCard: some View {
        let directive = app.dailyDirective
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.forgeScore)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.cream)
                    Text("Forge Score")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
                Sparkline(values: app.recovery.forgeScoreTrend, height: 72)
                Text(directive.headline)
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.creamDim)
            }
        }
    }

    /// Today, in three quiet rows + the single priority.
    private var todayCard: some View {
        let directive = app.dailyDirective
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                ForEach(directive.actions.prefix(3)) { action in
                    HStack(spacing: 12) {
                        Image(systemName: action.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.creamDim)
                            .frame(width: 22)
                        Text(action.value)
                            .font(Theme.text(14))
                            .foregroundStyle(Theme.cream)
                        Spacer()
                    }
                }
                Divider().overlay(Theme.hairline)
                Text(directive.priorityAction)
                    .font(Theme.text(13, .medium))
                    .foregroundStyle(Theme.gold)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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

// MARK: - Quick actions

/// Four circular one-tap actions under the greeting — the reference-style
/// "do the thing now" row. Big targets, zero navigation depth.
private struct QuickActionsRow: View {
    @Environment(AppState.self) private var app
    @State private var waterLogged = false

    var body: some View {
        HStack(spacing: 0) {
            actionButton("dumbbell.fill", "Workout") { app.selectedTab = .train }
            actionButton("fork.knife", "Meal") { app.selectedTab = .fuel }
            actionButton(waterLogged ? "checkmark" : "drop.fill", waterLogged ? "+16 oz" : "Water") {
                guard !waterLogged else { return }
                app.nutrition.addWater(16)
                Haptics.success()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { waterLogged = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { waterLogged = false }
                }
            }
            NavigationLink { WearablesView() } label: {
                circleLabel("arrow.triangle.2.circlepath", "Sync")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Sync devices")
        }
    }

    private func actionButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            circleLabel(icon, label)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(label)
    }

    private func circleLabel(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Theme.card)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 52, height: 52)
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .contentShape(Rectangle())
    }
}
