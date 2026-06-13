import Foundation
import Observation

/// Chat state + orchestration for the AI Coach. AIService owns the live/mock
/// decision; this owns the conversation and passes today's check-in as context.
@Observable
final class CoachViewModel {
    var messages: [CoachMessage] = []
    var isThinking = false
    /// Set by the view from today's morning check-in, if completed.
    var checkInNote: String?

    func seedIfNeeded(userName: String) {
        guard messages.isEmpty else { return }
        let first = userName.split(separator: " ").first.map(String.init) ?? userName
        let mode = ForgeConfig.aiMode == .live ? "" : " (demo coach — add an API key for live AI)"
        messages.append(CoachMessage(
            role: .coach,
            text: "Morning, \(first). I'm reading everything — last night's sleep, your HRV, the knee, yesterday's bench session, today's protein pace\(mode). Ask me anything.",
            suggestions: Array(AIService.quickPrompts.prefix(6))
        ))
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(CoachMessage(role: .user, text: trimmed))
        let history = messages
        isThinking = true
        Task { @MainActor in
            let reply = await AIService.reply(to: trimmed, history: history, checkInNote: checkInNote)
            messages.append(reply)
            isThinking = false
        }
    }
}
