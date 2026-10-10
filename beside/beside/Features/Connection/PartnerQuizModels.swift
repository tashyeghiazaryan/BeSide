import Foundation

enum PartnerQuizPhase: Equatable, Sendable {
    case howToPlay
    case roleReveal
    case playing
    case results
}

/// Your assigned role for today's Partner Quiz round.
enum PartnerQuizRole: Equatable, Sendable {
    /// You pick honest answers; partner will guess later.
    case answering
    /// You guess your partner's locked truths.
    case guessing
}

struct PartnerQuizOption: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
}

struct PartnerQuizQuestion: Identifiable, Equatable, Sendable {
    let id: String
    let prompt: String
    let options: [PartnerQuizOption]
    let partnerTruthOptionID: String

    var isCustom: Bool { id == PartnerQuiz.customQuestionID }

    func option(id: String) -> PartnerQuizOption? {
        options.first { $0.id == id }
    }
}

enum PartnerQuiz {
    /// Points for completing your own truth answers.
    static let truthCompletionPoints = 20
    /// Points per correct guess.
    static let pointsPerCorrectGuess = 10
    /// Premium custom question replaces this seed index (0-based) — slot 2 of 4.
    static let customSlotIndex = 1
    static let customQuestionID = "pq-custom"

    /// Seed deck, optionally swapping slot 2 for a Premium custom question.
    static func demoSeed(
        partnerName: String = "Alex",
        customQuestion: PartnerQuizQuestion? = nil
    ) -> [PartnerQuizQuestion] {
        var questions = [
            PartnerQuizQuestion(
                id: "pq-coffee",
                prompt: "What’s \(partnerName)’s go-to morning drink?",
                options: [
                    PartnerQuizOption(id: "a", text: "Black coffee, no sugar"),
                    PartnerQuizOption(id: "b", text: "Oat-milk latte"),
                    PartnerQuizOption(id: "c", text: "Green tea"),
                ],
                partnerTruthOptionID: "b"
            ),
            PartnerQuizQuestion(
                id: "pq-weekend",
                prompt: "Ideal lazy Sunday for \(partnerName)?",
                options: [
                    PartnerQuizOption(id: "a", text: "Long walk + thrift stores"),
                    PartnerQuizOption(id: "b", text: "Couch, snacks, one good movie"),
                    PartnerQuizOption(id: "c", text: "Brunch with friends"),
                ],
                partnerTruthOptionID: "b"
            ),
            PartnerQuizQuestion(
                id: "pq-love",
                prompt: "Which love language fits \(partnerName) best?",
                options: [
                    PartnerQuizOption(id: "a", text: "Words of affirmation"),
                    PartnerQuizOption(id: "b", text: "Quality time"),
                    PartnerQuizOption(id: "c", text: "Acts of service"),
                ],
                partnerTruthOptionID: "c"
            ),
            PartnerQuizQuestion(
                id: "pq-stress",
                prompt: "When stressed, \(partnerName) usually…",
                options: [
                    PartnerQuizOption(id: "a", text: "Talks it out right away"),
                    PartnerQuizOption(id: "b", text: "Needs quiet alone time first"),
                    PartnerQuizOption(id: "c", text: "Jokes to lighten the mood"),
                ],
                partnerTruthOptionID: "b"
            ),
        ]
        if let customQuestion, questions.indices.contains(customSlotIndex) {
            questions[customSlotIndex] = customQuestion
        }
        return questions
    }

    /// Build a Premium custom question (3 options + locked truth).
    static func makeCustomQuestion(
        prompt: String,
        optionTexts: [String],
        truthOptionID: String
    ) -> PartnerQuizQuestion? {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let options: [PartnerQuizOption] = zip(["a", "b", "c"], optionTexts).compactMap { id, text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return PartnerQuizOption(id: id, text: trimmed)
        }
        guard !trimmedPrompt.isEmpty,
              options.count == 3,
              options.contains(where: { $0.id == truthOptionID })
        else { return nil }
        return PartnerQuizQuestion(
            id: customQuestionID,
            prompt: trimmedPrompt,
            options: options,
            partnerTruthOptionID: truthOptionID
        )
    }
}
