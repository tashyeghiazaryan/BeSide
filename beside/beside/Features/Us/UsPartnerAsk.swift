import Foundation

/// Day-scoped Little Thing — either partner asks you, or you ask them.
struct UsPartnerAsk: Identifiable, Hashable, Sendable {
    /// Max asks you can create for your partner on one calendar day (done still counts).
    static let maxFromMePerDay = 5

    enum Author: String, Hashable, Sendable {
        /// I asked my partner (e.g. Anna → “Make me a coffee”).
        case me
        /// Partner asked me (e.g. Alex → “Do the dishes”).
        case partner
    }

    let id: String
    var body: String
    /// Who wrote this ask.
    var author: Author
    /// Calendar day this ask belongs to (start of day). Not tied to event dates.
    var day: Date
    var createdAt: Date
    /// When the assignee marked this done (nil = still open).
    var completedAt: Date?

    var isDone: Bool { completedAt != nil }

    /// The person who should do it is the other one than the author.
    var isAssignedToMe: Bool { author == .partner }

    /// Total asks you authored that day — completed ones still use a slot.
    static func countFromMe(
        on day: Date,
        from asks: [UsPartnerAsk],
        calendar: Calendar = .current
    ) -> Int {
        let target = calendar.startOfDay(for: day)
        return asks.filter {
            calendar.isDate($0.day, inSameDayAs: target)
                && $0.author == .me
        }.count
    }

    static func canAddFromMe(
        on day: Date,
        from asks: [UsPartnerAsk],
        calendar: Calendar = .current
    ) -> Bool {
        countFromMe(on: day, from: asks, calendar: calendar) < maxFromMePerDay
    }

    static func demoSeed(now: Date = Date(), calendar: Calendar = .current) -> [UsPartnerAsk] {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let inTwo = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        return [
            UsPartnerAsk(
                id: "ask-coffee",
                body: "Make me a coffee",
                author: .me,
                day: today,
                createdAt: now,
                completedAt: nil
            ),
            UsPartnerAsk(
                id: "ask-dishes",
                body: "Do the dishes",
                author: .partner,
                day: today,
                createdAt: now.addingTimeInterval(-3600),
                completedAt: nil
            ),
            UsPartnerAsk(
                id: "ask-flowers",
                body: "Pick up flowers",
                author: .me,
                day: tomorrow,
                createdAt: now,
                completedAt: nil
            ),
            UsPartnerAsk(
                id: "ask-groceries",
                body: "Grab groceries",
                author: .partner,
                day: inTwo,
                createdAt: now,
                completedAt: nil
            ),
        ]
    }

    static func asks(
        on day: Date,
        from asks: [UsPartnerAsk],
        calendar: Calendar = .current
    ) -> [UsPartnerAsk] {
        let target = calendar.startOfDay(for: day)
        return asks
            .filter { calendar.isDate($0.day, inSameDayAs: target) }
            .sorted { a, b in
                if a.isDone != b.isDone { return !a.isDone && b.isDone }
                return a.createdAt > b.createdAt
            }
    }
}
