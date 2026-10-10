import Foundation
import Supabase

enum SupabaseClientProvider {
    private static var cached: SupabaseClient?

    static func client(config: SupabaseConfig? = SupabaseConfig.loadFromBundle()) -> SupabaseClient? {
        if let cached { return cached }
        guard let config else { return nil }
        let client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        cached = client
        return client
    }

    static func reset() {
        cached = nil
    }
}
