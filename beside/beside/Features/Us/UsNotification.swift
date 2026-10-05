import Foundation

enum UsNotificationKind: String, Sendable, Equatable {
    case moodReaction
    case loveNote
    case importantDate
    case sharedMemory
}

struct UsNotification: Identifiable, Equatable, Sendable {
    let id: String
    var kind: UsNotificationKind
    var title: String
    var subtitle: String?
    var createdAt: Date
    var read: Bool
    /// Linked entity id (love note / important date / memory / mood share).
    var relatedID: String?
    /// Stable key so the same event is not posted twice.
    var dedupeKey: String

    var timeLabel: String {
        UsNotifications.relativeTimeLabel(from: createdAt)
    }
}

enum UsNotifications {
    static let dateReminderDayThresholds = [7, 3, 1, 0]

    static func relativeTimeLabel(from date: Date, now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 {
            let m = Int(interval / 60)
            return "\(m)m ago"
        }
        if interval < 86_400 {
            let h = Int(interval / 3600)
            return "\(h)h ago"
        }
        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if days < 7 { return "\(max(days, 1))d ago" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func countdownSubtitle(daysUntil: Int) -> String {
        if daysUntil == 0 { return "Today" }
        if daysUntil == 1 { return "Tomorrow" }
        return "In \(daysUntil) days"
    }

    static func demoSeed(
        partnerName: String = "Alex",
        now: Date = Date()
    ) -> [UsNotification] {
        let calendar = Calendar.current
        return [
            UsNotification(
                id: "notif-mood-react",
                kind: .moodReaction,
                title: "\(partnerName) reacted to your mood",
                subtitle: nil,
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                read: false,
                relatedID: nil,
                dedupeKey: "mood-react-seed"
            ),
            UsNotification(
                id: "notif-anniversary",
                kind: .importantDate,
                title: "Upcoming: Our Anniversary",
                subtitle: "In 5 days",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                read: false,
                relatedID: "anniversary",
                dedupeKey: "date-remind-anniversary-d5"
            ),
            UsNotification(
                id: "notif-lovenote",
                kind: .loveNote,
                title: "New love note is waiting",
                subtitle: nil,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                read: true,
                relatedID: "ln-seed-incoming-1",
                dedupeKey: "lovenote-ln-seed-incoming-1"
            ),
        ]
    }
}
