import SwiftUI

/// Five-tab shell with a custom premium tab bar. The Coach sits center with a gold glow.
/// Health, Body, Forecast, Social, Compete, Achievements, Marketplace, Teams, and Profile
/// are reachable from the Home command center and navigation bars (iOS HIG: 5 primary tabs).
struct MainTabView: View {
    @Environment(AppState.self) private var app

    var body: some View {
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
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Theme.bg.opacity(0.75))
                .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: MainTab) -> some View {
        let selected = app.selectedTab == tab
        let isCoach = tab == .coach

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                app.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isCoach {
                        Circle()
                            .fill(Theme.goldGradient)
                            .frame(width: 40, height: 40)
                            .shadow(color: Theme.gold.opacity(selected ? 0.7 : 0.35), radius: selected ? 14 : 8)
                            .offset(y: -8)
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.bg)
                            .offset(y: -8)
                    } else {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(selected ? Theme.gold : Theme.faint)
                            .frame(height: 28)
                    }
                }
                Text(tab.label)
                    .font(.system(size: 10, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Theme.goldBright : Theme.faint)
                    .offset(y: isCoach ? -6 : 0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
