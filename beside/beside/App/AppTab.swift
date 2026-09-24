import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case me
    case partner
    case us
    case connection
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .me: "Me"
        case .partner: "Partner"
        case .us: "Us"
        case .connection: "Connection"
        case .more: "More"
        }
    }

    var iconKind: TabBarIconKind {
        switch self {
        case .me: .userRound
        case .partner: .users
        case .us: .heart
        case .connection: .sparkle
        case .more: .more
        }
    }

    var tabIdentifier: String { "tab.\(rawValue)" }
    var screenIdentifier: String { "screen.\(rawValue)" }
}
