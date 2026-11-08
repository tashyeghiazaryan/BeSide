import Foundation

/// Short warm line for the Instagram Stories couple sticker — one phrase per calendar day.
enum UsCoupleShareWarmth {
    private static let lines: [String] = [
        "still choosing each other",
        "quiet days count too",
        "same team, always",
        "our ordinary magic",
        "held, not rushed",
        "day by day is enough",
        "this is the soft part",
        "home is a person",
        "little days, big love",
        "still us",
        "close in the quiet",
        "side by side",
        "warmth over noise",
        "together, simply",
        "chosen again today",
        "soft place to land",
        "our time, unhurried",
        "gentle on purpose",
        "keeping the light on",
        "two hearts, one pace",
    ]

    static func line(for day: Date = Date(), calendar: Calendar = .current) -> String {
        let dayIndex = calendar.ordinality(of: .day, in: .era, for: day) ?? 0
        return lines[abs(dayIndex) % lines.count]
    }
}
