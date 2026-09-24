import Foundation

/// Allowed custom-wish input: Latin letters, digits, space, punctuation, emoji; max 80.
enum WishTextRules {
    static let maxLength = 80

    static func isAllowed(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(isAllowedScalar)
    }

    static func containsDisallowed(_ string: String) -> Bool {
        let normalized = normalizeInput(string)
        return normalized.count > maxLength || normalized.contains { !isAllowed($0) }
    }

    static func limitLength(_ string: String) -> String {
        String(string.prefix(maxLength))
    }

    /// Newlines / tabs from the multiline field → spaces; keeps typing predictable.
    static func normalizeInput(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
    }

    static func sanitize(_ string: String) -> String {
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

    static func isValidShareWish(_ string: String) -> Bool {
        let trimmed = normalizeInput(string).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxLength else { return false }
        return trimmed.allSatisfy(isAllowed)
    }

    private static func isAllowedScalar(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        // A–Z a–z
        if (0x41...0x5A).contains(value) || (0x61...0x7A).contains(value) { return true }
        // 0–9
        if (0x30...0x39).contains(value) { return true }
        // space / NBSP (paste)
        if value == 0x20 || value == 0xA0 { return true }
        // . , ! ? - : "
        if value == 0x2E || value == 0x2C || value == 0x21 || value == 0x3F
            || value == 0x2D || value == 0x3A || value == 0x22
        {
            return true
        }
        // ' and iOS smart quotes (I’m / Let’s)
        if value == 0x27 || value == 0x2018 || value == 0x2019
            || value == 0x201C || value == 0x201D
        {
            return true
        }
        // Emoji sequences: ZWJ, VS16, skin tones
        if value == 0x200D || value == 0xFE0F || (0x1F3FB...0x1F3FF).contains(value) {
            return true
        }
        // Emoji (exclude ASCII — digits/`#`/`*` falsely report isEmoji)
        if value > 0x7F, scalar.properties.isEmoji || scalar.properties.isEmojiModifier {
            return true
        }
        return false
    }
}

/// Short optional note from the partner with a mood reaction (same charset as custom wish).
enum PartnerNoteRules {
    static let maxLength = 60

    static func limitLength(_ string: String) -> String {
        String(string.prefix(maxLength))
    }

    static func containsDisallowed(_ string: String) -> Bool {
        let normalized = WishTextRules.normalizeInput(string)
        return normalized.count > maxLength || normalized.contains { !WishTextRules.isAllowed($0) }
    }

    static func isValidOptionalNote(_ string: String) -> Bool {
        let trimmed = WishTextRules.normalizeInput(string)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        guard trimmed.count <= maxLength else { return false }
        return trimmed.allSatisfy(WishTextRules.isAllowed)
    }
}

enum WishShareAlert: Identifiable, Equatable, Sendable {
    case emptyWish
    case invalidWish

    var id: String {
        switch self {
        case .emptyWish: "empty"
        case .invalidWish: "invalid"
        }
    }

    /// Short inline copy under the wish field / list (not a modal).
    var inlineMessage: String {
        switch self {
        case .emptyWish:
            "Choose a ready-made wish or write your own."
        case .invalidWish:
            "Only Latin letters, numbers, punctuation (.,!?-:'\"), spaces, and emoji. Max 80 characters."
        }
    }
}
