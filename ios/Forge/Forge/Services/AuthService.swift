import Foundation
import Observation

/// Mock auth. Swap the bodies for Supabase/Firebase calls later — the async
/// signatures are already shaped for a real network backend.
@Observable
final class AuthService {
    var isAuthenticated = false
    var lastError: String?

    @MainActor
    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        lastError = nil
        try? await Task.sleep(for: .milliseconds(700))
        guard email.contains("@"), password.count >= 6 else {
            lastError = "Check your email and password (6+ characters)."
            return false
        }
        isAuthenticated = true
        return true
    }

    @MainActor
    @discardableResult
    func signUp(name: String, email: String, password: String) async -> Bool {
        lastError = nil
        try? await Task.sleep(for: .milliseconds(900))
        guard !name.isEmpty, email.contains("@"), password.count >= 6 else {
            lastError = "Fill in every field — password needs 6+ characters."
            return false
        }
        isAuthenticated = true
        return true
    }

    func signInDemo() {
        isAuthenticated = true
    }

    func sendPasswordReset(email: String) async -> Bool {
        try? await Task.sleep(for: .milliseconds(600))
        return email.contains("@")
    }

    func signOut() {
        isAuthenticated = false
    }
}
