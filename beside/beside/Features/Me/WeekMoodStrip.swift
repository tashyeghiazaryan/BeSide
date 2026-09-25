import SwiftUI

/// Week strip matching the Me screenshot: tap a day → in-card detail with tinted mood rows.
struct WeekMoodStrip: View {
    var title: String = "My mood this week"
    var accessibilityID: String = "week.mood.strip"
    let buckets: [MeSessionStore.DayBucket]
    let expandedDayKey: String?
    let onTapDay: (MeSessionStore.DayBucket) -> Void
    /// Tap on panel chrome / empty space (not a day control) dismisses the detail.
    var onTapOutsideDetail: (() -> Void)? = nil

    private var expandedBucket: MeSessionStore.DayBucket? {
        guard let expandedDayKey else { return nil }
        return buckets.first { $0.id == expandedDayKey && !$0.entries.isEmpty }
    }

    private static let scrollFromCount = 3
    private static let scrollContentHeight: CGFloat = 168

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray.opacity(0.55))
                    Text(title)
                        .font(.system(size: 12, weight: .light))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.black.opacity(0.28))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if expandedDayKey != nil { onTapOutsideDetail?() }
                }

                HStack(alignment: .top, spacing: 0) {
                    ForEach(buckets) { bucket in
                        dayColumn(bucket)
                            .frame(maxWidth: .infinity)
                    }
                }

                if let expandedBucket {
                    dayDetailCard(expandedBucket)
                        .transition(
                            .opacity
                                .combined(with: .move(edge: .top))
                                .combined(with: .scale(scale: 0.98, anchor: .top))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background {
                if expandedDayKey != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { onTapOutsideDetail?() }
                }
            }
        }
        .animation(.easeOut(duration: 0.22), value: expandedDayKey)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityID)
    }

    @ViewBuilder
    private func dayColumn(_ bucket: MeSessionStore.DayBucket) -> some View {
        let isExpanded = expandedDayKey == bucket.id
        let last = bucket.entries.last
        let hasEntries = !bucket.entries.isEmpty

        Button {
            onTapDay(bucket)
        } label: {
            VStack(spacing: 6) {
                daySphere(last: last, moodCount: bucket.entries.count, isExpanded: isExpanded)
                Text(bucket.label)
                    .font(.system(size: 11, weight: bucket.isToday ? .medium : .light))
                    .foregroundStyle(bucket.isToday ? Color.gray : Color.gray.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasEntries)
        .accessibilityIdentifier("week.day.\(bucket.id)")
    }

    @ViewBuilder
    private func daySphere(last: SharedMood?, moodCount: Int, isExpanded: Bool) -> some View {
        if let last, let mood = last.mood {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(mood.color.opacity(isExpanded ? 0.38 : 0.2))
                    .frame(width: 48, height: 48)
                    .blur(radius: 9)
                    .opacity(isExpanded ? 1 : 0)

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
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mood.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 5)
                            .opacity(0.45)
                            .clipShape(Circle())
                    }
                    .overlay {
                        MoodIcon(kind: mood.icon, size: 17)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .overlay {
                        Circle().stroke(
                            isExpanded ? mood.color.opacity(0.55) : Color.white.opacity(0.5),
                            lineWidth: isExpanded ? 2 : 1.5
                        )
                    }
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)

                if moodCount > 1 {
                    Text("\(moodCount)")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.gray)
                        .frame(width: 14, height: 14)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.92))
                                .overlay {
                                    Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                                }
                        }
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 48, height: 48)
        } else {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                .foregroundStyle(Color.black.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Text("?")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gray.opacity(0.35))
                }
                .frame(width: 48, height: 48)
        }
    }

    private func dayDetailCard(_ bucket: MeSessionStore.DayBucket) -> some View {
        let needsScroll = bucket.entries.count >= Self.scrollFromCount

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(bucket.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.gray.opacity(0.55))
                Spacer(minLength: 0)
                Text("\(bucket.entries.count) mood\(bucket.entries.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.gray.opacity(0.45))
            }

            Group {
                if needsScroll {
                    ScrollView(.vertical, showsIndicators: true) {
                        moodRows(bucket.entries)
                    }
                    .frame(height: Self.scrollContentHeight)
                } else {
                    moodRows(bucket.entries)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.88),
                                    Color.white.opacity(0.72),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                }
        }
        .accessibilityIdentifier("week.day.detail")
    }

    private func moodRows(_ entries: [SharedMood]) -> some View {
        VStack(spacing: 8) {
            ForEach(entries) { entry in
                if let mood = entry.mood {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            mood.color.opacity(0.55),
                                            mood.color.opacity(0.28),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            MoodIcon(kind: mood.icon, size: 12)
                                .foregroundStyle(.white.opacity(0.95))
                        }
                        .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mood.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BeSideColor.textPrimary)
                            Text(mood.name)
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(BeSideColor.textMuted)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        Text(Self.timeString(entry.timestamp))
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.textMutedSoft)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        mood.color.opacity(0.16),
                                        mood.color.opacity(0.07),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
        }
    }

    private static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
