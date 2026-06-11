import SwiftUI

struct CoachView: View {
    @Environment(AppState.self) private var app
    @State private var messages: [CoachMessage] = []
    @State private var input = ""
    @State private var thinking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(messages) { msg in
                                CoachBubble(message: msg, onSuggestion: send)
                            }
                            if thinking {
                                ThinkingIndicator()
                            }
                            Color.clear.frame(height: 4).id("bottom")
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                composer
            }
            .background(Theme.bg)
            .navigationBarHidden(true)
            .onAppear { seedIfNeeded() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.goldGradient).frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.bg)
            }
            .shadow(color: Theme.gold.opacity(0.5), radius: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text("Forge Coach")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.cream)
                HStack(spacing: 5) {
                    Circle().fill(Theme.green).frame(width: 6, height: 6)
                    Text("Synced · recovery 78 · knee phase 2 · 23-day streak")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgElevated)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask the Coach…", text: $input)
                .font(.system(size: 14))
                .foregroundStyle(Theme.cream)
                .padding(12)
                .background(Capsule().fill(Theme.card))
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                .onSubmit { send(input) }

            Button {
                send(input)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.goldGradient))
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 84)
        .background(Theme.bgElevated)
    }

    private func seedIfNeeded() {
        guard messages.isEmpty else { return }
        let first = app.user.name.split(separator: " ").first.map(String.init) ?? app.user.name
        messages.append(CoachMessage(
            role: .coach,
            text: "Morning, \(first). I'm reading everything — last night's sleep, your HRV, the knee, yesterday's bench session, today's protein pace. Ask me anything.",
            suggestions: ["What should I do today?", "Why am I tired?", "Should I train hard?",
                          "Why is my bench not increasing?", "How do I recover from knee pain?",
                          "What supplement am I missing?"]
        ))
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        messages.append(CoachMessage(role: .user, text: trimmed))
        input = ""
        thinking = true
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            messages.append(AIService.reply(to: trimmed))
            thinking = false
        }
    }
}

// MARK: - Bubbles

struct CoachBubble: View {
    let message: CoachMessage
    let onSuggestion: (String) -> Void
    @State private var showSteps = false

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 60)
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.cream)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.gold.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 4)
                    Text(message.text)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(Theme.creamDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))

                if !message.steps.isEmpty {
                    Button {
                        withAnimation { showSteps.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "list.number")
                            Text(showSteps ? "Hide reasoning" : "Reasoning · \(message.steps.count) signals")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.gold)
                    }

                    if showSteps {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(message.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 7) {
                                    Text("\(i + 1).")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.gold.opacity(0.7))
                                    Text(step)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.bgElevated))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
                    }
                }

                if !message.cards.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(message.cards) { card in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(card.label.uppercased())
                                    .font(.system(size: 8, weight: .semibold))
                                    .kerning(1)
                                    .foregroundStyle(Theme.muted)
                                Text(card.value)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundStyle(card.tone.color)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(card.tone.color.opacity(0.07)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(card.tone.color.opacity(0.3), lineWidth: 1))
                        }
                    }
                }

                if !message.suggestions.isEmpty {
                    FlowChips(options: message.suggestions,
                              isSelected: { _ in false },
                              toggle: onSuggestion)
                }
            }
        }
    }
}

struct ThinkingIndicator: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Theme.gold)
                .opacity(pulse ? 1 : 0.35)
            Text("COACH IS THINKING")
                .font(Theme.eyebrow(9))
                .kerning(2)
                .foregroundStyle(Theme.gold.opacity(0.8))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever()) { pulse = true }
        }
    }
}
