import Foundation
import SwiftUI

/// Colored icon sphere presets for Important Dates (list bubble + add picker).
enum UsDateIconPreset: String, CaseIterable, Identifiable, Sendable {
    case sparklesCoral
    case heartRose
    case giftLavender
    case calendarMint
    case sparklesSky
    case starAmber
    case planeTeal
    case cakeBlush

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sparklesCoral: return "Special"
        case .heartRose: return "Love"
        case .giftLavender: return "Gift"
        case .calendarMint: return "Plan"
        case .sparklesSky: return "Celebrate"
        case .starAmber: return "Milestone"
        case .planeTeal: return "Trip"
        case .cakeBlush: return "Party"
        }
    }

    var systemImage: String {
        switch self {
        case .sparklesCoral, .sparklesSky: return "sparkles"
        case .heartRose: return "heart.fill"
        case .giftLavender: return "gift.fill"
        case .calendarMint: return "calendar"
        case .starAmber: return "star.fill"
        case .planeTeal: return "airplane"
        case .cakeBlush: return "birthday.cake.fill"
        }
    }

    var accentHex: UInt32 {
        switch self {
        case .sparklesCoral: return 0xFF555D
        case .heartRose: return 0xFB7185
        case .giftLavender: return 0xA78BFA
        case .calendarMint: return 0x22C55E
        case .sparklesSky: return 0x60A5FA
        case .starAmber: return 0xF59E0B
        case .planeTeal: return 0x14B8A6
        case .cakeBlush: return 0xF472B6
        }
    }

    var accentColor: Color { Color(hex: accentHex) }

    var gradientColors: [Color] {
        switch self {
        case .sparklesCoral:
            return [Color(hex: 0xFF555D), Color(hex: 0xFF8A90)]
        case .heartRose:
            return [Color(hex: 0xFB7185), Color(hex: 0xFDA4AF)]
        case .giftLavender:
            return [Color(hex: 0xA78BFA), Color(hex: 0xC4B5FD)]
        case .calendarMint:
            return [Color(hex: 0x22C55E), Color(hex: 0x86EFAC)]
        case .sparklesSky:
            return [Color(hex: 0x60A5FA), Color(hex: 0x93C5FD)]
        case .starAmber:
            return [Color(hex: 0xF59E0B), Color(hex: 0xFCD34D)]
        case .planeTeal:
            return [Color(hex: 0x14B8A6), Color(hex: 0x5EEAD4)]
        case .cakeBlush:
            return [Color(hex: 0xF472B6), Color(hex: 0xF9A8D4)]
        }
    }

    static var defaultCustom: UsDateIconPreset { .calendarMint }
}

/// Soft colored sphere with SF Symbol — used in add picker and list rows.
struct UsDateIconSphere: View {
    let preset: UsDateIconPreset
    var size: CGFloat = 36
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            preset.accentColor.opacity(0.55),
                            preset.accentColor.opacity(0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: preset.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.42)
                .blur(radius: size * 0.22)
                .clipShape(Circle())

            Circle()
                .stroke(Color.white.opacity(isSelected ? 0.95 : 0.65), lineWidth: isSelected ? 2 : 1)

            Image(systemName: preset.systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
        }
        .frame(width: size, height: size)
        .shadow(color: preset.accentColor.opacity(isSelected ? 0.35 : 0.12), radius: isSelected ? 8 : 3, y: 2)
        .scaleEffect(isSelected ? 1.08 : 1)
    }
}
