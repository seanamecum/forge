import SwiftUI
import SwiftData

/// Home — calm, premium, alive. It answers three questions and nothing else:
/// *How am I doing?* (Forge Score + trend), *What matters most right now?*
/// (one curated ambient insight), *What's the next best action?* (today's
/// coached priority). Every card earns its place; duplication is designed out.
struct DashboardView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @State private var todayExpanded = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                entrance(0) { header }
                entrance(1) { headline }
                if isFreshAccount {
                    entrance(2) { firstStepsCard }   // inspire the first action
                }
                entrance(3) { heroCard }                 // How am I doing?
                entrance(4) { AmbientInsightCard() }     // What matters most right now?
                entrance(5) { MorningCheckInCard() }     // conditional
                entrance(6) { todayCard }                // What's the next best action?
                entrance(7) { todaysGoals }              // fuel · steps · energy
                entrance(8) { QuickActionsRow() }
                entrance(9) { connectHealthBanner }      // conditional
                entrance(10) { ModulesGrid() }
                entrance(11) { DisclaimerNote() }
            }
            .navigationBarHidden(true)
            .refreshable { await refresh() }
            .onAppear {
                app.refreshFuelPlan()
                app.publishWidgetSnapshot()
                // Snapshot today's Forge Score so trends build from real history.
                PersistenceService.recordTodayScore(app.forgeScore, context: modelContext)
                if !appeared { appeared = true }   // fire the one-time entrance choreography
            }
        }
    }

    /// One-time staggered entrance — each section eases up + in with a spring,
    /// delayed by its position, then never replays on tab switches.
    private func entrance<V: View>(_ index: Int, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(Motion.entrance.delay(Double(index) * 0.05), value: appeared)
    }

    // MARK: - First-run empty state (inspire action, never look unfinished)

    private var isFreshAccount: Bool {
        !app.isDemoAccount && app.workouts.history.isEmpty && app.nutrition.entries.isEmpty
    }

    private var firstStepsCard: some View {
        let first = app.user.name.split(separator: " ").first.map(String.init)
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: Space.md) {
                Text(first.map { "Welcome, \($0)." } ?? "Welcome to Forge.")
                    .font(Typography.title3).foregroundStyle(Theme.cream)
                Text("Do one thing and Forge starts learning you — no wearable required.")
                    .font(Typography.footnote).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                firstStep("fork.knife", "Log your first meal", "Targets adapt as you eat") { app.selectedTab = .fuel }
                firstStep("dumbbell.fill", "Start your first workout", "Builds your PRs and volume") { app.selectedTab = .train }
            }
        }
    }

    private func firstStep(_ icon: String, _ title: String, _ detail: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(Motion.spring) { action() }
        } label: {
            HStack(spacing: Space.md) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.14))
                    Image(systemName: icon).font(.system(size: IconSize.md)).foregroundStyle(Theme.gold)
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Typography.body.weight(.semibold)).foregroundStyle(Theme.cream)
                    Text(detail).font(Typography.caption).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.faint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(detail)")
    }

    /// Pull-to-refresh: re-ingest Health signals and recompute the live plan,
    /// boards, and widget — with a soft start / success-end haptic.
    @MainActor
    private func refresh() async {
        Haptics.soft()
        app.ingestHealthKitSignals()
        app.refreshFuelPlan()
        app.refreshTrainingBoards()
        app.publishWidgetSnapshot()
        try? await Task.sleep(for: .milliseconds(600))
        Haptics.success()
    }

    // MARK: - Greeting

    private var header: some View {
        HStack(spacing: Space.md) {
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
                    .font(Typography.subheadline)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            NavigationLink { NotificationsView() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: IconSize.lg))
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
        .padding(.top, Space.xs)
    }

    /// Big friendly opener, tuned to the day's state.
    private var headline: some View {
        Text(headlineText)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.cream)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Space.xxs)
    }

    private var headlineText: String {
        if app.recovery.today.recovery >= 80 { return "Green light.\nGo get it." }
        switch Daypart.now {
        case "Morning": return "Let's start\nstrong."
        case "Afternoon": return "Keep the\nmomentum."
        default: return "Finish the\nday right."
        }
    }

    // MARK: - How am I doing? (Forge Score + trend)

    private var heroCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Space.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(app.forgeScore)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.cream)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(Motion.snappy, value: app.forgeScore)
                        HStack(spacing: 5) {
                            Text("Forge Score").font(Typography.footnote).foregroundStyle(Theme.muted)
                            // Honest, but calm — a faint caption while the score is
                            // still estimated, not an amber debug chip.
                            if app.recovery.provenance != .live {
                                Text("· \(app.recovery.provenance.label.lowercased())")
                                    .font(Typography.caption).foregroundStyle(Theme.faint)
                            }
                        }
                    }
                    Spacer()
                    if streakDays >= 2 {
                        Chip(text: "\(streakDays)-day streak", tone: .gold)
                    }
                }
                if app.recovery.forgeScoreTrend.count >= 2 {
                    Sparkline(values: app.recovery.forgeScoreTrend, height: 64,
                              accessibilityLabel: "Forge Score trend")
                } else {
                    // A flat/empty line reads as broken — invite the trend instead.
                    Text("Your trend builds as you log each day.")
                        .font(Typography.caption).foregroundStyle(Theme.faint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Space.md)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forge Score \(app.forgeScore)\(streakDays >= 2 ? ", \(streakDays) day streak" : "")")
    }

    /// Consecutive days the athlete did the work — a completed workout or a
    /// logged check-in (not "opened the app").
    private var streakDays: Int {
        StreakEngine.streak(days: PersistenceService.activeDays())
    }

    // MARK: - What's the next best action? (today's coached priority)

    private var todayCard: some View {
        let directive = app.dailyDirective
        return Card {
            VStack(alignment: .leading, spacing: Space.md) {
                // Collapsed by default: the header + the single next best action.
                // Tap to reveal the supporting plan and the "why".
                Button {
                    Haptics.tap()
                    withAnimation(Motion.spring) { todayExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Today").font(Typography.footnote).foregroundStyle(Theme.muted)
                        Spacer()
                        Image(systemName: todayExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.faint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(todayExpanded ? "Today, hide details" : "Today, show details")

                Text(directive.priorityAction)
                    .font(Typography.callout.weight(.medium))
                    .foregroundStyle(Theme.gold)
                    .fixedSize(horizontal: false, vertical: true)

                if todayExpanded {
                    VStack(alignment: .leading, spacing: Space.md) {
                        Divider().overlay(Theme.hairline)
                        ForEach(directive.actions.prefix(3)) { action in
                            HStack(spacing: Space.md) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.creamDim)
                                    .frame(width: 22)
                                Text(action.value)
                                    .font(Typography.body)
                                    .foregroundStyle(Theme.cream)
                                Spacer()
                            }
                        }
                        RecommendationBasisView(basis: app.directiveBasis)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack {
                    Button("Ask Coach") { Haptics.tap(); app.selectedTab = .coach }
                        .buttonStyle(GoldButtonStyle(compact: true))
                    Spacer()
                }
            }
        }
    }

    // MARK: - How close to today's goals? (one ring row)

    private var todaysGoals: some View {
        let n = app.nutrition
        let hk = app.healthKit
        let stepGoal = TargetEngine.steps(app.user)
        let energyGoal = TargetEngine.activeEnergy(app.user)
        return VStack(alignment: .leading, spacing: Space.sm) {
            EyebrowLabel(text: "Today's Goals")
            Card {
                HStack(spacing: 0) {
                    goalRing(pct: Progress.displayPercent(n.calories, of: n.calorieTarget),
                             label: "Fuel", value: "\(n.calories.formatted()) kcal", tone: .gold)
                    ringDivider
                    goalRing(pct: Progress.displayPercent(hk.steps, of: stepGoal),
                             label: "Steps", value: hk.steps.formatted(), tone: .green)
                    ringDivider
                    goalRing(pct: Progress.displayPercent(hk.activeEnergy, of: energyGoal),
                             label: "Energy", value: "\(hk.activeEnergy.formatted()) kcal", tone: .amber)
                }
            }
        }
    }

    private func goalRing(pct: Int, label: String, value: String, tone: Tone) -> some View {
        VStack(spacing: 6) {
            ScoreRing(value: min(pct, 100), label: label, size: 62, lineWidth: 6, tone: tone)
            Text(value)
                .font(Typography.caption).foregroundStyle(Theme.muted)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), \(min(pct, 100)) percent of goal")
    }

    private var ringDivider: some View {
        Rectangle().fill(Theme.hairline).frame(width: 1, height: 44)
    }

    // MARK: - Optional: connect Apple Health

    /// A wearable is an *enhancement*, not a requirement — Forge runs on check-ins,
    /// workouts, nutrition, and weight without one. Offered only when undecided.
    @ViewBuilder
    private var connectHealthBanner: some View {
        if app.healthKit.authState == .notDetermined {
            Card(gold: true) {
                HStack(spacing: Space.md) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: IconSize.xl)).foregroundStyle(Theme.rubyBright)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add automatic tracking (optional)")
                            .font(Typography.body.weight(.semibold)).foregroundStyle(Theme.cream)
                        Text("Forge already runs on your check-ins and logs. Connect Apple Health to add automatic HRV, sleep, and activity.")
                            .font(Typography.footnote).foregroundStyle(Theme.muted)
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
}

// MARK: - Quick actions

/// Four circular one-tap actions — do the thing now, zero navigation depth.
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
                Haptics.logged()
                withAnimation(Motion.spring) { waterLogged = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation(Motion.gentle) { waterLogged = false }
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
                    .font(.system(size: IconSize.lg, weight: .medium))
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
