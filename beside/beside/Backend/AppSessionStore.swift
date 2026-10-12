import Foundation
import Observation

enum AppSessionPhase: Equatable {
    case loading
    case needsAuth
    case authenticated
    case demo
}

@Observable
@MainActor
final class AppSessionStore {
    var phase: AppSessionPhase = .loading
    var coupleContext: CoupleContext?
    var lastError: String?
    /// Demo / cached account email for Edit profile.
    var accountEmail: String = "anna@beside.app"

    private let auth: AuthService?
    private let couples: CoupleService?
    private let usesLiveBackend: Bool

    init(
        auth: AuthService? = nil,
        couples: CoupleService? = nil,
        usesLiveBackend: Bool = false
    ) {
        self.auth = auth
        self.couples = couples
        self.usesLiveBackend = usesLiveBackend
    }

    static func makeDefault() -> AppSessionStore {
        let backend = AppBackend.shared
        guard backend.isLiveConfigured,
              let client = SupabaseClientProvider.client(config: backend.supabaseConfig) else {
            return AppSessionStore(usesLiveBackend: false)
        }
        return AppSessionStore(
            auth: SupabaseAuthService(client: client),
            couples: SupabaseCoupleService(client: client),
            usesLiveBackend: true
        )
    }

    func bootstrap() async {
        lastError = nil
        guard usesLiveBackend, let auth else {
            phase = .demo
            coupleContext = .demo
            return
        }

        phase = .loading
        if await auth.currentSessionUserId() == nil {
            phase = .needsAuth
            coupleContext = nil
            return
        }

        await refreshCoupleContext()
        await refreshAccountEmail()
        phase = .authenticated
    }

    func requestOTP(email: String) async throws {
        guard let auth else { throw AuthServiceError.notConfigured }
        lastError = nil
        try await auth.signInWithOTP(email: email)
    }

    func verifyOTP(email: String, token: String) async throws {
        guard let auth else { throw AuthServiceError.notConfigured }
        lastError = nil
        try await auth.verifyOTP(email: email, token: token)
        await refreshCoupleContext()
        await refreshAccountEmail()
        phase = .authenticated
    }

    /// Password path for when project email rate limit blocks OTP.
    func signInWithPassword(email: String, password: String, createIfNeeded: Bool) async throws {
        guard let auth else { throw AuthServiceError.notConfigured }
        lastError = nil
        if createIfNeeded {
            try await auth.signUpWithPassword(email: email, password: password)
        } else {
            try await auth.signInWithPassword(email: email, password: password)
        }
        guard await auth.currentSessionUserId() != nil else {
            throw AuthServiceError.underlying(
                "No session yet. In Supabase → Auth → Providers → Email, turn OFF “Confirm email”, then try again."
            )
        }
        await refreshCoupleContext()
        await refreshAccountEmail()
        phase = .authenticated
    }

    func updateAccountEmail(_ email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else {
            throw AuthServiceError.invalidEmail
        }
        if let auth, usesLiveBackend {
            try await auth.updateEmail(trimmed)
        }
        accountEmail = trimmed
    }

    func updateDisplayName(_ displayName: String) async throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CoupleServiceError.underlying("Name can’t be empty.")
        }
        if let couples, usesLiveBackend {
            try await couples.updateDisplayName(trimmed)
            await refreshCoupleContext()
        } else if var context = coupleContext {
            context.displayName = trimmed
            coupleContext = context
        }
    }

    func leaveCouple() async throws {
        if let couples, usesLiveBackend {
            try await couples.leaveCouple()
            await refreshCoupleContext()
        } else if var context = coupleContext {
            context.coupleId = nil
            context.partnerUserId = nil
            context.partnerDisplayName = nil
            context.inviteCode = nil
            coupleContext = context
        }
    }

    func setRelationshipStart(_ date: Date) async throws {
        if let couples, usesLiveBackend {
            try await couples.setRelationshipStart(date)
        }
    }

    func signOut() async {
        lastError = nil
        try? await auth?.signOut()
        coupleContext = nil
        phase = usesLiveBackend ? .needsAuth : .demo
    }

    private func refreshAccountEmail() async {
        if let email = await auth?.currentSessionEmail(), !email.isEmpty {
            accountEmail = email
        }
    }

    func createCouple(displayName: String) async throws -> String {
        guard let couples else { throw CoupleServiceError.notConfigured }
        lastError = nil
        let (context, code) = try await couples.createCouple(displayName: displayName)
        coupleContext = context
        return code
    }

    func joinCouple(code: String) async throws {
        guard let couples else { throw CoupleServiceError.notConfigured }
        lastError = nil
        coupleContext = try await couples.joinCouple(code: code)
    }

    func refreshCoupleContext() async {
        guard let couples else { return }
        do {
            coupleContext = try await couples.fetchContext()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
