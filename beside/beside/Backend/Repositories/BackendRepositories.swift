import Foundation

// MARK: - Auth & couple

protocol AuthService: AnyObject, Sendable {
    func currentSessionUserId() async -> UUID?
    func signInWithOTP(email: String) async throws
    func verifyOTP(email: String, token: String) async throws
    /// Dev fallback when email OTP is rate-limited (no email sent).
    func signUpWithPassword(email: String, password: String) async throws
    func signInWithPassword(email: String, password: String) async throws
    func signOut() async throws
}

protocol CoupleService: AnyObject, Sendable {
    func fetchContext() async throws -> CoupleContext
    func createCouple(displayName: String) async throws -> (CoupleContext, inviteCode: String)
    func joinCouple(code: String) async throws -> CoupleContext
}

extension CoupleService {
    func createCouple() async throws -> (CoupleContext, inviteCode: String) {
        try await createCouple(displayName: "")
    }
}

// MARK: - Domain repositories

protocol MoodShareRepository: AnyObject, Sendable {
    func fetchMyShares(coupleId: UUID, userId: UUID) async throws -> [SharedMoodDTO]
    func fetchPartnerShares(coupleId: UUID, partnerUserId: UUID) async throws -> [SharedMoodDTO]
    func shareMood(coupleId: UUID, userId: UUID, moodID: String, wish: String) async throws -> SharedMoodDTO
}

protocol MoodReactionRepository: AnyObject, Sendable {
    func react(moodShareId: UUID, reactorUserId: UUID, reaction: String, note: String) async throws
}

protocol ImportantDateRepository: AnyObject, Sendable {
    func list(coupleId: UUID) async throws -> [ImportantDateDTO]
    func add(coupleId: UUID, title: String, occursOn: Date, kind: String) async throws -> ImportantDateDTO
    func delete(id: UUID) async throws
}

protocol LoveNoteRepository: AnyObject, Sendable {
    func list(coupleId: UUID) async throws -> [LoveNoteDTO]
    func send(coupleId: UUID, senderId: UUID, recipientId: UUID, body: String) async throws -> LoveNoteDTO
    func markRead(id: UUID) async throws
}

protocol SharedMemoryRepository: AnyObject, Sendable {
    func list(coupleId: UUID) async throws -> [SharedMemoryDTO]
    func create(_ draft: SharedMemoryDraft, coupleId: UUID, authorId: UUID) async throws -> SharedMemoryDTO
    func update(_ memory: SharedMemoryDTO) async throws -> SharedMemoryDTO
    func delete(id: UUID) async throws
}

protocol MediaUploading: AnyObject, Sendable {
    func uploadJPEG(data: Data, bucket: String, path: String) async throws -> String
}

// MARK: - DTOs (wire shapes; map to UI models in stores)

struct SharedMoodDTO: Equatable, Sendable, Identifiable {
    var id: UUID
    var userId: UUID
    var moodID: String
    var wish: String
    var sharedAt: Date
    var partnerReaction: String?
    var partnerNote: String?
}

struct ImportantDateDTO: Equatable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var occursOn: Date
    var kind: String
}

struct LoveNoteDTO: Equatable, Sendable, Identifiable {
    var id: UUID
    var senderId: UUID
    var recipientId: UUID
    var body: String
    var status: String
    var readAt: Date?
    var createdAt: Date
}

struct SharedMemoryDTO: Equatable, Sendable, Identifiable {
    var id: UUID
    var authorId: UUID
    var title: String
    var description: String
    var occurredAt: Date
    var moodEmoji: String
    var photoPath: String?
    var likesCount: Int
    var likedByMe: Bool
}

struct SharedMemoryDraft: Equatable, Sendable {
    var title: String
    var description: String
    var occurredAt: Date
    var moodEmoji: String
    var photoJPEG: Data?
}
