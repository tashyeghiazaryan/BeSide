import Foundation
import Observation

struct SharedMood: Identifiable, Hashable, Sendable {
    let id: UUID
    let moodID: String
    let wish: String
    let timestamp: Date
    /// Emoji reaction from the partner (Figma Make chip on Me).
    var partnerReaction: String?
    /// Optional short note from the partner with the reaction.
    var partnerNote: String?

    init(
        id: UUID = UUID(),
        moodID: String,
        wish: String,
        timestamp: Date,
        partnerReaction: String? = nil,
        partnerNote: String? = nil
    ) {
        self.id = id
        self.moodID = moodID
        self.wish = wish
        self.timestamp = timestamp
        self.partnerReaction = partnerReaction
        self.partnerNote = partnerNote
    }

    var mood: Mood? {
        MoodCatalog.mood(id: moodID)
    }

    var hasPartnerResponse: Bool {
        partnerReaction != nil || !(partnerNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

enum SharePhase: Equatable, Sendable {
    case idle
    case sending
    case sent
}

@Observable
@MainActor
final class MeSessionStore {
    var selectedMoodID: String?
    var selectedWish: String?
    var customWishText: String = ""
    var sharePhase: SharePhase = .idle
    var history: [SharedMood]
    var expandedDayKey: String?
    var activeAlert: WishShareAlert?

    var displayName = "Anna"
    var partnerDisplayName = "Alex"

    /// Partner's latest mood (Partner tab). Separate from your Me history.
    var partnerCurrentMood: SharedMood
    /// Your emoji reaction to the partner's mood.
    var myReactionToPartner: String?
    /// Your short note about the partner's mood.
    var myNoteToPartner: String?

    init(history: [SharedMood]? = nil, partnerCurrentMood: SharedMood? = nil) {
        self.history = history ?? Self.makeSeedHistory()
        self.partnerCurrentMood = partnerCurrentMood ?? Self.makeSeedPartnerMood()
        if let response = Self.seedMyResponseToPartner {
            self.myReactionToPartner = response.reaction
            self.myNoteToPartner = response.note
        }
    }

    var hasResponseToPartner: Bool {
        myReactionToPartner != nil
            || !(myNoteToPartner?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    /// You react + optionally note the partner's mood (Partner tab).
    func respondToPartnerMood(reaction: String, note: String?) {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let limitedNote: String?
        if let trimmedNote, !trimmedNote.isEmpty {
            limitedNote = PartnerNoteRules.limitLength(trimmedNote)
        } else {
            limitedNote = nil
        }
        myReactionToPartner = reaction
        myNoteToPartner = limitedNote
    }

    /// Incoming: partner reacts to your latest Me share.
    func applyPartnerResponse(reaction: String, note: String?) {
        guard !history.isEmpty else { return }
        let trimmedNote = note?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let limitedNote: String?
        if let trimmedNote, !trimmedNote.isEmpty {
            limitedNote = PartnerNoteRules.limitLength(trimmedNote)
        } else {
            limitedNote = nil
        }
        history[history.count - 1].partnerReaction = reaction
        history[history.count - 1].partnerNote = limitedNote
    }

    var selectedMood: Mood? {
        guard let selectedMoodID else { return nil }
        return MoodCatalog.mood(id: selectedMoodID)
    }

    var currentSharedMood: SharedMood? {
        history.last
    }

    /// Your shares that the partner reacted to (oldest first — dialogue order).
    var partnerResponseHistory: [SharedMood] {
        history
            .filter(\.hasPartnerResponse)
            .sorted { $0.timestamp < $1.timestamp }
    }

    var wishesForSelection: [String] {
        guard let selectedMoodID else { return [] }
        return MoodCatalog.wishes(for: selectedMoodID)
    }

    /// True when a valid preset or custom wish is ready to send.
    var canShare: Bool {
        guard sharePhase == .idle, selectedMoodID != nil,
              let wish = selectedWish?.trimmingCharacters(in: .whitespacesAndNewlines),
              !wish.isEmpty
        else { return false }
        if wishesForSelection.contains(wish) { return true }
        return WishTextRules.isValidShareWish(wish)
    }

    /// Share control is tappable whenever a mood is selected (validation alerts on tap).
    var canAttemptShare: Bool {
        selectedMoodID != nil && sharePhase == .idle
    }

    func selectMood(_ mood: Mood) {
        guard sharePhase == .idle else { return }
        if selectedMoodID == mood.id {
            selectedMoodID = nil
            selectedWish = nil
            customWishText = ""
        } else {
            selectedMoodID = mood.id
            selectedWish = nil
            customWishText = ""
        }
        activeAlert = nil
    }

    func selectWish(_ wish: String) {
        guard sharePhase == .idle, selectedMoodID != nil else { return }
        selectedWish = wish
        customWishText = ""
        activeAlert = nil
    }

    func updateCustomWish(_ text: String) {
        guard sharePhase == .idle, selectedMoodID != nil else { return }
        // Keep typed text (max 80). Charset is checked only when Share is pressed.
        let limited = WishTextRules.limitLength(WishTextRules.normalizeInput(text))
        customWishText = limited
        let trimmed = limited.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedWish = trimmed.isEmpty ? nil : trimmed
        activeAlert = nil
    }

    func toggleDay(_ key: String, hasEntries: Bool) {
        guard hasEntries else { return }
        expandedDayKey = expandedDayKey == key ? nil : key
    }

    func share() async {
        guard let moodID = selectedMoodID, sharePhase == .idle else { return }

        let presets = wishesForSelection
        let trimmedCustom = WishTextRules.normalizeInput(customWishText)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCustomText = !trimmedCustom.isEmpty

        // Inline errors only after Share tap.
        if hasCustomText, !WishTextRules.isValidShareWish(customWishText) {
            activeAlert = .invalidWish
            return
        }

        let candidate = hasCustomText
            ? trimmedCustom
            : selectedWish?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let wish = candidate, !wish.isEmpty else {
            activeAlert = .emptyWish
            return
        }

        let isPreset = presets.contains(wish)
        if !isPreset, !WishTextRules.isValidShareWish(wish) {
            activeAlert = .invalidWish
            return
        }

        sharePhase = .sending
        activeAlert = nil
        try? await Task.sleep(for: .milliseconds(1200))
        let entry = SharedMood(moodID: moodID, wish: wish, timestamp: Date())
        history.append(entry)
        sharePhase = .sent
        try? await Task.sleep(for: .seconds(2))
        selectedMoodID = nil
        selectedWish = nil
        customWishText = ""
        sharePhase = .idle
    }

    struct DayBucket: Identifiable {
        let id: String
        let label: String
        let isToday: Bool
        let entries: [SharedMood]
    }

    func weekBuckets(now: Date = Date()) -> [DayBucket] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        var buckets: [DayBucket] = []

        for offset in (0...6).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let key = Self.dayKey(day, calendar: calendar)
            let isToday = offset == 0
            let label: String
            if isToday {
                label = "Today"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "EEE"
                label = formatter.string(from: day)
            }
            let entries = history
                .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .sorted { $0.timestamp < $1.timestamp }
            buckets.append(DayBucket(id: key, label: label, isToday: isToday, entries: entries))
        }
        return buckets
    }

    nonisolated static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    nonisolated static func makeSeedPartnerMood(now: Date = Date()) -> SharedMood {
        let calendar = Calendar.current
        var date = calendar.date(bySettingHour: 9, minute: 40, second: 0, of: now) ?? now
        if calendar.component(.hour, from: now) < 9 {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return SharedMood(
            moodID: "joy",
            wish: "Let's celebrate small wins together.",
            timestamp: date
        )
    }

    /// Demo: you already left a light response on partner's mood (optional empty for first-run feel).
    nonisolated private static var seedMyResponseToPartner: (reaction: String, note: String)? {
        nil
    }

    nonisolated static func makeSeedHistory(now: Date = Date()) -> [SharedMood] {
        let calendar = Calendar.current
        let seeds: [(daysAgo: Int, moodID: String, wish: String, hour: Int, minute: Int)] = [
            (6, "joy", "Let's celebrate small wins together.", 8, 0),
            (5, "calm", "Let's just sit together in silence.", 10, 15),
            (5, "love", "Let's just talk about us.", 20, 30),
            (4, "stressed", "Just listen without judging.", 14, 0),
            (3, "sad", "I want hugs.", 9, 0),
            (3, "calm", "I'm feeling grounded — I can help you with something.", 17, 0),
            (2, "joy", "Go for a walk or a run together.", 7, 0),
            (2, "love", "Let's have a date / time without phones.", 19, 45),
            (2, "calm", "Let's do something calm together (read, puzzle, cook).", 22, 30),
            (1, "exhausted", "Don't be upset if I stay quiet.", 11, 0),
            // Today — enough moods to exercise the day-dropdown scroll (≥5).
            (0, "calm", "Let's just sit together in silence.", 8, 10),
            (0, "joy", "Let's celebrate small wins together.", 10, 5),
            (0, "love", "Let's just talk about us.", 12, 40),
            (0, "stressed", "Just listen without judging.", 15, 20),
            (0, "sad", "I want hugs.", 17, 55),
            (0, "exhausted", "Don't be upset if I stay quiet.", 20, 15),
        ]

        let responses: [Int: (reaction: String, note: String)] = [
            seeds.count - 1: ("🤗", "Rest today. I got dinner."),
            7: ("❤️", "Miss our phone-free evenings."),
            4: ("💐", "Sending you a big hug."),
            1: ("😊", "Love when we sit quietly."),
        ]

        return seeds.enumerated().compactMap { index, seed in
            guard MoodCatalog.mood(id: seed.moodID) != nil else { return nil }
            var date = calendar.date(byAdding: .day, value: -seed.daysAgo, to: now) ?? now
            date = calendar.date(bySettingHour: seed.hour, minute: seed.minute, second: 0, of: date) ?? date
            let response = responses[index]
            return SharedMood(
                moodID: seed.moodID,
                wish: seed.wish,
                timestamp: date,
                partnerReaction: response?.reaction,
                partnerNote: response?.note
            )
        }
    }
}
