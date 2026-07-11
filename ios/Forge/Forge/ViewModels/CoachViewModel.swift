import Foundation
import Observation

/// Chat state + orchestration for the AI Coach. AIService owns the live/mock
/// decision; this owns the conversation and passes live app context through.
@Observable
final class CoachViewModel {
    var messages: [CoachMessage] = []
    var isThinking = false
    /// Set by the view from today's morning check-in, if completed.
    var checkInNote: String?

    func seedIfNeeded(userName: String) {
        guard messages.isEmpty else { return }
        let first = userName.split(separator: " ").first.map(String.init) ?? userName
        let hello = Daypart.now
        let mode = ForgeConfig.aiMode == .mock ? " (demo coach — configure the proxy for live AI)" : ""
        messages.append(CoachMessage(
            role: .coach,
            text: "\(hello), \(first). I'm reading everything — last night's sleep, your HRV, the knee, yesterday's bench session, today's protein pace\(mode). Ask me anything.",
            suggestions: Array(AIService.quickPrompts.prefix(3))
        ))
    }

    /// Sends a question with the app's live context. History is captured BEFORE
    /// the new message is appended so the question reaches the API exactly once.
    func send(_ text: String, context: CoachContext) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }
        let history = messages
        messages.append(CoachMessage(role: .user, text: trimmed))
        isThinking = true
        Task { @MainActor in
            let reply = await AIService.reply(to: trimmed, history: history,
                                              context: context, checkInNote: checkInNote)
            messages.append(reply)
            isThinking = false
        }
    }
}
