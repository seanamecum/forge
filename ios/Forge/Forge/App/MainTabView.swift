import SwiftUI

/// Five-tab shell with a custom premium tab bar. The Coach sits center with a gold glow.
/// Health, Body, Forecast, Social, Compete, Achievements, Marketplace, Teams, and Profile
/// are reachable from the Home command center and navigation bars (iOS HIG: 5 primary tabs).
struct MainTabView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        // Demo/screenshot hook (no effect in normal use): FORGE_SCREEN jumps
        // straight to a pushed screen.
        switch ProcessInfo.processInfo.environment["FORGE_SCREEN"] {
        case "ecosystem": NavigationStack { WearablesView() }
        case "market": NavigationStack { MarketplaceView() }
        case "weekly": NavigationStack { WeeklyReportView() }
        case "logger": NavigationStack { WorkoutLoggerView(plan: app.todaysPlan) }
        default: tabShell
        }
    }

    private var tabShell: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch app.selectedTab {
                case .home: DashboardView()
                case .train: TrainHomeView()
                case .coach: CoachView()
                case .fuel: NutritionHomeView()
                case .recover: RecoverHomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ForgeTabBar()
        }
        .ignoresSafeArea(.keyboard)
        .background(Theme.bg)
    }
}

struct ForgeTabBar: View {
    @Environment(AppState.self) private var app

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        // Floating pill — glassy, detached from the screen edge.
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Theme.bg.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.55), radius: 20, y: 10)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }

    /// Reference-style pill: the ACTIVE tab expands into a gold capsule with
    /// icon + label; inactive tabs collapse to quiet glyphs. One moving pill,
    /// nothing else animated.
    @ViewBuilder
    private func tabButton(_ tab: MainTab) -> some View {
        let selected = app.selectedTab == tab

        Button {
            guard app.selectedTab != tab else { return }
            Haptics.selection()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                app.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selected ? Theme.bg : Theme.faint)
                if selected {
                    Text(tab.label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.bg)
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(.horizontal, selected ? 16 : 10)
            .padding(.vertical, 11)
            .background {
                if selected {
                    Capsule()
                        .fill(Theme.goldGradient)
                        .shadow(color: Theme.gold.opacity(0.4), radius: 10, y: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.label) tab")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
