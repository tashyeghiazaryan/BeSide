import Foundation

/// Shared Memories add-modal field rules (Title + Description).
enum SharedMemoryFieldRules {
    static let titleMaxLength = 40
    static let descriptionMaxLength = 120

    enum TitleError: Equatable {
        case empty
        case invalidCharacters

        var inlineMessage: String {
            switch self {
            case .empty:
                "Add a title for this memory."
            case .invalidCharacters:
                "Only Latin letters, numbers, punctuation (.,!?-:'\"), spaces, and emoji. Max \(SharedMemoryFieldRules.titleMaxLength) characters."
            }
        }
    }

    enum DescriptionError: Equatable {
        case whitespaceOnly
        case invalidCharacters

        var inlineMessage: String {
            switch self {
            case .whitespaceOnly:
                "Description can’t be only spaces. Add text or leave the field empty."
            case .invalidCharacters:
                "Only Latin letters, numbers, punctuation (.,!?-:'\"), spaces, and emoji. Max \(SharedMemoryFieldRules.descriptionMaxLength) characters."
            }
        }
    }

    static func normalizeInput(_ string: String) -> String {
        WishTextRules.normalizeInput(string)
    }

    static func isAllowed(_ character: Character) -> Bool {
        WishTextRules.isAllowed(character)
    }

    static func sanitizeTitle(_ string: String) -> String {
        sanitize(string, maxLength: titleMaxLength)
    }

    static func sanitizeDescription(_ string: String) -> String {
        sanitize(string, maxLength: descriptionMaxLength)
    }

    static func validateTitle(_ string: String) -> TitleError? {
        let normalized = normalizeInput(string)
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.count > titleMaxLength || trimmed.contains(where: { !isAllowed($0) }) {
            return .invalidCharacters
        }
        return nil
    }

    /// Empty is OK. Spaces-only or disallowed characters → error.
    static func validateDescription(_ string: String) -> DescriptionError? {
        let normalized = normalizeInput(string)
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return normalized.isEmpty ? nil : .whitespaceOnly
        }
        if trimmed.count > descriptionMaxLength || trimmed.contains(where: { !isAllowed($0) }) {
            return .invalidCharacters
        }
        return nil
    }

    private static func sanitize(_ string: String, maxLength: Int) -> String {
        var result = ""
        result.reserveCapacity(min(string.count, maxLength))
        for character in normalizeInput(string) {
            guard result.count < maxLength else { break }
            if isAllowed(character) {
                result.append(character)
            }
        }
        return result
    }
}
