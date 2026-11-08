import Foundation

/// Couple story bubble on Us — shared strip for both partners (session photo for v1).
struct UsCoupleStory: Identifiable, Equatable, Sendable {
    /// How long a story stays in the active strip rings (Instagram-style).
    static let stripLifetime: TimeInterval = 24 * 60 * 60

    enum Author: String, Sendable {
        case me
        case partner
    }

    let id: String
    var author: Author
    /// JPEG bytes for the story frame (camera / library).
    var imageJPEG: Data
    var createdAt: Date
    /// Local “seen” for the current user (ring style).
    var seenByMe: Bool

    init(
        id: String = UUID().uuidString,
        author: Author,
        imageJPEG: Data,
        createdAt: Date = Date(),
        seenByMe: Bool = false
    ) {
        self.id = id
        self.author = author
        self.imageJPEG = imageJPEG
        self.createdAt = createdAt
        self.seenByMe = seenByMe
    }

    var expiresAt: Date { createdAt.addingTimeInterval(Self.stripLifetime) }

    /// Still shown as a ring on the Us strip (within 24h).
    func isLive(at now: Date = Date()) -> Bool {
        now < expiresAt
    }
}
