import SwiftUI

struct SignInSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var showForgot = false

    var body: some View {
        AuthSheetShell(title: "Sign In", subtitle: "Welcome back to The Forge.") {
            AuthField(label: "Email", text: $email, keyboard: .emailAddress)
            AuthField(label: "Password", text: $password, secure: true)

            if let error = app.auth.lastError {
                Text(error).font(.system(size: 12)).foregroundStyle(Theme.rubyBright)
            }

            Button(busy ? "Signing in…" : "Sign In") {
                busy = true
                Task {
                    let ok = await app.auth.signIn(email: email, password: password)
                    busy = false
                    if ok {
                        dismiss()
                        app.completeAuth(demo: false)
                    }
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(busy)

            Button("Forgot password?") { showForgot = true }
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
        }
        .sheet(isPresented: $showForgot) { ForgotPasswordSheet() }
    }
}

struct SignUpSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false

    var body: some View {
        AuthSheetShell(title: "Create Account", subtitle: "14 days free. No card required.") {
            AuthField(label: "Name", text: $name)
            AuthField(label: "Email", text: $email, keyboard: .emailAddress)
            AuthField(label: "Password", text: $password, secure: true)

            if let error = app.auth.lastError {
                Text(error).font(.system(size: 12)).foregroundStyle(Theme.rubyBright)
            }

            Button(busy ? "Creating…" : "Begin") {
                busy = true
                Task {
                    let ok = await app.auth.signUp(name: name, email: email, password: password)
                    busy = false
                    if ok {
                        if !name.isEmpty { app.user.name = name }
                        dismiss()
                        app.completeAuth(demo: false)
                    }
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(busy)
        }
    }
}

struct ForgotPasswordSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        AuthSheetShell(title: "Reset Password",
                       subtitle: sent ? "Check your inbox for the reset link." : "We'll email you a reset link.") {
            if !sent {
                AuthField(label: "Email", text: $email, keyboard: .emailAddress)
                Button("Send reset link") {
                    Task {
                        sent = await app.auth.sendPasswordReset(email: email)
                    }
                }
                .buttonStyle(GoldButtonStyle())
            } else {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.gold)
                    .frame(maxWidth: .infinity)
                Button("Done") { dismiss() }
                    .buttonStyle(GhostButtonStyle())
            }
        }
        .presentationDetents([.height(320)])
    }
}

// MARK: - Shared shell

struct AuthSheetShell<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Theme.bgElevated.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Capsule().fill(Theme.faint.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Text(title)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.cream)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 6)

                content
                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

struct AuthField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var secure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(Theme.muted)
            Group {
                if secure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(label == "Name" ? .words : .never)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(Theme.cream)
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 11).fill(Theme.bg.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.hairline, lineWidth: 1))
        }
    }
}
