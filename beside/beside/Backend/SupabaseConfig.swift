import Foundation

struct SupabaseConfig: Equatable, Sendable {
    var url: URL
    var anonKey: String

    static func loadFromBundle(_ bundle: Bundle = .main) -> SupabaseConfig? {
        guard
            let path = bundle.path(forResource: "SupabaseSecrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = dict["SUPABASE_URL"],
            let url = URL(string: urlString),
            let anonKey = dict["SUPABASE_ANON_KEY"],
            !anonKey.isEmpty,
            !anonKey.contains("YOUR_ANON_KEY"),
            !urlString.contains("YOUR_PROJECT")
        else {
            return nil
        }
        return SupabaseConfig(url: url, anonKey: anonKey)
    }
}
