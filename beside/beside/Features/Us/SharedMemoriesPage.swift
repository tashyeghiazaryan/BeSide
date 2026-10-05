import SwiftUI

/// Shared Memories gallery — same memories as the Us home preview carousel.
struct SharedMemoriesPage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void
    let onAdd: () -> Void
    let onOpenMemory: (UsSharedMemory) -> Void
    let onEdit: (UsSharedMemory) -> Void
    let onDelete: (UsSharedMemory) -> Void

    @State private var dateFilter: String = "all"
    @State private var pendingDelete: UsSharedMemory?

    private var ink: Color { Color(hex: 0x26282B) }

    private var filtered: [UsSharedMemory] {
        store.sharedMemories(filterMonthKey: dateFilter)
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                filterChips
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    if filtered.isEmpty {
                        emptyState
                            .padding(.top, 64)
                            .padding(.horizontal, 16)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                            ],
                            spacing: 10
                        ) {
                            ForEach(filtered) { memory in
                                galleryCell(memory)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.bottom, BeSideMetrics.tabBarClearance)
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
        .accessibilityIdentifier("us.memories.page")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF8FAFC),
                    Color(hex: 0xFAF5FF),
                    Color(hex: 0xFDF2F8),
                    Color(hex: 0xF0FDF9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0xC4B5FD).opacity(0.28), .clear],
                center: UnitPoint(x: 0.88, y: -0.08),
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0xA7F3D0).opacity(0.18), .clear],
                center: UnitPoint(x: 0, y: 0.3),
                startRadius: 10,
                endRadius: 220
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xC4B5FD).opacity(0.4), Color(hex: 0xFBCFE8).opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 350, height: 350)
                .blur(radius: 110)
                .offset(x: -100, y: -140)
                .allowsHitTesting(false)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.44))
                            .overlay {
                                Circle().stroke(ink.opacity(0.15), lineWidth: 1.5)
                            }
                            .shadow(color: ink.opacity(0.06), radius: 8, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Us")
            .accessibilityIdentifier("us.memories.back")

            VStack(spacing: 2) {
                Text("Shared Memories")
                    .font(.system(size: 11, weight: .light))
                    .tracking(2.2)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.42))
                Text("All your moments")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ink.opacity(0.82))
            }
            .frame(maxWidth: .infinity)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.44))
                            .overlay {
                                Circle().stroke(ink.opacity(0.15), lineWidth: 1.5)
                            }
                            .shadow(color: ink.opacity(0.06), radius: 8, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a memory")
            .accessibilityIdentifier("us.memories.page.add")
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(key: "all", label: "All")
                ForEach(store.sharedMemoryMonthFilterKeys, id: \.self) { key in
                    filterChip(key: key, label: UsSharedMemories.monthLabel(key))
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityIdentifier("us.memories.filters")
    }

    private func filterChip(key: String, label: String) -> some View {
        let active = dateFilter == key
        return Button {
            dateFilter = key
        } label: {
            Text(label)
                .font(.system(size: 11, weight: active ? .medium : .regular))
                .foregroundStyle(ink.opacity(0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(active ? Color.white.opacity(0.72) : Color.white.opacity(0.44))
                        .overlay {
                            Capsule().stroke(
                                active ? ink.opacity(0.22) : ink.opacity(0.12),
                                lineWidth: active ? 1.5 : 1
                            )
                        }
                        .shadow(color: ink.opacity(0.05), radius: 6, y: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("us.memories.filter.\(key)")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(store.sharedMemories.isEmpty ? "No moments yet" : "Nothing in this month")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ink.opacity(0.7))
            Text(
                store.sharedMemories.isEmpty
                    ? "Add a memory to start your gallery — photos and little stories you want to keep together."
                    : "Try another date filter or add a new memory."
            )
            .font(.system(size: 12, weight: .light))
            .foregroundStyle(ink.opacity(0.45))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 260)

            Button(action: onAdd) {
                Text("Add a memory")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.72))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.44))
                            .overlay {
                                Capsule().stroke(ink.opacity(0.15), lineWidth: 1.5)
                            }
                            .shadow(color: ink.opacity(0.06), radius: 8, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private func galleryCell(_ memory: UsSharedMemory) -> some View {
        let hasPhoto = UsSharedMemories.hasPhoto(memory)
        return Button {
            onOpenMemory(memory)
        } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if hasPhoto {
                        SharedMemoryPhotoView(memory: memory)
                    } else {
                        Color(hex: 0xF0EEE9)
                            .overlay {
                                Text(memory.mood)
                                    .font(.system(size: 28))
                                    .opacity(0.85)
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if hasPhoto {
                    LinearGradient(
                        colors: [
                            Color(hex: 0x26282B).opacity(0.7),
                            Color(hex: 0x26282B).opacity(0.2),
                            .clear,
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(memory.mood)
                        .font(.system(size: 16))
                    Text(memory.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(hasPhoto ? Color.white : ink)
                        .lineLimit(2)
                    Text(UsSharedMemories.shortDateLabel(memory.dateTime))
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(hasPhoto ? Color.white.opacity(0.8) : ink.opacity(0.45))
                    if !memory.description.isEmpty {
                        Text(memory.description)
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(hasPhoto ? Color.white.opacity(0.75) : ink.opacity(0.42))
                            .lineLimit(2)
                    }
                }
                .padding(12)
            }
            // Fixed cell aspect keeps grid tiles equal and stops photos from overlapping neighbors.
            .aspectRatio(3 / 4, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
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
        }
        .accessibilityLabel("Open memory \(memory.title)")
        .accessibilityIdentifier("us.memories.cell.\(memory.id)")
    }
}
