import SwiftUI
import UIKit

/// Full-screen couple story — tap to advance / dismiss.
struct CoupleStoryViewer: View {
    let stories: [UsCoupleStory]
    let startID: String
    let meLabel: String
    let partnerLabel: String
    let onSeen: (String) -> Void
    let onClose: () -> Void

    @State private var index: Int = 0

    private var current: UsCoupleStory? {
        guard stories.indices.contains(index) else { return nil }
        return stories[index]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = current, let image = UIImage(data: story.imageJPEG) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color(hex: 0x1A1A2E).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Progress pips
                HStack(spacing: 4) {
                    ForEach(Array(stories.indices), id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i <= index ? 0.95 : 0.28))
                            .frame(height: 2.5)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                HStack {
                    Text(authorLabel(for: current))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.18)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()
            }

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goBack() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goForward() }
            }
        }
        .onAppear {
            if let i = stories.firstIndex(where: { $0.id == startID }) {
                index = i
            }
            markCurrentSeen()
        }
        .onChange(of: index) { _, _ in
            markCurrentSeen()
        }
        .hidesFloatingTabBar()
        .accessibilityIdentifier("us.stories.viewer")
    }

    private func authorLabel(for story: UsCoupleStory?) -> String {
        guard let story else { return "" }
        return story.author == .me ? meLabel : partnerLabel
    }

    private func markCurrentSeen() {
        guard let id = current?.id else { return }
        onSeen(id)
    }

    private func goBack() {
        if index > 0 {
            index -= 1
        } else {
            onClose()
        }
    }

    private func goForward() {
        if index + 1 < stories.count {
            index += 1
        } else {
            onClose()
        }
    }
}
