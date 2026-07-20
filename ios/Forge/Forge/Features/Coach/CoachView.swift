import SwiftUI

struct CoachView: View {
    @Environment(AppState.self) private var app
    @State private var vm = CoachViewModel()
    @State private var input = ""
    @State private var showEvidence = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(vm.messages) { msg in
                                CoachBubble(message: msg, onSuggestion: send)
                            }
                            if vm.isThinking {
                                ThinkingIndicator()
                            }
                            Color.clear.frame(height: 4).id("bottom")
                        }
                        .padding(16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: vm.messages.count) {
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                composer
            }
            .background(Theme.bg)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                        .foregroundStyle(Theme.gold)
                }
            }
            .onAppear {
                vm.checkInNote = app.checkIn?.coachNote
                vm.seedIfNeeded(userName: app.user.name)
            }
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

            Button {
                showEvidence = true
            } label: {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.card))
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("The science behind Forge's coaching")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgElevated)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
        .sheet(isPresented: $showEvidence) { EvidenceSheet() }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask the Coach…", text: $input)
                .focused($inputFocused)
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

    private func send(_ text: String) {
        Haptics.tap()
        vm.send(text, context: app.coachContext)
        input = ""
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
                    .font(Theme.text(14))
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
                        .font(Theme.text(14))
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
                            Text(showSteps ? "Hide signals" : "Signals Forge used · \(message.steps.count)")
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

// MARK: - Evidence sheet

/// "Grounded in sport science" — the vetted references behind Forge's
/// recommendations, shown to the athlete instead of asked to be trusted.
struct EvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Forge's recommendations are grounded in position stands and landmark studies. The live coach cites only from this vetted list — it is never allowed to invent a reference.")
                        .font(Theme.text(12.5))
                        .foregroundStyle(Theme.muted)
                        .padding(.bottom, 4)

                    ForEach(EvidenceBase.items) { item in
                        Card {
                            VStack(alignment: .leading, spacing: 6) {
                                EyebrowLabel(text: item.topic)
                                Text(item.claim)
                                    .font(Theme.text(13))
                                    .foregroundStyle(Theme.cream)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(item.source)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.gold)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Text("Educational guidance, not medical advice.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.faint)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("The Science")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
    }
}
