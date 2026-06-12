import Foundation
import Observation

/// Chat state + orchestration for the AI Coach. AIService stays a pure
/// reply engine (mock now, Claude API later); this owns the conversation.
@Observable
final class CoachViewModel {
    var messages: [CoachMessage] = []
    var isThinking = false

    func seedIfNeeded(userName: String) {
        guard messages.isEmpty else { return }
        let first = userName.split(separator: " ").first.map(String.init) ?? userName
        messages.append(CoachMessage(
            role: .coach,
            text: "Morning, \(first). I'm reading everything — last night's sleep, your HRV, the knee, yesterday's bench session, today's protein pace. Ask me anything.",
            suggestions: ["What should I do today?", "Why am I tired?", "Should I train hard?",
                          "Why is my bench not increasing?", "How do I recover from knee pain?",
                          "What supplement am I missing?"]
        ))
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(CoachMessage(role: .user, text: trimmed))
        isThinking = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            messages.append(AIService.reply(to: trimmed))
            isThinking = false
        }
    }
}
