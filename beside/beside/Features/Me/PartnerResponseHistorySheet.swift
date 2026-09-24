import SwiftUI

/// Bottom sheet: partner reactions as a short dialogue (their reply left, your share right).
struct PartnerResponseHistorySheet: View {
    let entries: [SharedMood]
    var youName: String = "You"
    var partnerName: String = "Alex"

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    if entries.isEmpty {
                        Text("No reactions from \(partnerName) yet")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(BeSideColor.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(entries) { entry in
                            dialogueThread(entry)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background {
                BeSideBackground.softCanvas.ignoresSafeArea()
            }
            .navigationTitle("\(partnerName)’s reactions")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("partner.response.history")
    }

    private func dialogueThread(_ entry: SharedMood) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Self.format(entry.timestamp))
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(BeSideColor.textMutedSoft)
                .frame(maxWidth: .infinity)

            // You — mood + wish (right)
            HStack(alignment: .bottom, spacing: 8) {
                Spacer(minLength: 36)
                youBubble(entry)
            }

            // Partner — reaction + note (left)
            HStack(alignment: .bottom, spacing: 8) {
                partnerBubble(entry)
                Spacer(minLength: 36)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func youBubble(_ entry: SharedMood) -> some View {
        let mood = entry.mood
        return VStack(alignment: .trailing, spacing: 4) {
            Text(youName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BeSideColor.textMutedSoft)

            HStack(alignment: .top, spacing: 10) {
                if let mood {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [mood.color.opacity(0.56), mood.color.opacity(0.31)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        MoodIcon(kind: mood.icon, size: 16)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(mood?.name ?? "Mood")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(BeSideColor.textPrimary)
                    Text(entry.wish)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(BeSideColor.wishTextIdle)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 6,
                    topTrailingRadius: 18,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                (mood?.color ?? .gray).opacity(0.22),
                                (mood?.color ?? .gray).opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.8)
                }
            }
        }
        .frame(maxWidth: 280, alignment: .trailing)
        .accessibilityIdentifier("history.you.bubble")
    }

    private func partnerBubble(_ entry: SharedMood) -> some View {
        let moodColor = entry.mood?.color ?? .gray
        let note = entry.partnerNote?.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 4) {
            Text(partnerName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BeSideColor.textMutedSoft)

            VStack(alignment: .leading, spacing: 6) {
                if let reaction = entry.partnerReaction {
                    HStack(spacing: 6) {
                        Text(reaction)
                            .font(.system(size: 20))
                        Text("reacted")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.textMuted)
                    }
                }

                if let note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(BeSideColor.wishText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 6,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                moodColor.opacity(0.12),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .stroke(moodColor.opacity(0.22), lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: 260, alignment: .leading)
        .accessibilityIdentifier("history.partner.bubble")
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d · HH:mm"
        return formatter.string(from: date)
    }
}
