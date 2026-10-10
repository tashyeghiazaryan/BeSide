import Foundation
import Supabase

/// Live couple data access. Used by `MeSessionStore` when Supabase mode is active.
@MainActor
final class CoupleBackendGateway {
    let client: SupabaseClient
    private(set) var context: CoupleContext

    init(client: SupabaseClient, context: CoupleContext) {
        self.client = client
        self.context = context
    }

    func updateContext(_ context: CoupleContext) {
        self.context = context
    }

    private var coupleId: UUID {
        get throws {
            guard let id = context.coupleId else {
                throw CoupleServiceError.underlying("Not in a couple yet.")
            }
            return id
        }
    }

    // MARK: - Bootstrap load

    struct Snapshot {
        var myShares: [SharedMood]
        var partnerShares: [SharedMood]
        var importantDates: [UsImportantDate]
        var myWishlist: [UsWishlistItem]
        var partnerWishlist: [UsWishlistItem]
        var wishlistHistory: [UsCompletedWish]
        var loveNotes: [LoveNote]
        var sharedMemories: [UsSharedMemory]
        var level: Int
        var points: Int
        var streak: Int
        var relationshipStart: Date?
        var qotdPrompt: String
        var meQuestionAnswer: String?
        var partnerQuestionAnswer: String?
        var meDailySubmitted: Bool
        var partnerDailySubmitted: Bool
        var meActivityDone: Bool
        var partnerActivityDone: Bool
        var pendingAnswers: [ConnectionPendingAnswer]
        var dailyPhase: ConnectionDailyPhase
        var myReactionToPartner: String?
        var myNoteToPartner: String?
    }

    func loadSnapshot() async throws -> Snapshot {
        let cid = try coupleId
        async let shares: [MoodShareRow] = client
            .from("mood_shares")
            .select("*, mood_reactions(*)")
            .eq("couple_id", value: cid)
            .order("shared_at", ascending: false)
            .execute()
            .value

        async let dates: [ImportantDateRow] = client
            .from("important_dates")
            .select()
            .eq("couple_id", value: cid)
            .execute()
            .value

        async let wishes: [WishlistRow] = client
            .from("wishlist_items")
            .select()
            .eq("couple_id", value: cid)
            .order("created_at", ascending: false)
            .execute()
            .value

        async let completed: [CompletedWishRow] = client
            .from("completed_wishes")
            .select()
            .eq("couple_id", value: cid)
            .order("completed_at", ascending: false)
            .execute()
            .value

        async let notes: [LoveNoteRow] = client
            .from("love_notes")
            .select()
            .eq("couple_id", value: cid)
            .order("created_at", ascending: false)
            .execute()
            .value

        async let memories: [MemoryRow] = client
            .from("shared_memories")
            .select("*, shared_memory_likes(user_id)")
            .eq("couple_id", value: cid)
            .order("occurred_at", ascending: false)
            .execute()
            .value

        async let progress: [ProgressRow] = client
            .from("couple_progress")
            .select()
            .eq("couple_id", value: cid)
            .limit(1)
            .execute()
            .value

        async let coupleRows: [CoupleRow] = client
            .from("couples")
            .select()
            .eq("id", value: cid)
            .limit(1)
            .execute()
            .value

        let today = Self.dayString(Date())
        async let qotdPromptRows: [QotdPromptRow] = client
            .from("qotd_prompts")
            .select()
            .eq("prompt_date", value: today)
            .limit(1)
            .execute()
            .value

        async let qotdAnswers: [QotdAnswerRow] = client
            .from("qotd_answers")
            .select()
            .eq("couple_id", value: cid)
            .eq("prompt_date", value: today)
            .execute()
            .value

        async let dailyRounds: [DailyRoundRow] = client
            .from("daily_rounds")
            .select("*, daily_submissions(*)")
            .eq("couple_id", value: cid)
            .eq("round_date", value: today)
            .limit(1)
            .execute()
            .value

        let shareRows = try await shares
        let myShares = shareRows
            .filter { $0.user_id == context.userId }
            .map { $0.asSharedMood(viewerId: context.userId) }
        let partnerShares = shareRows
            .filter { $0.user_id != context.userId }
            .map { $0.asSharedMood(viewerId: context.userId) }

        let partnerLatest = partnerShares.first
        var myReaction: String?
        var myNote: String?
        if let partnerLatest,
           let shareRow = shareRows.first(where: { $0.id.uuidString == partnerLatest.id.uuidString }),
           let mine = shareRow.mood_reactions?.first(where: { $0.reactor_user_id == context.userId }) {
            myReaction = mine.reaction
            myNote = mine.note.isEmpty ? nil : mine.note
        }

        let wishRows = try await wishes
        let noteRows = try await notes
        let memoryRows = try await memories
        let progressRow = try await progress.first
        let couple = try await coupleRows.first
        let prompt = try await qotdPromptRows.first?.prompt
            ?? "What's one small thing that made you smile today?"
        let answers = try await qotdAnswers
        let round = try await dailyRounds.first

        let meDaily = round?.daily_submissions?.first(where: { $0.user_id == context.userId })
        let partnerDaily = round?.daily_submissions?.first(where: { $0.user_id != context.userId })

        var pending: [ConnectionPendingAnswer] = []
        if let partnerDaily, partnerDaily.status == "submitted" {
            pending.append(
                ConnectionPendingAnswer(
                    id: partnerDaily.id.uuidString,
                    partnerName: context.partnerDisplayName ?? "Partner",
                    task: partnerDaily.body.isEmpty ? "Daily task" : partnerDaily.body,
                    submittedAt: Self.shortTime(partnerDaily.submitted_at)
                )
            )
        }

        let phase: ConnectionDailyPhase = meDaily == nil
            ? (round == nil ? .closed : .open)
            : .waiting

        let myWishlist = await resolveWishlist(wishRows.filter { $0.owner_user_id == context.userId })
        let partnerWishlist = await resolveWishlist(wishRows.filter { $0.owner_user_id != context.userId })
        let sharedMemories = await resolveMemories(memoryRows)

        return Snapshot(
            myShares: myShares,
            partnerShares: partnerShares,
            importantDates: try await dates.map(\.asModel),
            myWishlist: myWishlist,
            partnerWishlist: partnerWishlist,
            wishlistHistory: try await completed.map(\.asModel),
            loveNotes: noteRows.map { $0.asModel(viewerId: context.userId) },
            sharedMemories: sharedMemories,
            level: progressRow?.level ?? 1,
            points: progressRow?.points ?? 0,
            streak: progressRow?.streak_days ?? 0,
            relationshipStart: couple?.relationship_start_date.flatMap(Self.parseDay),
            qotdPrompt: prompt,
            meQuestionAnswer: answers.first(where: { $0.user_id == context.userId })?.answer,
            partnerQuestionAnswer: answers.first(where: { $0.user_id != context.userId })?.answer,
            meDailySubmitted: meDaily != nil,
            partnerDailySubmitted: partnerDaily != nil,
            meActivityDone: meDaily?.status == "approved",
            partnerActivityDone: partnerDaily?.status == "approved",
            pendingAnswers: pending,
            dailyPhase: phase,
            myReactionToPartner: myReaction,
            myNoteToPartner: myNote
        )
    }

    private func signedURL(bucket: String, path: String) async -> String {
        do {
            let url = try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: 60 * 60 * 24)
            return url.absoluteString
        } catch {
            return ""
        }
    }

    private func resolveWishlist(_ rows: [WishlistRow]) async -> [UsWishlistItem] {
        var items: [UsWishlistItem] = []
        for row in rows {
            var model = row.asModel
            if let path = row.photo_path {
                model.photoURL = await signedURL(bucket: "wishlist-photos", path: path)
            }
            items.append(model)
        }
        return items
    }

    private func resolveMemories(_ rows: [MemoryRow]) async -> [UsSharedMemory] {
        var items: [UsSharedMemory] = []
        for row in rows {
            var model = row.asModel(viewerId: context.userId)
            if let path = row.photo_path {
                model.photoURL = await signedURL(bucket: "memory-photos", path: path)
            }
            items.append(model)
        }
        return items
    }

    // MARK: - Moods

    func shareMood(moodID: String, wish: String) async throws -> SharedMood {
        struct Insert: Encodable {
            let couple_id: UUID
            let user_id: UUID
            let mood_id: String
            let wish: String
        }
        let cid = try coupleId
        let row: MoodShareRow = try await client
            .from("mood_shares")
            .insert(Insert(couple_id: cid, user_id: context.userId, mood_id: moodID, wish: wish))
            .select("*, mood_reactions(*)")
            .single()
            .execute()
            .value
        return row.asSharedMood(viewerId: context.userId)
    }

    func reactToMood(shareId: UUID, reaction: String, note: String) async throws {
        struct Insert: Encodable {
            let mood_share_id: UUID
            let reactor_user_id: UUID
            let reaction: String
            let note: String
        }
        try await client
            .from("mood_reactions")
            .upsert(
                Insert(
                    mood_share_id: shareId,
                    reactor_user_id: context.userId,
                    reaction: reaction,
                    note: note
                ),
                onConflict: "mood_share_id,reactor_user_id"
            )
            .execute()
    }

    // MARK: - Important dates

    func addImportantDate(title: String, date: Date, kind: String, accentHex: String?, systemImage: String?, iconPreset: String?) async throws -> UsImportantDate {
        struct Insert: Encodable {
            let couple_id: UUID
            let title: String
            let occurs_on: String
            let kind: String
            let accent_hex: String?
            let system_image: String?
            let icon_preset: String?
            let created_by: UUID
        }
        let cid = try coupleId
        let row: ImportantDateRow = try await client
            .from("important_dates")
            .insert(
                Insert(
                    couple_id: cid,
                    title: title,
                    occurs_on: Self.dayString(date),
                    kind: kind,
                    accent_hex: accentHex,
                    system_image: systemImage,
                    icon_preset: iconPreset,
                    created_by: context.userId
                )
            )
            .select()
            .single()
            .execute()
            .value
        return row.asModel
    }

    func deleteImportantDate(id: UUID) async throws {
        try await client.from("important_dates").delete().eq("id", value: id).execute()
    }

    // MARK: - Wishlist

    func addWish(caption: String, photoJPEG: Data?) async throws -> UsWishlistItem {
        let cid = try coupleId
        var photoPath: String?
        if let photoJPEG {
            let path = "\(cid.uuidString)/\(context.userId.uuidString)/\(UUID().uuidString).jpg"
            try await client.storage.from("wishlist-photos").upload(path, data: photoJPEG, options: .init(contentType: "image/jpeg", upsert: true))
            photoPath = path
        }
        struct Insert: Encodable {
            let couple_id: UUID
            let owner_user_id: UUID
            let caption: String
            let photo_path: String?
        }
        let row: WishlistRow = try await client
            .from("wishlist_items")
            .insert(Insert(couple_id: cid, owner_user_id: context.userId, caption: caption, photo_path: photoPath))
            .select()
            .single()
            .execute()
            .value
        return row.asModel
    }

    func removeWish(id: UUID) async throws {
        try await client.from("wishlist_items").delete().eq("id", value: id).execute()
    }

    func markWishDone(id: UUID, title: String) async throws -> UsCompletedWish {
        let cid = try coupleId
        try await client.from("wishlist_items").delete().eq("id", value: id).execute()
        struct Insert: Encodable {
            let couple_id: UUID
            let title: String
            let direction: String
        }
        let row: CompletedWishRow = try await client
            .from("completed_wishes")
            .insert(Insert(couple_id: cid, title: title, direction: "for_me"))
            .select()
            .single()
            .execute()
            .value
        return row.asModel
    }

    // MARK: - Love notes

    func sendLoveNote(body: String) async throws -> LoveNote {
        guard let partner = context.partnerUserId else {
            throw CoupleServiceError.underlying("Partner not joined yet.")
        }
        struct Insert: Encodable {
            let couple_id: UUID
            let sender_id: UUID
            let recipient_id: UUID
            let body: String
        }
        let cid = try coupleId
        let row: LoveNoteRow = try await client
            .from("love_notes")
            .insert(Insert(couple_id: cid, sender_id: context.userId, recipient_id: partner, body: body))
            .select()
            .single()
            .execute()
            .value
        return row.asModel(viewerId: context.userId)
    }

    func markNoteRead(id: UUID) async throws {
        struct Patch: Encodable {
            let status: String
            let read_at: String
        }
        try await client
            .from("love_notes")
            .update(Patch(status: "read", read_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: id)
            .execute()
    }

    func deleteLoveNote(id: UUID) async throws {
        try await client.from("love_notes").delete().eq("id", value: id).execute()
    }

    // MARK: - Memories

    func addMemory(title: String, description: String, occurredAt: Date, mood: String, photoJPEG: Data?) async throws -> UsSharedMemory {
        let cid = try coupleId
        var photoPath: String?
        if let photoJPEG {
            let path = "\(cid.uuidString)/\(UUID().uuidString).jpg"
            try await client.storage
                .from("memory-photos")
                .upload(path, data: photoJPEG, options: .init(contentType: "image/jpeg", upsert: true))
            photoPath = path
        }
        struct Insert: Encodable {
            let couple_id: UUID
            let author_id: UUID
            let title: String
            let description: String
            let occurred_at: String
            let mood_emoji: String
            let photo_path: String?
        }
        let row: MemoryRow = try await client
            .from("shared_memories")
            .insert(
                Insert(
                    couple_id: cid,
                    author_id: context.userId,
                    title: title,
                    description: description,
                    occurred_at: ISO8601DateFormatter().string(from: occurredAt),
                    mood_emoji: mood,
                    photo_path: photoPath
                )
            )
            .select("*, shared_memory_likes(user_id)")
            .single()
            .execute()
            .value
        return row.asModel(viewerId: context.userId)
    }

    func updateMemory(id: UUID, title: String, description: String, occurredAt: Date, mood: String, photoJPEG: Data?, removePhoto: Bool) async throws -> UsSharedMemory {
        let cid = try coupleId
        var photoPath: String?
        if let photoJPEG {
            let path = "\(cid.uuidString)/\(UUID().uuidString).jpg"
            try await client.storage
                .from("memory-photos")
                .upload(path, data: photoJPEG, options: .init(contentType: "image/jpeg", upsert: true))
            photoPath = path
        }
        struct Patch: Encodable {
            let title: String
            let description: String
            let occurred_at: String
            let mood_emoji: String
            let photo_path: String?
        }
        let row: MemoryRow = try await client
            .from("shared_memories")
            .update(
                Patch(
                    title: title,
                    description: description,
                    occurred_at: ISO8601DateFormatter().string(from: occurredAt),
                    mood_emoji: mood,
                    photo_path: removePhoto ? nil : photoPath
                )
            )
            .eq("id", value: id)
            .select("*, shared_memory_likes(user_id)")
            .single()
            .execute()
            .value
        return row.asModel(viewerId: context.userId)
    }

    func deleteMemory(id: UUID) async throws {
        try await client.from("shared_memories").delete().eq("id", value: id).execute()
    }

    // MARK: - QOTD / Daily

    func ensureTodayQOTDPrompt(_ fallback: String) async throws -> String {
        let today = Self.dayString(Date())
        struct Insert: Encodable {
            let prompt_date: String
            let prompt: String
        }
        do {
            let existing: [QotdPromptRow] = try await client
                .from("qotd_prompts")
                .select()
                .eq("prompt_date", value: today)
                .limit(1)
                .execute()
                .value
            if let prompt = existing.first?.prompt { return prompt }
            let row: QotdPromptRow = try await client
                .from("qotd_prompts")
                .insert(Insert(prompt_date: today, prompt: fallback))
                .select()
                .single()
                .execute()
                .value
            return row.prompt
        } catch {
            return fallback
        }
    }

    func submitQOTD(answer: String) async throws {
        let cid = try coupleId
        let today = Self.dayString(Date())
        _ = try await ensureTodayQOTDPrompt("What's one small thing that made you smile today?")
        struct Insert: Encodable {
            let couple_id: UUID
            let prompt_date: String
            let user_id: UUID
            let answer: String
        }
        try await client
            .from("qotd_answers")
            .upsert(
                Insert(couple_id: cid, prompt_date: today, user_id: context.userId, answer: answer),
                onConflict: "couple_id,prompt_date,user_id"
            )
            .execute()
    }

    func ensureDailyRound(meTask: String, partnerTask: String) async throws -> UUID {
        let cid = try coupleId
        let today = Self.dayString(Date())
        let existing: [DailyRoundRow] = try await client
            .from("daily_rounds")
            .select("*, daily_submissions(*)")
            .eq("couple_id", value: cid)
            .eq("round_date", value: today)
            .limit(1)
            .execute()
            .value
        if let id = existing.first?.id { return id }
        struct Insert: Encodable {
            let couple_id: UUID
            let round_date: String
            let me_task: String
            let partner_task: String
        }
        let row: DailyRoundRow = try await client
            .from("daily_rounds")
            .insert(Insert(couple_id: cid, round_date: today, me_task: meTask, partner_task: partnerTask))
            .select("*, daily_submissions(*)")
            .single()
            .execute()
            .value
        return row.id
    }

    func markDailyDone(body: String) async throws {
        let roundId = try await ensureDailyRound(
            meTask: "Send a voice note about your day",
            partnerTask: "Ask how their day felt in one word"
        )
        struct Insert: Encodable {
            let round_id: UUID
            let user_id: UUID
            let body: String
            let status: String
        }
        try await client
            .from("daily_submissions")
            .upsert(
                Insert(round_id: roundId, user_id: context.userId, body: body, status: "submitted"),
                onConflict: "round_id,user_id"
            )
            .execute()
    }

    func approveSubmission(id: UUID) async throws {
        struct Patch: Encodable { let status: String }
        try await client
            .from("daily_submissions")
            .update(Patch(status: "approved"))
            .eq("id", value: id)
            .execute()
    }

    func declineSubmission(id: UUID) async throws {
        try await client.from("daily_submissions").delete().eq("id", value: id).execute()
    }

    // MARK: - Progress / quiz points

    func addProgressPoints(_ amount: Int) async throws -> (level: Int, points: Int) {
        let cid = try coupleId
        let rows: [ProgressRow] = try await client
            .from("couple_progress")
            .select()
            .eq("couple_id", value: cid)
            .limit(1)
            .execute()
            .value
        var level = rows.first?.level ?? 1
        var points = (rows.first?.points ?? 0) + amount
        while points >= 100, level < 30 {
            points -= 100
            level += 1
        }
        struct Patch: Encodable {
            let level: Int
            let points: Int
        }
        if rows.isEmpty {
            struct Insert: Encodable {
                let couple_id: UUID
                let level: Int
                let points: Int
            }
            try await client
                .from("couple_progress")
                .insert(Insert(couple_id: cid, level: level, points: points))
                .execute()
        } else {
            try await client
                .from("couple_progress")
                .update(Patch(level: level, points: points))
                .eq("couple_id", value: cid)
                .execute()
        }
        return (level, points)
    }

    // MARK: - Helpers

    nonisolated static func dayString(_ date: Date) -> String { CoupleDateFormat.dayString(date) }

    nonisolated static func parseDay(_ string: String) -> Date? { CoupleDateFormat.parseDay(string) }

    nonisolated static func shortTime(_ date: Date) -> String { CoupleDateFormat.shortTime(date) }
}

enum CoupleDateFormat {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    nonisolated static func dayString(_ date: Date) -> String { dayFormatter.string(from: date) }
    nonisolated static func parseDay(_ string: String) -> Date? { dayFormatter.date(from: string) }
    nonisolated static func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Rows

private struct MoodReactionRow: Decodable {
    let id: UUID
    let mood_share_id: UUID
    let reactor_user_id: UUID
    let reaction: String
    let note: String
}

private struct MoodShareRow: Decodable {
    let id: UUID
    let couple_id: UUID
    let user_id: UUID
    let mood_id: String
    let wish: String
    let shared_at: Date
    let mood_reactions: [MoodReactionRow]?

    func asSharedMood(viewerId: UUID) -> SharedMood {
        let partnerReaction = mood_reactions?.first(where: { $0.reactor_user_id != user_id })
        return SharedMood(
            id: id,
            moodID: mood_id,
            wish: wish,
            timestamp: shared_at,
            partnerReaction: partnerReaction?.reaction,
            partnerNote: partnerReaction?.note.nilIfEmpty
        )
    }
}

private struct ImportantDateRow: Decodable {
    let id: UUID
    let title: String
    let occurs_on: String
    let kind: String
    let accent_hex: String?
    let system_image: String?
    let icon_preset: String?

    var asModel: UsImportantDate {
        let date = CoupleBackendGateway.parseDay(occurs_on) ?? Date()
        let kind = UsImportantDate.Kind(rawValue: kind) ?? .custom
        let hex = UInt32(accent_hex?.replacingOccurrences(of: "#", with: "") ?? "C9A7B8", radix: 16) ?? 0xC9A7B8
        return UsImportantDate(
            id: id.uuidString,
            title: title,
            date: date,
            kind: kind,
            accentHex: hex,
            systemImage: system_image ?? "heart.fill",
            iconPresetRaw: icon_preset
        )
    }
}

private struct WishlistRow: Decodable {
    let id: UUID
    let owner_user_id: UUID
    let caption: String
    let photo_path: String?

    var asModel: UsWishlistItem {
        UsWishlistItem(
            id: id.uuidString,
            caption: caption,
            photoURL: photo_path.map { "storage://wishlist-photos/\($0)" } ?? ""
        )
    }
}

private struct CompletedWishRow: Decodable {
    let id: UUID
    let title: String
    let completed_at: Date
    let direction: String

    var asModel: UsCompletedWish {
        UsCompletedWish(
            id: id.uuidString,
            title: title,
            completedAt: completed_at,
            direction: direction == "for_partner" ? .forPartner : .forMe
        )
    }
}

private struct LoveNoteRow: Decodable {
    let id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let body: String
    let status: String
    let read_at: Date?
    let created_at: Date

    func asModel(viewerId: UUID) -> LoveNote {
        LoveNote(
            id: id.uuidString,
            body: body,
            createdAt: created_at,
            direction: sender_id == viewerId ? .outgoing : .incoming,
            status: status == "read" ? .read : .sent,
            readAt: read_at
        )
    }
}

private struct MemoryLikeRow: Decodable {
    let user_id: UUID
}

private struct MemoryRow: Decodable {
    let id: UUID
    let author_id: UUID
    let title: String
    let description: String
    let occurred_at: Date
    let mood_emoji: String
    let photo_path: String?
    let likes_count: Int
    let shared_memory_likes: [MemoryLikeRow]?

    func asModel(viewerId: UUID) -> UsSharedMemory {
        UsSharedMemory(
            id: id.uuidString,
            title: title,
            dateTime: occurred_at,
            description: description,
            mood: mood_emoji,
            photoURL: photo_path.map { "storage://memory-photos/\($0)" } ?? "",
            photoData: nil,
            likes: likes_count,
            likedByMe: shared_memory_likes?.contains(where: { $0.user_id == viewerId }) ?? false,
            addedByUser: author_id == viewerId
        )
    }
}

private struct ProgressRow: Decodable {
    let couple_id: UUID
    let level: Int
    let points: Int
    let streak_days: Int
}

private struct CoupleRow: Decodable {
    let id: UUID
    let relationship_start_date: String?
}

private struct QotdPromptRow: Decodable {
    let prompt_date: String
    let prompt: String
}

private struct QotdAnswerRow: Decodable {
    let user_id: UUID
    let answer: String
}

private struct DailySubmissionRow: Decodable {
    let id: UUID
    let user_id: UUID
    let body: String
    let status: String
    let submitted_at: Date
}

private struct DailyRoundRow: Decodable {
    let id: UUID
    let me_task: String
    let partner_task: String
    let daily_submissions: [DailySubmissionRow]?
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
