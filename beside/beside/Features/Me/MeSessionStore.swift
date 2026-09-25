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
    /// Partner mood shares for the week strip (includes current).
    var partnerHistory: [SharedMood]
    var expandedPartnerDayKey: String?
    /// Demo default paired so Partner mood UI is reachable (Figma invite modal still supported).
    var isPaired: Bool = true
    var inviteCode: String = "BESIDE-4K2M"
    /// Your emoji reaction to the partner's mood.
    var myReactionToPartner: String?
    /// Your short note about the partner's mood.
    var myNoteToPartner: String?

    // MARK: - Us home (local seeds; no network)

    /// Relationship start for “together for …” (Figma Make default: 14 Mar 2022).
    var relationshipStartDate: Date
    /// Long-term connection level 1…30 (demo default 7).
    var usLongTermLevel: Int
    /// Points toward the next level (demo default 420).
    var usLongTermPoints: Int
    /// Current daily streak days (demo default 3).
    var usStreakDays: Int
    /// Couples prompt completion today (you / partner) — demo both incomplete.
    var meActivityDoneToday: Bool
    var partnerActivityDoneToday: Bool
    /// Important dates for Us (seeded + user-added this session).
    var importantDates: [UsImportantDate]

    /// You shared a mood today (Me history).
    var meMoodSharedToday: Bool {
        let calendar = Calendar.current
        return history.contains { calendar.isDateInToday($0.timestamp) }
    }

    /// Partner has a current mood share (Partner hero).
    var partnerMoodSharedToday: Bool {
        partnerCurrentMood.mood != nil
    }

    /// You reacted to partner’s mood.
    var meCheckedPartnerMoodToday: Bool {
        myReactionToPartner != nil
    }

    /// Partner reacted to your latest Me share.
    var partnerCheckedMyMoodToday: Bool {
        history.last?.hasPartnerResponse ?? false
    }

    var usLevelName: String {
        UsLongTermLevels.name(for: usLongTermLevel)
    }

    var usLevelEmoji: String {
        UsLongTermLevels.emoji(for: usLongTermLevel)
    }

    var usPointsToNext: Int {
        UsLongTermLevels.pointsToNext(for: usLongTermLevel)
    }

    var usLevelProgressFraction: Double {
        let goal = usPointsToNext
        guard goal > 0 else { return 1 }
        return min(1, max(0, Double(usLongTermPoints) / Double(goal)))
    }

    var timeTogetherPhrase: String {
        UsTimeTogether.phrase(since: relationshipStartDate)
    }

    /// All dates sorted by soonest occurrence (past dates last by daysUntil).
    var importantDatesSorted: [UsImportantDate] {
        importantDates.sorted {
            UsImportantDates.daysUntil($0.date) < UsImportantDates.daysUntil($1.date)
        }
    }

    /// Nearest upcoming (daysUntil >= 0); else soonest overall.
    var nearestImportantDate: UsImportantDate? {
        let upcoming = importantDatesSorted.filter { UsImportantDates.daysUntil($0.date) >= 0 }
        return upcoming.first ?? importantDatesSorted.first
    }

    var usNearestImportantDateTitle: String {
        nearestImportantDate?.title ?? ""
    }

    var usNearestImportantDate: Date {
        nearestImportantDate?.date ?? Date()
    }

    var usNearestImportantDaysUntil: Int {
        guard let nearest = nearestImportantDate else { return 0 }
        return UsImportantDates.daysUntil(nearest.date)
    }

    init(history: [SharedMood]? = nil, partnerCurrentMood: SharedMood? = nil) {
        self.history = history ?? Self.makeSeedHistory()
        let partnerMood = partnerCurrentMood ?? Self.makeSeedPartnerMood()
        self.partnerCurrentMood = partnerMood
        self.partnerHistory = Self.makeSeedPartnerHistory(current: partnerMood)
        if let response = Self.seedMyResponseToPartner {
            self.myReactionToPartner = response.reaction
            self.myNoteToPartner = response.note
        }
        let relationshipStart = Self.makeSeedRelationshipStart()
        self.relationshipStartDate = relationshipStart
        self.usLongTermLevel = 7
        self.usLongTermPoints = 420
        self.usStreakDays = 3
        self.meActivityDoneToday = false
        self.partnerActivityDoneToday = false
        self.importantDates = UsImportantDates.makeSeedDates(
            relationshipStart: relationshipStart,
            partnerName: "Alex"
        )
    }

    /// Add a custom important date for this session. Returns false if title empty.
    @discardableResult
    func addImportantDate(title: String, date: Date) -> Bool {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let entry = UsImportantDate(
            id: "custom-\(UUID().uuidString)",
            title: clean,
            date: day,
            kind: .custom,
            accentHex: 0x22C55E
        )
        importantDates.append(entry)
        return true
    }

    nonisolated private static func makeSeedRelationshipStart() -> Date {
        var comps = DateComponents()
        comps.year = 2022
        comps.month = 3
        comps.day = 14
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date(timeIntervalSince1970: 1_647_216_000)
    }

    func togglePartnerDay(_ key: String, hasEntries: Bool) {
        guard isPaired, hasEntries else { return }
        expandedPartnerDayKey = expandedPartnerDayKey == key ? nil : key
    }

    func completePairing() {
        isPaired = true
    }

    func partnerWeekBuckets(now: Date = Date()) -> [DayBucket] {
        weekBuckets(from: partnerHistory, now: now)
    }

    var hasResponseToPartner: Bool {
        myReactionToPartner != nil
            || !(myNoteToPartner?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    /// You react + optionally note the partner's mood (Partner tab). Once per current partner mood.
    func respondToPartnerMood(reaction: String, note: String?) {
        guard myReactionToPartner == nil else { return }
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

    /// New partner share resets your reaction slot for that mood.
    func replacePartnerCurrentMood(_ mood: SharedMood) {
        partnerCurrentMood = mood
        if !partnerHistory.contains(where: { $0.id == mood.id }) {
            partnerHistory.append(mood)
        }
        myReactionToPartner = nil
        myNoteToPartner = nil
        expandedPartnerDayKey = nil
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
        weekBuckets(from: history, now: now)
    }

    private func weekBuckets(from entries: [SharedMood], now: Date) -> [DayBucket] {
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
            let dayEntries = entries
                .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .sorted { $0.timestamp < $1.timestamp }
            buckets.append(DayBucket(id: key, label: label, isToday: isToday, entries: dayEntries))
        }
        return buckets
    }

    nonisolated static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// Figma Make Partner hero defaults to stressed.
    nonisolated static func makeSeedPartnerMood(now: Date = Date()) -> SharedMood {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .minute, value: -45, to: now) ?? now
        return SharedMood(
            moodID: "stressed",
            wish: "Just listen without judging.",
            timestamp: date
        )
    }

    /// Partner week history matching `PartnerScreen.tsx` past days + today earlier entries + current.
    nonisolated static func makeSeedPartnerHistory(current: SharedMood, now: Date = Date()) -> [SharedMood] {
        let calendar = Calendar.current
        let past: [(daysAgo: Int, moodID: String, wishIndex: Int, hour: Int, minute: Int)] = [
            (6, "calm", 0, 9, 30),
            (6, "stressed", 0, 18, 15),
            (5, "stressed", 2, 11, 0),
            (4, "sad", 0, 8, 45),
            (4, "calm", 2, 15, 20),
            (4, "stressed", 0, 18, 0),
            (4, "love", 2, 21, 0),
            (3, "calm", 1, 10, 0),
            (2, "love", 0, 19, 30),
            (1, "joy", 2, 12, 0),
            (1, "joy", 1, 17, 45),
        ]

        let todayEarlier: [(moodID: String, wishIndex: Int, hour: Int, minute: Int)] = [
            ("calm", 0, 8, 15),
            ("joy", 2, 10, 40),
            ("love", 2, 12, 20),
            ("sad", 2, 14, 5),
            ("exhausted", 1, 16, 10),
        ]

        func wish(_ moodID: String, index: Int) -> String {
            let list = MoodCatalog.wishes(for: moodID)
            guard !list.isEmpty else { return "…" }
            return list[index % list.count]
        }

        var entries: [SharedMood] = past.compactMap { seed in
            guard MoodCatalog.mood(id: seed.moodID) != nil else { return nil }
            var date = calendar.date(byAdding: .day, value: -seed.daysAgo, to: now) ?? now
            date = calendar.date(bySettingHour: seed.hour, minute: seed.minute, second: 0, of: date) ?? date
            return SharedMood(moodID: seed.moodID, wish: wish(seed.moodID, index: seed.wishIndex), timestamp: date)
        }

        for seed in todayEarlier {
            guard MoodCatalog.mood(id: seed.moodID) != nil else { continue }
            var date = calendar.date(bySettingHour: seed.hour, minute: seed.minute, second: 0, of: now) ?? now
            if date > current.timestamp {
                date = calendar.date(byAdding: .hour, value: -1, to: current.timestamp) ?? current.timestamp
            }
            entries.append(
                SharedMood(moodID: seed.moodID, wish: wish(seed.moodID, index: seed.wishIndex), timestamp: date)
            )
        }

        entries.append(current)
        return entries.sorted { $0.timestamp < $1.timestamp }
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
