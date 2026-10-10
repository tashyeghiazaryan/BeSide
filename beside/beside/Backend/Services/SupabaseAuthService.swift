import Foundation
import Supabase

enum AuthServiceError: LocalizedError {
    case notConfigured
    case invalidEmail
    case invalidOTP
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase is not configured."
        case .invalidEmail: return "Enter a valid email address."
        case .invalidOTP: return "Enter the 6-digit code from your email."
        case .underlying(let message): return message
        }
    }
}

final class SupabaseAuthService: AuthService, @unchecked Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func currentSessionUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }

    func signInWithOTP(email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else {
            throw AuthServiceError.invalidEmail
        }
        do {
            // No redirect — iOS enters the 6-digit code from the email (not the magic link).
            try await client.auth.signInWithOTP(
                email: trimmed,
                redirectTo: nil,
                shouldCreateUser: true
            )
        } catch {
            let raw = error.localizedDescription
            if raw.localizedCaseInsensitiveContains("rate limit") {
                throw AuthServiceError.underlying(
                    "Too many emails sent. Wait about an hour, or try a different email."
                )
            }
            throw AuthServiceError.underlying(raw)
        }
    }

    func verifyOTP(email: String, token: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        // Digits only — ignore spaces; magic-link tokens are not accepted here.
        let code = token.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter(\.isNumber)
        guard code.count == 6 else { throw AuthServiceError.invalidOTP }
        do {
            // New accounts often arrive as `signup`; returning users as `email`.
            do {
                _ = try await client.auth.verifyOTP(
                    email: trimmedEmail,
                    token: code,
                    type: .email
                )
            } catch {
                _ = try await client.auth.verifyOTP(
                    email: trimmedEmail,
                    token: code,
                    type: .signup
                )
            }
        } catch {
            throw AuthServiceError.underlying(
                "Code invalid or expired. Request a new code in the app — don’t open the email link."
            )
        }
    }

    func signUpWithPassword(email: String, password: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), password.count >= 6 else {
            throw AuthServiceError.underlying("Use a valid email and password (6+ characters).")
        }
        do {
            _ = try await client.auth.signUp(email: trimmed, password: password)
            // If email confirm is on, session may be nil — try password sign-in next.
            if await currentSessionUserId() == nil {
                do {
                    _ = try await client.auth.signIn(email: trimmed, password: password)
                } catch {
                    throw AuthServiceError.underlying(
                        "Account may need email confirm. In Supabase → Auth → Providers → Email, turn OFF “Confirm email”, Save, then tap Create account / sign in again."
                    )
                }
            }
        } catch {
            let raw = error.localizedDescription
            if raw.localizedCaseInsensitiveContains("rate limit") {
                throw AuthServiceError.underlying(
                    "Still blocked by email limit (Confirm email sends mail). Turn OFF “Confirm email” in Supabase Auth → Providers → Email, wait a bit, then try password again."
                )
            }
            if raw.localizedCaseInsensitiveContains("already") || raw.localizedCaseInsensitiveContains("registered") {
                try await signInWithPassword(email: trimmed, password: password)
                return
            }
            throw AuthServiceError.underlying(raw)
        }
    }

    func signInWithPassword(email: String, password: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), !password.isEmpty else {
            throw AuthServiceError.invalidEmail
        }
        do {
            _ = try await client.auth.signIn(email: trimmed, password: password)
        } catch {
            throw AuthServiceError.underlying(error.localizedDescription)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthServiceError.underlying(error.localizedDescription)
        }
    }
}
