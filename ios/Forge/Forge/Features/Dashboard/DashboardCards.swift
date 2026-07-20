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
                        Text(AIService.dailyBrief(context: app.coachContext))
                            .font(Theme.text(12.5))
                            .foregroundStyle(Theme.creamDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Sparkline(values: app.recovery.forgeScoreTrend, height: 36,
                          accessibilityLabel: "Forge Score trend")

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

                        Divider().overlay(Theme.hairline.opacity(0.5))
                        RecommendationBasisView(basis: app.forgeScoreBasis)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

// MARK: - Forge Intelligence (cross-module connections)

/// The connective tissue: why recovery reads the way it does, and the causal
/// chains linking sleep → recovery → training → injury → fuel. This is what makes
/// Forge feel like one brain instead of twelve separate trackers.
struct IntelligenceCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let drivers = Array(app.recoveryDrivers.prefix(3))
        let insights = Array(app.forgeInsights.prefix(3))
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.gold)
                    EyebrowLabel(text: "Forge Intelligence · How Today Connects")
                }

                if !drivers.isEmpty {
                    Text("WHY RECOVERY IS \(app.recovery.today.recovery)")
                        .font(.system(size: 8.5, weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    VStack(spacing: 7) {
                        ForEach(drivers) { d in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: d.positive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(d.positive ? Theme.green : Theme.amber)
                                    .frame(width: 13)
                                    .padding(.top, 2)
                                Text(d.factor)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.cream)
                                    .frame(width: 84, alignment: .leading)
                                Text(d.detail)
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                if !drivers.isEmpty && !insights.isEmpty {
                    Divider().overlay(Theme.hairline)
                }

                if !insights.isEmpty {
                    Text("THE CONNECTIONS")
                        .font(.system(size: 8.5, weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    VStack(spacing: 11) {
                        ForEach(insights) { i in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: i.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(i.tone.color)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(i.tone.color.opacity(0.14)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(i.chain)
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundStyle(Theme.cream)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(i.action)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.creamDim)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                Button { app.selectedTab = .coach } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 10))
                        Text("Ask the coach about this").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.gold)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forge intelligence. " + app.forgeInsights.prefix(3).map(\.chain).joined(separator: ". "))
    }
}

// MARK: - Today's workout

struct TodaysWorkoutCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let plan = app.todaysPlan
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Today's Session")
                    Spacer()
                    // Safety chip reflects the ACTUAL active injuries, not a fixed label.
                    if let injury = app.injuries.active.first {
                        Chip(text: "\(injury.type.rawValue)-Safe", tone: .amber)
                    } else {
                        Chip(text: "Full Clearance", tone: .green)
                    }
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
                LabeledBar(label: "Calories", valueText: "\(n.calories) / \(n.calorieTarget)",
                           value: Double(n.calories), target: Double(n.calorieTarget), tone: .gold)
                LabeledBar(label: "Protein", valueText: "\(n.protein) / \(n.proteinTarget) g",
                           value: Double(n.protein), target: Double(n.proteinTarget), tone: .green)
                LabeledBar(label: "Water", valueText: "\(Int(n.waterOz)) / \(n.waterTargetOz) oz",
                           value: n.waterOz, target: Double(n.waterTargetOz), tone: .royal)

                HStack {
                    Chip(text: "+\(n.proteinRemaining) g protein to go", tone: .amber)
                    Spacer()
                    Button("Log a meal") { app.selectedTab = .fuel }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.gold)
                }
                RecommendationBasisView(basis: app.nutritionBasis)
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
                        HStack(spacing: 6) {
                            EyebrowLabel(text: "Injury Risk · \(risk.band)")
                            Chip(text: "Sample", tone: .amber)
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
                        .foregroundStyle(app.healthKit.authState == .authorized ? Theme.green : Theme.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.healthKit.authState == .authorized
                             ? "Apple Health connected"
                             : "Apple Health not connected")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.cream)
                        Text(app.healthKit.authState == .authorized
                             ? "Sleep, HRV, activity, and workouts flowing"
                             : "Connect to replace demo data with yours")
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
                // 1.0 grid: everything here works with real data today.
                // Social/Compete/Teams/Marketplace/Bloodwork/Achievements
                // return post-launch (views still exist, just unlinked).
                ModuleTile(icon: "target", title: "Goals", subtitle: "Targets · deadlines · progress") { GoalsView() }
                ModuleTile(icon: "figure.run", title: "Running", subtitle: "GPS runs · paces · splits") { RunningView() }
                ModuleTile(icon: "figure.arms.open", title: "Body", subtitle: "Weight · measurements") { BodyTrackingView() }
                ModuleTile(icon: "wand.and.stars", title: "Digital Twin", subtitle: "Your 12-week forecast") { ForecastView() }
                ModuleTile(icon: "camera.viewfinder", title: "Form Analysis", subtitle: "Sample preview") { FormAnalysisView() }
                ModuleTile(icon: "heart.fill", title: "Apple Health", subtitle: "Your data source") { WearablesView() }
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
