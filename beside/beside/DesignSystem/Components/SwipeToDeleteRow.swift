import SwiftUI

/// Swipe left to reveal a small trailing delete control for that row only.
struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isOpen: Bool
    let onDelete: () -> Void
    var deleteAccessibilityLabel: String = "Delete"
    var deleteAccessibilityIdentifier: String = "swipe.delete"
    @ViewBuilder let content: Content

    @State private var dragOffset: CGFloat = 0

    private let revealWidth: CGFloat = 52
    private let openThreshold: CGFloat = 28
    private var ink: Color { Color(hex: 0x1A1A2E) }

    private var revealedOffset: CGFloat {
        let base = isOpen ? -revealWidth : 0
        return min(0, max(-revealWidth, base + dragOffset))
    }

    private var isRevealing: Bool { revealedOffset < -0.5 }

    var body: some View {
        ZStack(alignment: .trailing) {
            content
                .offset(x: revealedOffset)
                .overlay {
                    // Cover only the still-visible content when open — not the
                    // trailing reveal slot (overlay uses layout bounds, not offset).
                    if isOpen {
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(perform: closeSwipe)
                            Color.clear
                                .frame(width: revealWidth)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .highPriorityGesture(swipeGesture)

            if isRevealing {
                Button {
                    onDelete()
                    closeSwipe()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ink.opacity(0.48))
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .overlay {
                                    Circle().stroke(ink.opacity(0.1), lineWidth: 0.8)
                                }
                        }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .accessibilityLabel(deleteAccessibilityLabel)
                .accessibilityIdentifier(deleteAccessibilityIdentifier)
                .zIndex(1)
            }
        }
        .clipped()
        .onChange(of: isOpen) { _, open in
            if !open {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    dragOffset = 0
                }
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                if abs(value.translation.height) > abs(dx) + 10, !isOpen {
                    dragOffset = 0
                    return
                }
                if isOpen {
                    dragOffset = min(revealWidth, max(-revealWidth, dx))
                } else {
                    dragOffset = min(0, max(-revealWidth, dx))
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    if isOpen {
                        isOpen = dx < openThreshold
                    } else {
                        isOpen = dx < -openThreshold
                    }
                    dragOffset = 0
                }
            }
    }

    private func closeSwipe() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isOpen = false
            dragOffset = 0
        }
    }
}
