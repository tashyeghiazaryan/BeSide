import SwiftUI

/// Story sticker rendered for Instagram Stories share — soft BeSide couple card.
struct CoupleStoryShareCard: View {
    let meName: String
    let partnerName: String
    var style: UsTimeTogether.Style = .detailed
    var relationshipStart: Date = Date()

    private let ink = Color(hex: 0x26282B)
    private let accent = Color(hex: 0xC48A9A)

    private var breakdown: UsTimeTogether.Breakdown {
        UsTimeTogether.breakdown(since: relationshipStart)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                BesideLogoMark(size: 20)
                Text("beside")
                    .font(.system(size: 15, weight: .ultraLight))
                    .tracking(1.0)
                    .foregroundStyle(ink.opacity(0.5))
                Spacer(minLength: 0)
            }
            .padding(.bottom, 22)

            Text("\(meName) & \(partnerName)")
                .font(.system(size: 30, weight: .thin))
                .tracking(0.3)
                .foregroundStyle(ink.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.bottom, 12)

            Text(style == .sinceDate ? "together since" : "together for")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(accent.opacity(0.85))
                .padding(.bottom, 10)

            timeTogetherBody
                .padding(.bottom, 18)

            Text(UsCoupleShareWarmth.line())
                .font(.system(size: 14, weight: .light))
                .tracking(0.2)
                .foregroundStyle(ink.opacity(0.42))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 26)
        .padding(.top, 16)
        .padding(.bottom, 26)
        .frame(width: 340)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color(hex: 0xFAF6F8),
                            Color(hex: 0xF3EEF6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1.2)
                }
                .shadow(color: ink.opacity(0.1), radius: 24, y: 12)
        }
    }

    @ViewBuilder
    private var timeTogetherBody: some View {
        switch style {
        case .detailed:
            HStack(spacing: 0) {
                counterBlock(value: breakdown.years, unit: breakdown.years == 1 ? "year" : "years")
                counterDivider
                counterBlock(value: breakdown.months, unit: breakdown.months == 1 ? "month" : "months")
                counterDivider
                counterBlock(value: breakdown.days, unit: breakdown.days == 1 ? "day" : "days")
            }
            .frame(maxWidth: .infinity)
        case .daysOnly:
            VStack(spacing: 4) {
                Text("\(breakdown.totalDays)")
                    .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink.opacity(0.88))
                Text(breakdown.totalDays == 1 ? "day" : "days")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.38))
            }
            .frame(maxWidth: .infinity)
        case .sinceDate:
            Text(breakdown.sinceLabel)
                .font(.system(size: 30, weight: .ultraLight, design: .rounded))
                .foregroundStyle(ink.opacity(0.9))
                .frame(maxWidth: .infinity)
        }
    }

    private func counterBlock(value: Int, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 30, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ink.opacity(0.9))
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(ink.opacity(0.36))
        }
        .frame(maxWidth: .infinity)
    }

    private var counterDivider: some View {
        Rectangle()
            .fill(ink.opacity(0.08))
            .frame(width: 1, height: 36)
    }
}
