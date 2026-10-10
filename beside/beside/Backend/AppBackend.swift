import Foundation

/// Composition root for backend services. UI keeps using `MeSessionStore` until
/// repositories are wired feature-by-feature (see OpenSpec `add-supabase-backend`).
@MainActor
final class AppBackend {
    static let shared = AppBackend()

    let mode: BackendMode
    let supabaseConfig: SupabaseConfig?

    private init() {
        mode = BackendConfiguration.mode
        supabaseConfig = SupabaseConfig.loadFromBundle()
    }

    var isLiveConfigured: Bool {
        mode == .supabase && supabaseConfig != nil
    }

    /// Call at launch to log misconfiguration early (DEBUG).
    func validateLaunchConfiguration() {
        #if DEBUG
        if mode == .supabase && supabaseConfig == nil {
            print("""
            [BeSide] BackendMode.supabase but SupabaseSecrets.plist missing or incomplete.
            Copy Backend/SupabaseSecrets.example.plist → SupabaseSecrets.plist and fill URL + anon key.
            Falling back to demo behavior until secrets exist.
            """)
        }
        #endif
    }
}
