import Foundation

struct LoveNote: Identifiable, Equatable, Sendable {
    let id: String
    let body: String
    let createdAt: Date
    let direction: Direction
    var status: Status
    var readAt: Date?

    enum Direction: String, Sendable {
        case incoming, outgoing
    }

    enum Status: String, Sendable {
        case sent, read
    }
}

enum LoveNoteBody {
    static let maxLength = 100

    static func characterCount(_ text: String) -> Int {
        Array(text).count
    }

    static func sanitize(_ raw: String) -> String {
        var out = ""
        for ch in raw {
            guard isAllowed(ch) else { continue }
            if characterCount(out) >= maxLength { break }
            out.append(ch)
        }
        return out
    }

    static func preview(_ body: String, max: Int = 52) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard trimmed.count > max else { return trimmed }
        return String(trimmed.prefix(max).trimmingCharacters(in: .whitespacesAndNewlines)) + "…"
    }

    private static func isAllowed(_ ch: Character) -> Bool {
        guard let scalar = ch.unicodeScalars.first else { return false }
        let v = scalar.value
        if v >= 0x20 && v <= 0x7E { return true }
        if v == 0x00A0 || v == 0x2019 || v == 0x2018 || v == 0x201C || v == 0x201D { return true }
        if v == 0x2026 || v == 0x2014 || v == 0x2013 { return true }
        if scalar.properties.isEmoji { return true }
        return false
    }
}

extension LoveNote {
    static func demoSeed() -> [LoveNote] {
        let now = Date()
        let calendar = Calendar.current
        return [
            LoveNote(
                id: "ln-seed-incoming-1",
                body: "Hey you — just thinking of you. Hope this makes you smile today.",
                createdAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                direction: .incoming,
                status: .sent
            ),
            LoveNote(
                id: "ln-seed-incoming-2",
                body: "Can't wait to see you tonight 💛",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                direction: .incoming,
                status: .read,
                readAt: calendar.date(byAdding: .hour, value: -20, to: now)
            ),
        ]
    }

    static func formatSentAt(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
