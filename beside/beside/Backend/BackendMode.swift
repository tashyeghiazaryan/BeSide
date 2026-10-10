import Foundation

/// Selects session-demo behavior vs live Supabase.
/// Flip to `.supabase` after secrets + package + migrations are ready.
enum BackendMode: String, Sendable {
    case demo
    case supabase
}

enum BackendConfiguration {
    /// Prefer Supabase when secrets are present; override with `BESIDE_BACKEND_MODE=demo|supabase`.
    static var mode: BackendMode {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["BESIDE_BACKEND_MODE"],
           let mode = BackendMode(rawValue: override) {
            return mode
        }
        #endif
        if SupabaseConfig.loadFromBundle() != nil {
            return .supabase
        }
        return .demo
    }

    static var usesSupabase: Bool { mode == .supabase }
}
