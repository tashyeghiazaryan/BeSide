import Foundation

enum ConnectionDailyPhase: String, Sendable, Equatable {
    case closed
    case open
    case waiting
}

/// A partner daily task waiting for the user to count (or pass).
struct ConnectionPendingAnswer: Identifiable, Equatable, Sendable {
    let id: String
    var partnerName: String
    /// The task the partner completed — not their answer text.
    var task: String
    var submittedAt: String
}

enum ConnectionPendingAnswers {
    /// Default session starts empty — Awaiting approval only appears when partner tasks arrive.
    static func demoSeed(partnerName: String = "Alex") -> [ConnectionPendingAnswer] {
        []
    }

    static func samplePending(partnerName: String = "Alex") -> [ConnectionPendingAnswer] {
        [
            ConnectionPendingAnswer(
                id: "pa-1",
                partnerName: partnerName,
                task: ConnectionCarousel.defaultPartnerTask,
                submittedAt: "Today · 10:24"
            ),
            ConnectionPendingAnswer(
                id: "pa-2",
                partnerName: partnerName,
                task: "Leave a tiny note about a moment today that made you smile thinking of them.",
                submittedAt: "Today · 14:02"
            ),
        ]
    }
}
