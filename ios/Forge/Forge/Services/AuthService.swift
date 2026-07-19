import Foundation
import Observation

/// Real accounts via Supabase Auth (GoTrue REST). Sessions persist across
/// relaunches. The demo path stays available and is labeled as such in the UI.
@Observable
final class AuthService {
    var isAuthenticated = false
    var lastError: String?
    /// Non-error guidance, e.g. "check your email to confirm your account".
    var notice: String?

    private static let sessionKey = "forge.auth.session.v1"

    private struct StoredSession: Codable {
        let accessToken: String
        let refreshToken: String?
        let email: String
        var expiresAt: Date?
    }

    init() {
        Self.migrateLegacySessionIfNeeded()
        // A stored session means this device already signed in.
        isAuthenticated = Self.loadSession() != nil
    }

    var sessionEmail: String? { Self.loadSession()?.email }
    var sessionToken: String? { Self.loadSession()?.accessToken }

    /// Self-service account deletion (App Store 5.1.1(v)) via the
    /// delete-account edge function — the server deletes whoever the JWT
    /// belongs to; no id ever comes from the client.
    @MainActor
    func deleteAccount() async -> Bool {
        // Make sure we send a live token — a stale JWT would 401 and look like a
        // network failure.
        await refreshIfNeeded()
        guard let token = sessionToken else {
            lastError = "Your session expired. Please sign in again to delete your account."
            return false
        }
        var request = URLRequest(url: SupabaseConfig.url.appending(path: "/functions/v1/delete-account"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode)
        else {
            lastError = "Couldn't delete the account — check your connection and try again."
            return false
        }
        signOut()
        return true
    }

    // MARK: - API

    @MainActor
    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        lastError = nil; notice = nil
        guard email.contains("@"), password.count >= 6 else {
            lastError = "Check your email and password (6+ characters)."
            return false
        }
        do {
            let body = try JSONEncoder().encode(["email": email, "password": password])
            let (data, status) = try await Self.post(path: "token?grant_type=password", body: body)
            guard status == 200 else {
                lastError = Self.serverMessage(data) ?? "Wrong email or password."
                return false
            }
            try Self.storeSession(from: data, email: email)
            isAuthenticated = true
            return true
        } catch {
            lastError = "Couldn't reach the server — check your connection and try again."
            return false
        }
    }

    @MainActor
    @discardableResult
    func signUp(name: String, email: String, password: String) async -> Bool {
        lastError = nil; notice = nil
        guard !name.isEmpty, email.contains("@"), password.count >= 6 else {
            lastError = "Fill in every field — password needs 6+ characters."
            return false
        }
        do {
            let payload: [String: Any] = [
                "email": email, "password": password,
                "data": ["name": name],
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let (data, status) = try await Self.post(path: "signup", body: body)
            guard status == 200 else {
                lastError = Self.serverMessage(data) ?? "Couldn't create the account."
                return false
            }
            if (try? Self.storeSession(from: data, email: email)) != nil {
                isAuthenticated = true
                return true
            }
            // Email confirmation is on: account exists, session comes after the
            // user clicks the link in their inbox.
            notice = "Account created — check \(email) for a confirmation link, then sign in."
            return false
        } catch {
            lastError = "Couldn't reach the server — check your connection and try again."
            return false
        }
    }

    func signInDemo() {
        isAuthenticated = true
    }

    @MainActor
    func sendPasswordReset(email: String) async -> Bool {
        guard email.contains("@") else { return false }
        let body = (try? JSONEncoder().encode(["email": email])) ?? Data()
        let result = try? await Self.post(path: "recover", body: body)
        return result?.1 == 200
    }

    func signOut() {
        Keychain.delete(Self.sessionKey)
        isAuthenticated = false
    }

    /// Refreshes the access token when it is missing an expiry or within 60s of
    /// expiring, using the stored refresh token. Best-effort: a failure leaves the
    /// existing session in place for the caller to handle (e.g. surface re-auth).
    @MainActor
    func refreshIfNeeded() async {
        guard let session = Self.loadSession() else { return }
        if let expiry = session.expiresAt, expiry.timeIntervalSinceNow > 60 { return }
        guard let refreshToken = session.refreshToken,
              let body = try? JSONEncoder().encode(["refresh_token": refreshToken]),
              let (data, status) = try? await Self.post(path: "token?grant_type=refresh_token", body: body),
              status == 200 else { return }
        try? Self.storeSession(from: data, email: session.email)
    }

    // MARK: - Transport

    private static func post(path: String, body: Data) async throws -> (Data, Int) {
        guard let url = URL(string: SupabaseConfig.url.absoluteString + "/auth/v1/" + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?
        let expiresAt: Int?
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
        }
    }

    private static func storeSession(from data: Data, email: String) throws {
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        let expiry: Date? = token.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            ?? token.expiresIn.map { Date(timeIntervalSinceNow: TimeInterval($0)) }
        let session = StoredSession(accessToken: token.accessToken,
                                    refreshToken: token.refreshToken,
                                    email: email, expiresAt: expiry)
        Keychain.set(try JSONEncoder().encode(session), for: sessionKey)
    }

    private static func loadSession() -> StoredSession? {
        guard let data = Keychain.get(sessionKey) else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    /// One-time move of any pre-Keychain session out of UserDefaults.
    private static func migrateLegacySessionIfNeeded() {
        guard Keychain.get(sessionKey) == nil,
              let legacy = UserDefaults.standard.data(forKey: sessionKey) else { return }
        Keychain.set(legacy, for: sessionKey)
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    /// Supabase error payloads vary: {"msg": …}, {"message": …}, {"error_description": …}.
    private static func serverMessage(_ data: Data) -> String? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (dict["msg"] ?? dict["message"] ?? dict["error_description"]) as? String
    }
}
