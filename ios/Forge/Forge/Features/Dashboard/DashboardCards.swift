import SwiftUI

// MARK: - Forge Score hero

struct ForgeScoreHero: View {
    @Environment(AppState.self) private var app
    @State private var showBreakdown = false

    var body: some View {
        Card(gold: true) {
            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    EyebrowLabel(text: "Forge Score · Today")
                    Spacer()
                    Chip(text: "Moderate Day", tone: .gold)
                }

                HStack(spacing: 20) {
                    ScoreRing(value: app.forgeScore, label: "Forge", size: 148, lineWidth: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coach's brief")
                            .font(Theme.eyebrow(9))
                            .kerning(1.6)
                            .foregroundStyle(Theme.muted)
                        Text(AIService.dailyBrief(forgeScore: app.forgeScore))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.creamDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Sparkline(values: app.recovery.forgeScoreTrend, height: 36)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showBreakdown.toggle() }
                } label: {
                    HStack {
                        Text(showBreakdown ? "Hide score drivers" : "What's driving this score?")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.gold)
                        Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.gold)
                    }
                }

                if showBreakdown {
                    VStack(spacing: 8) {
                        Text(app.forgeScoreNarrative)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.creamDim)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // What moved the score — signed drivers.
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(app.forgeScoreChanges) { change in
                                HStack(spacing: 7) {
                                    Image(systemName: change.positive ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(change.positive ? Theme.green : Theme.amber)
                                        .frame(width: 13)
                                    Text(change.text)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.creamDim)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // The single highest-leverage fix.
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.gold)
                            Text(app.forgeScoreLever)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Theme.gold)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)

                        Divider().overlay(Theme.hairline.opacity(0.5))

                        ForEach(app.forgeScoreBreakdown) { c in
                            HStack(spacing: 10) {
                                Text(c.label)
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Theme.creamDim)
                                    .frame(width: 110, alignment: .leading)
                                CapsuleBar(value: Double(c.value), target: 100,
                                           tone: c.value >= 75 ? .gold : (c.value >= 55 ? .amber : .ruby),
                                           height: 5)
                                Text("\(c.value)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.cream)
                                    .frame(width: 26, alignment: .trailing)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

// MARK: - Today's workout

struct TodaysWorkoutCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let plan = app.workouts.todaysPlan
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Today's Session")
                    Spacer()
                    Chip(text: "Knee-Safe", tone: .amber)
                }
                Text(plan.name)
                    .font(Theme.display(21))
                    .foregroundStyle(Theme.cream)
                Text("\(plan.blocks.reduce(0) { $0 + $1.items.count }) exercises · ~\(plan.estMinutes) min")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)

                CoachNote(text: plan.rationale)

                NavigationLink { WorkoutLoggerView(plan: plan) } label: {
                    Text("Start Session")
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }
}

// MARK: - Fuel

struct FuelCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let n = app.nutrition
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Fuel · Today")
                    Spacer()
                    Chip(text: "\(n.caloriesRemaining) kcal left", tone: .gold)
                }
                LabeledBar(label: "Calories", valueText: "\(n.calories) / \(n.user.calorieTarget)",
                           value: Double(n.calories), target: Double(n.user.calorieTarget), tone: .gold)
                LabeledBar(label: "Protein", valueText: "\(n.protein) / \(n.user.proteinTarget) g",
                           value: Double(n.protein), target: Double(n.user.proteinTarget), tone: .green)
                LabeledBar(label: "Water", valueText: "\(Int(n.waterOz)) / \(n.user.waterTargetOz) oz",
                           value: n.waterOz, target: Double(n.user.waterTargetOz), tone: .royal)

                HStack {
                    Chip(text: "+\(n.proteinRemaining) g protein to go", tone: .amber)
                    Spacer()
                    Button("Log a meal") { app.selectedTab = .fuel }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }
}

// MARK: - Injury risk

struct InjuryRiskCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let risk = app.injuries.risk
        return NavigationLink { ForgeRecoveryView() } label: {
            Card {
                HStack(spacing: 16) {
                    ScoreRing(value: risk.percent, label: "Risk", size: 76, lineWidth: 7, tone: .ruby)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            EyebrowLabel(text: "Injury Risk · \(risk.band)")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.faint)
                        }
                        ForEach(risk.drivers.prefix(3)) { d in
                            HStack(spacing: 6) {
                                Text(d.name).font(.system(size: 11)).foregroundStyle(Theme.muted)
                                Spacer()
                                Text(d.value).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wearables strip

struct WearableStatusStrip: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationLink { WearablesView() } label: {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(app.recovery.connectedCount) devices connected")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.cream)
                        Text("Apple Watch · WHOOP · Withings — synced minutes ago")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.faint)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modules grid

struct ModulesGrid: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: "Explore Forge")
            LazyVGrid(columns: columns, spacing: 10) {
                ModuleTile(icon: "target", title: "Goals", subtitle: "Targets · deadlines · progress") { GoalsView() }
                ModuleTile(icon: "figure.run", title: "Running", subtitle: "Mileage · paces · live runs") { RunningView() }
                ModuleTile(icon: "heart.text.square.fill", title: "Bloodwork", subtitle: "14 markers · AI read") { BloodworkView() }
                ModuleTile(icon: "figure.arms.open", title: "Body", subtitle: "Composition · photos") { BodyTrackingView() }
                ModuleTile(icon: "wand.and.stars", title: "Digital Twin", subtitle: "Your 12-week forecast") { ForecastView() }
                ModuleTile(icon: "camera.viewfinder", title: "Form Analysis", subtitle: "AI lift review") { FormAnalysisView() }
                ModuleTile(icon: "person.3.fill", title: "Social", subtitle: "Feed · groups") { SocialHubView() }
                ModuleTile(icon: "trophy.fill", title: "Compete", subtitle: "Boards · challenges") { CompeteView() }
                ModuleTile(icon: "star.circle.fill", title: "Achievements", subtitle: "XP · badges · missions") { AchievementsView() }
                ModuleTile(icon: "bag.fill", title: "Marketplace", subtitle: "Coaches · programs") { MarketplaceView() }
                ModuleTile(icon: "shield.lefthalf.filled", title: "Forge Teams", subtitle: "Squad dashboards") { TeamsView() }
                ModuleTile(icon: "applewatch.radiowaves.left.and.right", title: "Wearables", subtitle: "7-device hub") { WearablesView() }
            }
        }
    }
}

struct ModuleTile<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(Theme.gold)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.faint)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.cardGradient))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
