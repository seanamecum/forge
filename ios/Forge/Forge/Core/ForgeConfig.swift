import Foundation

/// How the AI coach reaches a model, safest-first:
///   liveProxy  — via Forge's backend (Supabase Edge Function holds the key). Production path.
///   liveDirect — straight to the Claude API with a local key. Local dev only.
///   mock       — rule-based offline engine. Always the fallback.
enum AIMode { case mock, liveProxy, liveDirect }

/// App configuration + secrets resolution.
///
/// SECURITY: an API key shipped inside an app binary is extractable by anyone
/// who downloads the app. Production therefore uses `liveProxy` — the client
/// sends the request to `supabase/functions/coach-proxy`, which holds the
/// Anthropic key server-side. `liveDirect` exists only for local development.
/// With neither configured, the app runs fully offline in mock mode.
enum ForgeConfig {

    /// Backend proxy URL (production path). Resolution order:
    ///   1. `FORGE_COACH_PROXY_URL` environment variable (Xcode scheme)
    ///   2. `CoachProxyURL` in the optional, gitignored `Secrets.plist`
    /// e.g. https://<project-ref>.functions.supabase.co/coach-proxy
    static var coachProxyURL: String? {
        if let env = ProcessInfo.processInfo.environment["FORGE_COACH_PROXY_URL"],
           !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return env
        }
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url),
           let raw = dict["CoachProxyURL"] as? String,
           !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            return raw
        }
        return nil
    }

    /// Anthropic API key (LOCAL DEV ONLY). Resolution order:
    ///   1. `ANTHROPIC_API_KEY` environment variable (set in the Xcode scheme)
    ///   2. `AnthropicAPIKey` in an optional, gitignored `Secrets.plist`
    ///   3. empty → not used
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

    /// Pure mode resolution — proxy always beats a local key. Unit-tested.
    static func mode(key: String?, proxy: String?) -> AIMode {
        if let proxy, !proxy.trimmingCharacters(in: .whitespaces).isEmpty { return .liveProxy }
        if let key, !key.trimmingCharacters(in: .whitespaces).isEmpty { return .liveDirect }
        return .mock
    }

    static var aiMode: AIMode { mode(key: anthropicAPIKey, proxy: coachProxyURL) }

    /// Where the coach request goes for the current mode.
    static var coachEndpoint: String {
        coachProxyURL ?? messagesEndpoint
    }

    // MARK: - Claude API

    /// Default per the Claude API guidance. Swap to `claude-sonnet-4-6` or
    /// `claude-haiku-4-5` to trade intelligence for cost/latency in a consumer chat.
    static let coachModel = "claude-opus-4-8"
    static let anthropicVersion = "2023-06-01"
    static let messagesEndpoint = "https://api.anthropic.com/v1/messages"
    static let coachMaxTokens = 1024
}
