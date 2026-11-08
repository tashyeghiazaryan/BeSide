import Foundation

/// Quiet together-milestone ladder for Us (Figma Make `US_LONG_TERM_LEVELS`).
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

/// Figma Make `calculateTimeTogether` — display styles cycle on Us hero tap.
enum UsTimeTogether {
    /// Cycle order on tap: detailed → days only → since date.
    enum Style: String, CaseIterable, Sendable {
        case detailed
        case daysOnly
        case sinceDate

        var next: Style {
            switch self {
            case .detailed: return .daysOnly
            case .daysOnly: return .sinceDate
            case .sinceDate: return .detailed
            }
        }
    }

    private static let sinceFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    /// Calendar breakdown for share-card counters (Full look).
    struct Breakdown: Equatable, Sendable {
        var years: Int
        var months: Int
        var days: Int
        /// Total whole days since start (Days look).
        var totalDays: Int
        var sinceLabel: String
    }

    static func breakdown(
        since startDate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Breakdown {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: now)
        let parts = calendar.dateComponents([.year, .month, .day], from: start, to: end)
        let totalDays = max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        return Breakdown(
            years: max(0, parts.year ?? 0),
            months: max(0, parts.month ?? 0),
            days: max(0, parts.day ?? 0),
            totalDays: totalDays,
            sinceLabel: sinceFormatter.string(from: start)
        )
    }

    static func phrase(
        since startDate: Date,
        style: Style = .detailed,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let parts = breakdown(since: startDate, now: now, calendar: calendar)

        switch style {
        case .daysOnly:
            let days = parts.totalDays
            return "together for \(days) day\(days == 1 ? "" : "s")"
        case .sinceDate:
            return "since \(parts.sinceLabel)"
        case .detailed:
            var chunks: [String] = []
            if parts.years > 0 {
                chunks.append("\(parts.years) year\(parts.years == 1 ? "" : "s")")
            }
            if parts.months > 0 {
                chunks.append("\(parts.months) month\(parts.months == 1 ? "" : "s")")
            }
            if parts.days > 0 || chunks.isEmpty {
                chunks.append("\(parts.days) day\(parts.days == 1 ? "" : "s")")
            }
            return "together for \(chunks.joined(separator: ", "))"
        }
    }
}
