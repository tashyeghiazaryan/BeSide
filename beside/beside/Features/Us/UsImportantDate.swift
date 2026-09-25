import Foundation
import SwiftUI

struct UsImportantDate: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable {
        case nextDate
        case anniversary
        case birthday
        case special
        case valentines
        case newYear
        case custom
    }

    let id: String
    var title: String
    var date: Date
    var kind: Kind
    /// Accent for list icon bubble (hex without alpha).
    var accentHex: UInt32

    var accentColor: Color { Color(hex: accentHex) }

    var systemImage: String {
        switch kind {
        case .nextDate, .special, .custom: return "sparkles"
        case .anniversary, .valentines: return "heart.fill"
        case .birthday: return "gift.fill"
        case .newYear: return "sparkles"
        }
    }
}

enum UsImportantDates {
    static func daysUntil(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: target).day ?? 0
    }

    static func nextAnnualOccurrence(of date: Date, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: today)
        var comps = DateComponents(year: year, month: month, day: day)
        var candidate = calendar.date(from: comps) ?? date
        if candidate < today {
            comps.year = year + 1
            candidate = calendar.date(from: comps) ?? candidate
        }
        return calendar.startOfDay(for: candidate)
    }

    static func countdownLabel(_ daysUntil: Int) -> String {
        if daysUntil == 0 { return "Today" }
        if daysUntil == 1 { return "Tomorrow" }
        if daysUntil < 0 {
            let ago = abs(daysUntil)
            if ago == 1 { return "Yesterday" }
            return "\(ago)d ago"
        }
        return "in \(daysUntil) days"
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func monthYearLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    /// Monday-start calendar cells for month (nil = padding).
    static func dayCells(year: Int, month: Int, calendar: Calendar = .current) -> [Int?] {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        guard let first = cal.date(from: DateComponents(year: year, month: month, day: 1)) else { return [] }
        let range = cal.range(of: .day, in: .month, for: first) ?? 1..<31
        let weekday = cal.component(.weekday, from: first)
        // weekday: 1=Sun … 7=Sat; convert to Mon=0 … Sun=6
        let startPad = (weekday + 5) % 7
        var cells: [Int?] = Array(repeating: nil, count: startPad)
        for d in range { cells.append(d) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    static func makeSeedDates(
        relationshipStart: Date,
        partnerName: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [UsImportantDate] {
        let start = calendar.startOfDay(for: now)
        let nextTogether = calendar.date(byAdding: .day, value: 10, to: start) ?? start

        var birthdayComps = DateComponents()
        birthdayComps.year = 1998
        birthdayComps.month = 3
        birthdayComps.day = 18
        let birthday = calendar.date(from: birthdayComps) ?? relationshipStart

        var specialComps = DateComponents()
        specialComps.year = 2022
        specialComps.month = 3
        specialComps.day = 13
        let special = calendar.date(from: specialComps) ?? relationshipStart

        var valComps = DateComponents()
        valComps.year = 2022
        valComps.month = 2
        valComps.day = 14
        let valentines = calendar.date(from: valComps) ?? relationshipStart

        var nyeComps = DateComponents()
        nyeComps.year = 2022
        nyeComps.month = 1
        nyeComps.day = 1
        let newYear = calendar.date(from: nyeComps) ?? relationshipStart

        return [
            UsImportantDate(
                id: "next-soon",
                title: "Next date together",
                date: nextTogether,
                kind: .nextDate,
                accentHex: 0xFF555D
            ),
            UsImportantDate(
                id: "anniversary",
                title: "Our Anniversary",
                date: nextAnnualOccurrence(of: relationshipStart, now: now, calendar: calendar),
                kind: .anniversary,
                accentHex: 0xFF555D
            ),
            UsImportantDate(
                id: "birthday",
                title: "\(partnerName)'s Birthday",
                date: nextAnnualOccurrence(of: birthday, now: now, calendar: calendar),
                kind: .birthday,
                accentHex: 0xA78BFA
            ),
            UsImportantDate(
                id: "special-day",
                title: "Our First Date",
                date: nextAnnualOccurrence(of: special, now: now, calendar: calendar),
                kind: .special,
                accentHex: 0xFF555D
            ),
            UsImportantDate(
                id: "valentines",
                title: "Valentine's Day",
                date: nextAnnualOccurrence(of: valentines, now: now, calendar: calendar),
                kind: .valentines,
                accentHex: 0xFF555D
            ),
            UsImportantDate(
                id: "new-year",
                title: "New Year",
                date: nextAnnualOccurrence(of: newYear, now: now, calendar: calendar),
                kind: .newYear,
                accentHex: 0x60A5FA
            ),
        ]
    }
}
