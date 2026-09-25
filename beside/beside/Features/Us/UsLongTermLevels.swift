import Foundation

/// Long-term level ladder for the Us progress bar (Figma Make `US_LONG_TERM_LEVELS`).
enum UsLongTermLevels {
    struct Level: Sendable {
        let level: Int
        let name: String
        let emoji: String
        let pointsToNext: Int
    }

    static let all: [Level] = [
        Level(level: 1, name: "First Spark", emoji: "✨", pointsToNext: 150),
        Level(level: 2, name: "Curious Hearts", emoji: "💛", pointsToNext: 260),
        Level(level: 3, name: "Getting Closer", emoji: "😊", pointsToNext: 370),
        Level(level: 4, name: "Warm Connection", emoji: "☀️", pointsToNext: 480),
        Level(level: 5, name: "Sweet Moments", emoji: "🍯", pointsToNext: 590),
        Level(level: 6, name: "Building Trust", emoji: "🤝", pointsToNext: 700),
        Level(level: 7, name: "Open Conversations", emoji: "💬", pointsToNext: 810),
        Level(level: 8, name: "Emotional Sync", emoji: "💞", pointsToNext: 920),
        Level(level: 9, name: "Deeper Feelings", emoji: "💓", pointsToNext: 1030),
        Level(level: 10, name: "Safe Space", emoji: "🫶", pointsToNext: 1000),
        Level(level: 11, name: "True Interest", emoji: "🌷", pointsToNext: 1100),
        Level(level: 12, name: "Growing Bond", emoji: "🌱", pointsToNext: 1200),
        Level(level: 13, name: "Daily Care", emoji: "☕", pointsToNext: 1400),
        Level(level: 14, name: "Meaningful Talks", emoji: "🧠", pointsToNext: 1500),
        Level(level: 15, name: "Honest Connection", emoji: "💎", pointsToNext: 1600),
        Level(level: 16, name: "Strong Feelings", emoji: "❤️‍🔥", pointsToNext: 1700),
        Level(level: 17, name: "Real Support", emoji: "🤗", pointsToNext: 1800),
        Level(level: 18, name: "Understanding Each Other", emoji: "🧩", pointsToNext: 1900),
        Level(level: 19, name: "Deep Connection", emoji: "💞", pointsToNext: 2000),
        Level(level: 20, name: "Unbreakable Link", emoji: "🔗", pointsToNext: 2100),
        Level(level: 21, name: "Shared World", emoji: "🌍", pointsToNext: 2200),
        Level(level: 22, name: "True Partnership", emoji: "👫", pointsToNext: 2300),
        Level(level: 23, name: "Soul Alignment", emoji: "🌙", pointsToNext: 2400),
        Level(level: 24, name: "Deep Trust", emoji: "🔐", pointsToNext: 2500),
        Level(level: 25, name: "Emotional Intimacy", emoji: "🫀", pointsToNext: 2600),
        Level(level: 26, name: "Pure Love", emoji: "💖", pointsToNext: 2700),
        Level(level: 27, name: "One Team", emoji: "🛡️", pointsToNext: 2800),
        Level(level: 28, name: "Soulmates", emoji: "💍", pointsToNext: 3000),
        Level(level: 29, name: "Lifelong Bond", emoji: "♾️", pointsToNext: 3200),
        Level(level: 30, name: "Infinite Love", emoji: "🌌", pointsToNext: 0),
    ]

    static func name(for level: Int) -> String {
        row(for: level)?.name ?? "First Spark"
    }

    static func emoji(for level: Int) -> String {
        row(for: level)?.emoji ?? "✨"
    }

    static func pointsToNext(for level: Int) -> Int {
        row(for: level)?.pointsToNext ?? 150
    }

    private static func row(for level: Int) -> Level? {
        let clamped = min(30, max(1, level))
        return all.first { $0.level == clamped }
    }
}

/// Figma Make `calculateTimeTogether`.
enum UsTimeTogether {
    static func phrase(since startDate: Date, now: Date = Date()) -> String {
        let diffMs = now.timeIntervalSince(startDate)
        let diffDays = Int(floor(diffMs / (60 * 60 * 24)))
        let years = diffDays / 365
        let months = (diffDays % 365) / 30
        let days = diffDays % 30
        if years > 0 {
            if months > 0 {
                return "together for \(years) year\(years == 1 ? "" : "s") and \(months) month\(months == 1 ? "" : "s")"
            }
            return "together for \(years) year\(years == 1 ? "" : "s")"
        }
        if months > 0 {
            return "together for \(months) month\(months == 1 ? "" : "s")"
        }
        return "together for \(days) day\(days == 1 ? "" : "s")"
    }
}
