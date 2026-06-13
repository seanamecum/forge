import Foundation

enum AIMode { case live, mock }

/// App configuration + secrets resolution.
///
/// SECURITY: an API key shipped inside an app binary is extractable by anyone
/// who downloads the app. For production, proxy Claude calls through your own
/// backend (which holds the key server-side) and point `messagesEndpoint` at it.
/// Leaving the key empty here is the safe default — the app runs in mock mode.
enum ForgeConfig {

    /// Anthropic API key. Resolution order:
    ///   1. `ANTHROPIC_API_KEY` environment variable (set in the Xcode scheme for local dev)
    ///   2. `AnthropicAPIKey` in an optional, gitignored `Secrets.plist`
    ///   3. empty → mock mode
    static var anthropicAPIKey: String {
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return env
        }
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url),
           let key = dict["AnthropicAPIKey"] as? String,
           !key.trimmingCharacters(in: .whitespaces).isEmpty {
            return key
        }
        return ""
    }

    static var aiMode: AIMode { anthropicAPIKey.isEmpty ? .mock : .live }

    // MARK: - Claude API

    /// Default per the Claude API guidance. Swap to `claude-sonnet-4-6` or
    /// `claude-haiku-4-5` to trade intelligence for cost/latency in a consumer chat.
    static let coachModel = "claude-opus-4-8"
    static let anthropicVersion = "2023-06-01"
    static let messagesEndpoint = "https://api.anthropic.com/v1/messages"
    static let coachMaxTokens = 1024
}
