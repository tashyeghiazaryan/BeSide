import Foundation

struct ConnectionCarouselSlide: Identifiable, Equatable, Sendable {
    let id: String
    var title: String?
    var body: String?
    var userTask: String?
    var partnerTask: String?
    var imageURL: String?

    var isTodaysActivity: Bool { id == ConnectionCarousel.todaysActivityID }

    var hasPairedTasks: Bool {
        userTask != nil && partnerTask != nil
    }
}

enum ConnectionCarousel {
    static let todaysActivityID = "todays-activity"

    static let defaultUserTask =
        "Send a short voice note: one thing you appreciated about your partner today, even if it was tiny."
    static let defaultPartnerTask =
        "Write one sentence you'd like to hear more often from them—keep it kind and specific."
    static let closedHint =
        "Open today’s little task, share your part, and when your partner says it feels right — it counts for both of you."
    static let pendingMessage =
        "You marked today’s task done. It counts only after you approve each other’s parts."
    static let togetherTitle = "You both did it"
    static let togetherMessage =
        "Today’s task is complete for both of you — a little win for your connection."
    static let tomorrowHint =
        "New bonding tasks open tomorrow — don’t miss them."

    /// Portrait 9:16 stills so the carousel fills a phone without landscape letterboxing/cropping.
    private static let portraitQuery = "w=1080&h=1920&fit=crop&crop=faces,center&q=80"

    static func demoSlides() -> [ConnectionCarouselSlide] {
        [
            ConnectionCarouselSlide(
                id: todaysActivityID,
                title: "Today's Activity",
                body: "Small relationship-building prompts—yours and your partner's are different, but they fit the same day.",
                userTask: defaultUserTask,
                partnerTask: defaultPartnerTask,
                imageURL: "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?\(portraitQuery)"
            ),
            ConnectionCarouselSlide(
                id: "partner-quiz",
                title: "How well do you know your partner?",
                body: "Take a test now—playful questions to understand each other. One answers, the other guesses—or you both answer and compare at the end.",
                userTask: nil,
                partnerTask: nil,
                imageURL: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?\(portraitQuery)"
            ),
            ConnectionCarouselSlide(
                id: "try-premium",
                title: "Try Premium!",
                body: "More daily questions, couple prompts, and rituals to grow your bond—unlock the full experience for both of you.",
                userTask: nil,
                partnerTask: nil,
                imageURL: "https://images.unsplash.com/photo-1518199266791-5375a83190b7?\(portraitQuery)"
            ),
        ]
    }
}
