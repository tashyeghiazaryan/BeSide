import SwiftUI

enum SmokePattern: String, Sendable {
    case floating
    case swirling
    case expanding
    case falling
    case chaotic
}

struct Mood: Identifiable, Sendable {
    let id: String
    let name: String
    let label: String
    let color: Color
    let gradientColors: [Color]
    let icon: MoodIconKind
    let smokePattern: SmokePattern
}

enum MoodCatalog {
    static let all: [Mood] = [
        Mood(
            id: "calm",
            name: "Calm & Balanced",
            label: "Calm",
            color: Color(hex: 0x98D8C8),
            gradientColors: [
                Color(hex: 0x98D8C8),
                Color(hex: 0xB0E0E6),
                Color(hex: 0xF0F8FF),
            ],
            icon: .leaf,
            smokePattern: .floating
        ),
        Mood(
            id: "joy",
            name: "Joy & High Energy",
            label: "Joy",
            // Warm honey yellow (no cool purple/blue wash — those muddied the sphere)
            color: Color(hex: 0xFFC447),
            gradientColors: [
                Color(hex: 0xFFE9A8),
                Color(hex: 0xFFD56A),
                Color(hex: 0xFFC447),
                Color(hex: 0xFFB347),
            ],
            icon: .sparkles,
            smokePattern: .swirling
        ),
        Mood(
            id: "love",
            name: "Love & Connection",
            label: "Love",
            color: Color(hex: 0xE53E3E),
            gradientColors: [
                Color(hex: 0xFF1744),
                Color(hex: 0xE53E3E),
                Color(hex: 0xFF5252),
            ],
            icon: .heart,
            smokePattern: .expanding
        ),
        Mood(
            id: "sad",
            name: "Sad & Vulnerable",
            label: "Sad",
            color: Color(hex: 0x4682B4),
            gradientColors: [
                Color(hex: 0x708090),
                Color(hex: 0x4682B4),
                Color(hex: 0x5F9EA0),
            ],
            icon: .cloud,
            smokePattern: .falling
        ),
        Mood(
            id: "exhausted",
            name: "Exhausted & Low Battery",
            label: "Exhausted",
            color: Color(hex: 0xB0C4DE),
            gradientColors: [
                Color(hex: 0xDCDCDC),
                Color(hex: 0xB0C4DE),
                Color(hex: 0xD3D3D3),
            ],
            icon: .battery,
            smokePattern: .falling
        ),
        Mood(
            id: "stressed",
            name: "Stressed & Irritated",
            label: "Stressed",
            color: Color(hex: 0xFF8C00),
            gradientColors: [
                Color(hex: 0xFF6B00),
                Color(hex: 0xFF8C00),
                Color(hex: 0xFFA040),
            ],
            icon: .zap,
            smokePattern: .chaotic
        ),
    ]

    static let wishesByMoodID: [String: [String]] = [
        "calm": [
            "Let's just sit together in silence.",
            "I'm feeling grounded — I can help you with something.",
            "Let's do something calm together (read, puzzle, cook).",
        ],
        "joy": [
            "Go for a walk or a run together.",
            "Share a funny story or meme.",
            "Let's celebrate small wins together.",
        ],
        "love": [
            "Let's have a date / time without phones.",
            "I want to be intimate / have sex.",
            "Let's just talk about us.",
        ],
        "sad": [
            "I want hugs.",
            "Let's change the scenery (walk/movie).",
            "I need a little support and words of love.",
        ],
        "exhausted": [
            "Take care of the chores today.",
            "Don't be upset if I stay quiet.",
            "Make me tea / bring me something to eat.",
        ],
        "stressed": [
            "I need a few minutes to calm down.",
            "Help me with small tasks while I relax.",
            "Just listen without judging.",
        ],
    ]

    static func mood(id: String) -> Mood? {
        all.first { $0.id == id }
    }

    static func wishes(for moodID: String) -> [String] {
        wishesByMoodID[moodID] ?? []
    }
}
