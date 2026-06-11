import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var app
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Ambient gold glow
            RadialGradient(colors: [Theme.gold.opacity(0.16), .clear],
                           center: .top, startRadius: 10, endRadius: 420)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ForgeMark(size: 72)
                    .padding(.bottom, 28)

                Text("FORGE")
                    .font(Theme.display(44, .semibold))
                    .kerning(14)
                    .foregroundStyle(Theme.cream)

                Text("HUMAN PERFORMANCE, ENGINEERED")
                    .font(Theme.eyebrow(11))
                    .kerning(3)
                    .foregroundStyle(Theme.gold)
                    .padding(.top, 10)

                Text("The body is a system.\nForge is the operating layer.")
                    .font(Theme.display(22))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.creamDim)
                    .padding(.top, 26)

                Spacer()

                VStack(spacing: 12) {
                    Button("Begin — Create Account") { showSignUp = true }
                        .buttonStyle(GoldButtonStyle())

                    Button("Sign In") { showSignIn = true }
                        .buttonStyle(GhostButtonStyle())

                    Button {
                        app.auth.signInDemo()
                        app.completeAuth(demo: true)
                    } label: {
                        Text("Explore the demo →")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appeared = true }
        }
        .sheet(isPresented: $showSignIn) { SignInSheet() }
        .sheet(isPresented: $showSignUp) { SignUpSheet() }
    }
}

/// Geometric gold anvil-shield logomark.
struct ForgeMark: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            ShieldShape()
                .stroke(Theme.goldGradient, lineWidth: 1.6)
                .opacity(0.65)
            Text("F")
                .font(Theme.display(size * 0.46, .bold))
                .foregroundStyle(Theme.goldGradient)
        }
        .frame(width: size, height: size * 1.1)
        .shadow(color: Theme.gold.opacity(0.45), radius: 18)
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.18))
        p.addLine(to: CGPoint(x: w, y: h * 0.55))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                   control1: CGPoint(x: w, y: h * 0.8),
                   control2: CGPoint(x: w * 0.78, y: h * 0.94))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.55),
                   control1: CGPoint(x: w * 0.22, y: h * 0.94),
                   control2: CGPoint(x: 0, y: h * 0.8))
        p.addLine(to: CGPoint(x: 0, y: h * 0.18))
        p.closeSubpath()
        return p
    }
}
