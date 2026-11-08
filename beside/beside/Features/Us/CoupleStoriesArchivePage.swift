import SwiftUI
import UIKit

/// Grid of past couple stories — opened from the Us strip “See all” cell.
struct CoupleStoriesArchivePage: View {
    let stories: [UsCoupleStory]
    let meLabel: String
    let partnerLabel: String
    let onClose: () -> Void
    let onOpenStory: (String) -> Void

    private var ink: Color { Color(hex: 0x26282B) }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack {
            BeSideBackground.softCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    if stories.isEmpty {
                        emptyState
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(stories) { story in
                                archiveCell(story)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    Color.clear.frame(height: 40)
                }
            }
        }
        .hidesFloatingTabBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.stories.archive.page")
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ink.opacity(0.35))
            Text("No stories yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.62))
            Text("Every story lands here as soon as you share it, and stays after the 24-hour ring is gone.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(ink.opacity(0.42))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.48))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
        }
        .environment(\.colorScheme, .light)
    }

    private func archiveCell(_ story: UsCoupleStory) -> some View {
        Button {
            onOpenStory(story.id)
        } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = UIImage(data: story.imageJPEG) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: 0xF3D6DE), Color(hex: 0xE8BEC9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()

                LinearGradient(
                    colors: [
                        Color(hex: 0x26282B).opacity(0.55),
                        Color(hex: 0x26282B).opacity(0.12),
                        .clear,
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(story.author == .me ? meLabel : partnerLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .lineLimit(1)
                    Text(Self.dateLabel(story.createdAt))
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineLimit(1)
                }
                .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Story from \(story.author == .me ? meLabel : partnerLabel), \(Self.dateLabel(story.createdAt))"
        )
        .accessibilityIdentifier("us.stories.archive.item.\(story.id)")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .overlay {
                                Circle().stroke(ink.opacity(0.08), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("us.stories.archive.back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Our stories")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ink.opacity(0.88))
                Text("Saved the moment you share — kept forever")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
    }

    private static func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
