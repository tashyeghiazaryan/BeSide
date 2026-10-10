import Foundation

/// Identifies the signed-in user and their couple for repository calls.
struct CoupleContext: Equatable, Sendable {
    var userId: UUID
    var coupleId: UUID?
    var partnerUserId: UUID?
    var displayName: String
    var partnerDisplayName: String?
    var inviteCode: String?

    /// Fully paired when both members exist.
    var isPaired: Bool { coupleId != nil && partnerUserId != nil }

    /// Created a couple and waiting for partner to join.
    var hasCouple: Bool { coupleId != nil }
}

extension CoupleContext {
    /// Demo context matching current `MeSessionStore` seed names.
    static let demo = CoupleContext(
        userId: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
        coupleId: UUID(uuidString: "00000000-0000-4000-8000-0000000000aa")!,
        partnerUserId: UUID(uuidString: "00000000-0000-4000-8000-000000000002")!,
        displayName: "Anna",
        partnerDisplayName: "Alex",
        inviteCode: "BESIDE-4K2M"
    )
}
