import SwiftUI

struct CurrentMoodPanel: View {
    let shared: SharedMood?
    var partnerName: String = "Alex"
    var onTap: (() -> Void)?

    private var isTappable: Bool { shared != nil && onTap != nil }

    var body: some View {
        Group {
            if isTappable {
                Button(action: { onTap?() }) {
                    panelContent
                }
                .buttonStyle(.plain)
            } else {
                panelContent
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current.mood.panel")
        .accessibilityAddTraits(isTappable ? .isButton : [])
        .accessibilityHint(isTappable ? "Shows \(partnerName)’s reaction history" : "")
    }

    private var panelContent: some View {
        GlassPanel {
            Group {
                if let shared, let mood = shared.mood {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            mood.color.opacity(0.56),
                                            mood.color.opacity(0.31),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: mood.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blur(radius: 8)
                                .opacity(0.5)
                                .clipShape(Circle())
                            MoodIcon(kind: mood.icon, size: 26)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(mood.name)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.75))
                            Text(shared.wish)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color.gray)
                                .lineLimit(2)
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(Self.format(shared.timestamp))
                                    .font(.system(size: 13, weight: .light))
                            }
                            .foregroundStyle(Color.gray.opacity(0.7))

                            if shared.hasPartnerResponse {
                                partnerResponse(shared: shared, mood: mood)
                                    .padding(.top, 4)
                            }
                        }
                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BeSideColor.textMutedSoft)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                } else {
                    Text("Select your mood below to share it with your partner")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                }
            }
        }
    }

    @ViewBuilder
    private func partnerResponse(shared: SharedMood, mood: Mood) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let reaction = shared.partnerReaction {
                HStack(spacing: 6) {
                    Text(reaction)
                        .font(.system(size: 18))
                        .accessibilityIdentifier("partner.reaction.emoji")
                    Text("\(partnerName) reacted")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(BeSideColor.textMutedSoft)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.color.opacity(0.10),
                                    mood.color.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(mood.color.opacity(0.15), lineWidth: 1)
                        }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("partner.reaction.chip")
            }

            if let note = shared.partnerNote?.trimmingCharacters(in: .whitespacesAndNewlines),
               !note.isEmpty
            {
                Text(note)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(BeSideColor.wishTextIdle)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("partner.reaction.note")
            }
        }
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d 'at' HH:mm"
        return formatter.string(from: date)
    }
}
