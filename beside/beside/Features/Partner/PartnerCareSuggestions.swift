import Foundation

/// Display-only care suggestions from Figma Make `PartnerScreen` `reactionsMap`.
enum PartnerCareSuggestions {
    static func lines(for moodID: String) -> [String] {
        map[moodID] ?? map["joy"] ?? []
    }

    static func feelingPhrase(for moodID: String) -> String {
        switch moodID {
        case "calm": return "calm and balanced"
        case "joy": return "joyful"
        case "love": return "loving and connected"
        case "sad": return "sad and vulnerable"
        case "exhausted": return "exhausted"
        case "stressed": return "stressed"
        default:
            return MoodCatalog.mood(id: moodID)?.label.lowercased() ?? "okay"
        }
    }

    private static let map: [String: [String]] = [
        "calm": [
            "🫖 Make them a warm cup of tea",
            "🤫 Give them quiet space nearby",
            "📖 Suggest reading together tonight",
            "🌿 Send a calming playlist",
        ],
        "joy": [
            "🎉 Plan a surprise mini-date tonight",
            "💌 Send a sweet voice message",
            "🎶 Share a song that reminds you of them",
            "🍦 Bring home their favorite treat",
        ],
        "love": [
            "💐 Write them a little love note",
            "📵 Suggest a phone-free evening",
            "🕯️ Set up a cozy atmosphere at home",
            "💬 Tell them what you love about them",
        ],
        "sad": [
            "🤗 Give them a long, warm hug",
            "🎬 Suggest watching their comfort movie",
            "🍫 Bring their favorite comfort food",
            "💬 Ask how you can help today",
        ],
        "exhausted": [
            "🍽️ Handle dinner tonight",
            "🛁 Run a warm bath for them",
            "📱 Don't expect quick replies today",
            "🧹 Take over chores without asking",
        ],
        "stressed": [
            "👂 Listen without trying to fix things",
            "🧘 Suggest a short breathing exercise together",
            "🚶 Offer a calming walk outside",
            "💆 Give them a shoulder massage",
        ],
    ]
}
