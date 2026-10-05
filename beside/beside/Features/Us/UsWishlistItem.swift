import Foundation

/// Wishlist entry — caption + optional photo URL (Figma Make `WishlistItem`).
struct UsWishlistItem: Identifiable, Equatable {
    let id: String
    var caption: String
    /// Remote or local file URL string; empty = caption-only.
    var photoURL: String
}

/// Fulfilled wishlist gift (Figma Make `CompletedWish`).
struct UsCompletedWish: Identifiable, Equatable {
    enum Direction: String {
        case forMe = "for_me"
        case forPartner = "for_partner"
    }

    let id: String
    var title: String
    var completedAt: Date
    var direction: Direction
}

enum UsWishlist {
    static let captionMaxLength = 80

    static func partnerSeed() -> [UsWishlistItem] {
        [
            UsWishlistItem(
                id: "pw-1",
                caption: "Cozy knit sweater",
                photoURL: "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=400&fit=crop"
            ),
            UsWishlistItem(
                id: "pw-2",
                caption: "Pour-over coffee kit",
                photoURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=400&fit=crop"
            ),
            UsWishlistItem(
                id: "pw-3",
                caption: "Concert tickets",
                photoURL: "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=400&fit=crop"
            ),
        ]
    }

    static func historyDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
}
