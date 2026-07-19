import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    /// Persisted per-directive: dismissing hides *this* directive's tip until the
    /// directive changes, surviving tab switches and relaunches (P1-9).
    @AppStorage("forge.dashboard.dismissedTipID") private var dismissedTipID = ""

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                header
                headline
                goalCard
                QuickActionsRow()
                connectHealthBanner
                MorningCheckInCard()
                dailySummary
                heroCard
                todayCard
                tipBanner
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

    /// Big friendly opener, tuned to the day's state — the reference design's
    /// "Let's start strong!" moment in Forge's voice.
    private var headline: some View {
        Text(headlineText)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.cream)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var headlineText: String {
        if app.recovery.today.recovery >= 80 { return "Green light.\nGo get it." }
        switch Daypart.now {
        case "Morning": return "Let's start\nstrong."
        case "Afternoon": return "Keep the\nmomentum."
        default: return "Finish the\nday right."
        }
    }

    /// Reference goal card: one percentage, one bar, one bolt.
    /// The number is real — today's calories against the coached target.
    private var goalCard: some View {
        let n = app.nutrition
        // One clamped source of truth so the visible bar and the VoiceOver label
        // can never disagree (previously the label read the unclamped value).
        let pct = Progress.displayPercent(n.calories, of: n.calorieTarget)
        return Card {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("You're \(pct)% to your fuel target")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                    CapsuleBar(value: Double(n.calories), target: Double(n.calorieTarget),
                               tone: .gold, height: 10)
                    Text("\(n.calories.formatted()) / \(n.calorieTarget.formatted()) kcal")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
                ZStack {
                    Circle().fill(Theme.goldGradient)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.bg)
                }
                .frame(width: 46, height: 46)
                .shadow(color: Theme.gold.opacity(0.35), radius: 9, y: 2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fuel progress: \(pct) percent of today's calorie target")
        .accessibilityValue("\(n.calories.formatted()) of \(n.calorieTarget.formatted()) kilocalories")
    }

    /// Reference "Daily Summary": two ring cards over live Health numbers.
    private var dailySummary: some View {
        let hk = app.healthKit
        // Goals are derived from the athlete's profile (labeled defaults), not a
        // universal 10,000 steps / 1,000 kcal. Progress is clamped + finite-safe.
        let stepGoal = TargetEngine.steps(app.user)
        let energyGoal = TargetEngine.activeEnergy(app.user)
        let stepPct = Progress.displayPercent(hk.steps, of: stepGoal)
        let energyPct = Progress.displayPercent(hk.activeEnergy, of: energyGoal)
        return VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: "Daily Summary")
            HStack(spacing: 10) {
                summaryRingCard(pct: stepPct, big: hk.steps.formatted(), label: "Steps",
                                sub: "goal \(stepGoal.formatted())")
                summaryRingCard(pct: energyPct, big: hk.activeEnergy.formatted(), label: "Active energy",
                                sub: "kcal · goal \(energyGoal.formatted())")
            }
        }
    }

    private func summaryRingCard(pct: Int, big: String, label: String, sub: String) -> some View {
        Card {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.muted)
                    Text(big)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(sub).font(.system(size: 9.5)).foregroundStyle(Theme.faint)
                }
                Spacer(minLength: 0)
                ScoreRing(value: min(pct, 100), size: 46, lineWidth: 5, animated: false)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(big), \(min(pct, 100)) percent")
    }

    /// Reference tip banner — gold, dismissible, with a real action.
    /// The tip is the directive's priority, not canned copy.
    @ViewBuilder
    private var tipBanner: some View {
        let directive = app.dailyDirective
        if directive.id != dismissedTipID {
            Card(gold: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(directive.priorityAction)
                        .font(Theme.text(14, .medium))
                        .foregroundStyle(Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button("Dismiss") {
                            withAnimation { dismissedTipID = directive.id }
                        }
                        .buttonStyle(GhostButtonStyle(compact: true))
                        Button("Ask Coach") {
                            Haptics.tap()
                            app.selectedTab = .coach
                        }
                        .buttonStyle(GoldButtonStyle(compact: true))
                    }
                    RecommendationBasisView(basis: app.directiveBasis)
                }
            }
        }
    }

    /// The 1.0 data story is Apple Health. Until it's connected the recovery
    /// numbers are demo values — say so, and make connecting one tap.
    @ViewBuilder
    private var connectHealthBanner: some View {
        if app.healthKit.authState == .notDetermined {
            Card(gold: true) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18)).foregroundStyle(Theme.rubyBright)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connect Apple Health")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text("Your score runs on demo data until Forge can read your sleep, HRV, and activity.")
                            .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button("Connect") {
                        Task {
                            await app.healthKit.connect()
                            app.ingestHealthKitSignals()
                        }
                    }
                    .buttonStyle(GoldButtonStyle(compact: true))
                }
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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.muted)
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

    /// Consecutive days the athlete did the work — completed a workout or logged
    /// a check-in. Not "opened the app" (see PersistenceService.activeDays).
    private var streakDays: Int {
        StreakEngine.streak(days: PersistenceService.activeDays())
    }

    private var heroCard: some View {
        let directive = app.dailyDirective
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text("\(app.forgeScore)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.cream)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            // Honest provenance: "Demo data" until any live signal
                            // arrives, then "Partial · estimated" while recovery and
                            // strain are still modeled — never a silent clean score.
                            if app.recovery.provenance != .live {
                                Chip(text: app.recovery.provenance.label, tone: .amber)
                            }
                            if streakDays >= 2 {
                                Chip(text: "\(streakDays)-day streak", tone: .gold)
                            }
                        }
                    }
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
