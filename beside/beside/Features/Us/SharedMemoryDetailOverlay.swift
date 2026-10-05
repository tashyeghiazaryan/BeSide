import SwiftUI

/// Full-screen Shared Memories feed — Instagram-style vertical scroll.
struct SharedMemoryDetailOverlay: View {
    let memories: [UsSharedMemory]
    @Binding var selectedID: String?
    let onClose: () -> Void
    let onEdit: (UsSharedMemory) -> Void
    let onDelete: (UsSharedMemory) -> Void

    @State private var pendingDelete: UsSharedMemory?

    private var ink: Color { Color(hex: 0x1A1A2E) }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0xFAFAFA)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    // VStack (not Lazy) so every remote photo starts loading when the feed opens.
                    VStack(spacing: 28) {
                        Color.clear
                            .frame(height: 52)
                            .id("feed-top")

                        ForEach(memories) { memory in
                            feedPost(memory)
                                .id(memory.id)
                        }

                        Color.clear.frame(height: BeSideMetrics.tabBarClearance + 24)
                    }
                }
                .onAppear {
                    scrollToSelection(proxy: proxy)
                }
                .onChange(of: selectedID) { _, _ in
                    scrollToSelection(proxy: proxy)
                }
            }

            topBar
        }
        .confirmationDialog(
            "Delete this memory?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    onDelete(pendingDelete)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            if let pendingDelete {
                Text("“\(pendingDelete.title)” will be removed from Shared Memories.")
            }
        }
        .accessibilityIdentifier("us.memories.detail")
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.72))
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .overlay {
                                Circle().stroke(ink.opacity(0.1), lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("us.memories.detail.close")

            Spacer()

            Text("Shared Memories")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.72))

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            LinearGradient(
                colors: [Color(hex: 0xFAFAFA), Color(hex: 0xFAFAFA).opacity(0.92), Color(hex: 0xFAFAFA).opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
    }

    private func feedPost(_ memory: UsSharedMemory) -> some View {
        let hasPhoto = UsSharedMemories.hasPhoto(memory)
        return VStack(alignment: .leading, spacing: 0) {
            // Header row — mood + title (Instagram-like post header)
            HStack(spacing: 10) {
                Text(memory.mood)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color(hex: 0xF0EEE9))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(memory.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.9))
                        .lineLimit(1)
                    Text(UsSharedMemories.shortDateLabel(memory.dateTime))
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(ink.opacity(0.45))
                }

                Spacer(minLength: 8)

                Menu {
                    Button {
                        onEdit(memory)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        pendingDelete = memory
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.55))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Memory options")
                .accessibilityIdentifier("us.memories.detail.menu.\(memory.id)")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // Photo — full-width square feed frame
            SharedMemoryPhotoView(memory: memory)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Color(hex: 0xF0EEE9))
                .clipped()

            // Actions + caption
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ShareLink(item: UsSharedMemories.shareText(for: memory)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(ink.opacity(0.78))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("us.memories.detail.share")

                    Spacer()
                }
                .padding(.top, 10)

                if !memory.description.isEmpty {
                    Text(memory.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(ink.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                } else if !hasPhoto {
                    Text(memory.title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(ink.opacity(0.78))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
        }
        .accessibilityLabel(memory.title)
    }

    private func scrollToSelection(proxy: ScrollViewProxy) {
        guard let selectedID else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(selectedID, anchor: .top)
            }
        }
    }
}
