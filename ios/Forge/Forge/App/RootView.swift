import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            switch app.phase {
            case .welcome:
                WelcomeView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingFlowView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .main:
                MainTabView()
                    // Onboarding → Home reveals with a gentle scale-up, so the
                    // dashboard feels like it settles into place rather than cutting in.
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .task { app.rehydrate() }
        .animation(Motion.entrance, value: phaseKey)
        // Dynamic Type: honor user text size up to AX2; larger sizes need a
        // dedicated reflow pass before they render acceptably in dense cards.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private var phaseKey: Int {
        switch app.phase {
        case .welcome: return 0
        case .onboarding: return 1
        case .main: return 2
        }
    }
}
