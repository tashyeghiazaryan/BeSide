import SwiftUI

struct LoveNotesPage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void
    let onCompose: () -> Void
    let onOpenNote: (LoveNote) -> Void
    var onDeleteNote: ((LoveNote) -> Void)? = nil

    @State private var openSwipeNoteID: String?

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private let pinkRGB = "248,187,208"

    var body: some View {
        ZStack {
            background
            content
        }
        .transition(.move(edge: .trailing))
        .accessibilityIdentifier("us.lovenotes.page")
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            BeSideBackground.loveNoteCanvas
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0xF8BBD0).opacity(0.35), .clear],
                center: UnitPoint(x: 0.12, y: -0.08),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: 0xE9D5FF).opacity(0.28), .clear],
                center: UnitPoint(x: 1, y: 0.2),
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFBCFE8).opacity(0.55), Color(hex: 0xC4B5FD).opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 350, height: 350)
                .blur(radius: 110)
                .offset(x: -100, y: -140)
                .allowsHitTesting(false)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFDECF5).opacity(0.55), Color(hex: 0xA7F3D0).opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 80, y: 300)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    incomingSection
                    outgoingSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.65))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Love Notes")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            composeCTA
        }
    }

    // MARK: - Incoming Section

    private var incomingSection: some View {
        let incoming = store.incomingLoveNotes.sorted { $0.createdAt > $1.createdAt }
        let unread = incoming.filter { $0.status == .sent }
        let readNotes = incoming.filter { $0.status == .read }

        return glassSection(
            pinkWash: true,
            headerLabel: "Incoming notes",
            headerSubtitle: "Left for you",
            count: incoming.count
        ) {
            if incoming.isEmpty {
                emptyState(
                    icon: "envelope",
                    title: "No notes for you yet",
                    subtitle: "When they write one, it will appear here."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(unread) { note in
                        incomingUnreadRow(note)
                    }
                    ForEach(readNotes) { note in
                        incomingReadRow(note)
                    }
                }
            }
        }
    }

    private func incomingUnreadRow(_ note: LoveNote) -> some View {
        swipeToDelete(note: note) {
            Button { onOpenNote(note) } label: {
                HStack(alignment: .top, spacing: 10) {
                    noteIconCircle(icon: "envelope.fill", pink: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New note")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(ink.opacity(0.88))
                        Text("\u{201C}\(LoveNoteBody.preview(note.body, max: 15))\u{201D}")
                            .font(.system(size: 11, weight: .medium))
                            .italic()
                            .foregroundStyle(ink.opacity(0.62))
                        Text(LoveNote.formatSentAt(note.createdAt))
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(ink.opacity(0.42))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(noteRowBackground(highlighted: true))
            }
            .buttonStyle(.plain)
        }
    }

    private func incomingReadRow(_ note: LoveNote) -> some View {
        swipeToDelete(note: note) {
            Button { onOpenNote(note) } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ink.opacity(0.38))
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seen")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ink.opacity(0.62))
                        Text("\u{201C}\(LoveNoteBody.preview(note.body, max: 15))\u{201D}")
                            .font(.system(size: 11, weight: .light))
                            .italic()
                            .foregroundStyle(ink.opacity(0.45))
                        Text(LoveNote.formatSentAt(note.createdAt))
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(ink.opacity(0.4))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(noteRowBackground(highlighted: false))
            }
            .buttonStyle(.plain)
            .opacity(0.95)
        }
    }

    // MARK: - Outgoing Section

    private var outgoingSection: some View {
        let outgoing = store.outgoingLoveNotes.sorted { $0.createdAt > $1.createdAt }

        return glassSection(
            pinkWash: false,
            headerLabel: "Sent by you",
            headerSubtitle: "On their way",
            count: outgoing.count
        ) {
            if outgoing.isEmpty {
                emptyState(
                    icon: "pencil",
                    title: "No notes yet — start with a little hello",
                    subtitle: "A few warm words can make their day."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(outgoing) { note in
                        outgoingRow(note)
                    }
                }
            }
        }
    }

    private func outgoingRow(_ note: LoveNote) -> some View {
        swipeToDelete(note: note) {
            Button { onOpenNote(note) } label: {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top, spacing: 10) {
                        if note.status == .read {
                            noteIconCircle(icon: "checkmark", pink: false)
                        } else {
                            noteIconCircle(icon: "paperplane.fill", pink: false)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(outgoingStatusLine(note))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(ink.opacity(0.72))
                            Text("\u{201C}\(LoveNoteBody.preview(note.body))\u{201D}")
                                .font(.system(size: 11, weight: .light))
                                .italic()
                                .foregroundStyle(ink.opacity(0.5))
                            Text(LoveNote.formatSentAt(note.createdAt))
                                .font(.system(size: 10, weight: .light))
                                .foregroundStyle(ink.opacity(0.4))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.trailing, 56)

                    statusBadge(note.status == .read ? "read" : "sent")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(noteRowBackground(highlighted: false))
            }
            .buttonStyle(.plain)
        }
    }

    private func swipeToDelete<Content: View>(
        note: LoveNote,
        @ViewBuilder content: () -> Content
    ) -> some View {
        SwipeToDeleteRow(
            isOpen: Binding(
                get: { openSwipeNoteID == note.id },
                set: { open in
                    if open {
                        openSwipeNoteID = note.id
                    } else if openSwipeNoteID == note.id {
                        openSwipeNoteID = nil
                    }
                }
            ),
            onDelete: {
                openSwipeNoteID = nil
                if let onDeleteNote {
                    onDeleteNote(note)
                } else {
                    store.deleteLoveNote(id: note.id)
                }
            },
            deleteAccessibilityLabel: "Delete note",
            deleteAccessibilityIdentifier: "us.lovenotes.delete"
        ) {
            content()
        }
        .accessibilityIdentifier("us.lovenotes.row.\(note.id)")
    }

    private func outgoingStatusLine(_ note: LoveNote) -> String {
        if note.status == .read { return "They've opened it" }
        return "On its way"
    }

    // MARK: - Compose CTA

    private var composeCTA: some View {
        Button(action: onCompose) {
            Text(store.outgoingLoveNotes.isEmpty ? "Write a note" : "Write another")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BeSideColor.navyLabel)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(BeSideColor.navyFill, in: Capsule())
                .shadow(color: Color(hex: 0x1A1A2E).opacity(0.16), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(
            store.outgoingLoveNotes.isEmpty ? "Write a note" : "Write another note"
        )
    }

    // MARK: - Shared Components

    private func glassSection<Content: View>(
        pinkWash: Bool,
        headerLabel: String,
        headerSubtitle: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(headerLabel)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(ink.opacity(0.42))
                    Text(headerSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ink.opacity(0.78))
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(ink.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.45))
                            .overlay(
                                Capsule().stroke(
                                    pinkWash ? Color(hex: 0xF8BBD0).opacity(0.22) : ink.opacity(0.08),
                                    lineWidth: 0.8
                                )
                            )
                    )
            }
            content()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: pinkWash
                                    ? [Color.white.opacity(0.55), Color(hex: 0xFDECF5).opacity(0.35)]
                                    : [Color.white.opacity(0.55), Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
                .overlay(alignment: .topLeading) {
                    if pinkWash {
                        RadialGradient(
                            colors: [Color(hex: 0xF8BBD0).opacity(0.16), .clear],
                            center: UnitPoint(x: 0.1, y: 0),
                            startRadius: 0,
                            endRadius: 180
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(ink.opacity(0.28))
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(ink.opacity(0.52))
            Text(subtitle)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(ink.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private func noteIconCircle(icon: String, pink: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14))
            .foregroundStyle(ink.opacity(pink ? 0.55 : 0.5))
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color.white.opacity(pink ? 0.55 : 0.5))
                    .overlay(
                        Circle().stroke(
                            pink ? Color(hex: 0xF8BBD0).opacity(0.25) : ink.opacity(0.08),
                            lineWidth: 0.8
                        )
                    )
            )
    }

    private func noteRowBackground(highlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                highlighted
                    ? LinearGradient(
                        colors: [Color.white.opacity(0.55), Color(hex: 0xFDECF5).opacity(0.38)],
                        startPoint: UnitPoint(x: 0.1, y: 0),
                        endPoint: UnitPoint(x: 0.9, y: 1)
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        highlighted
                            ? Color(hex: 0xF8BBD0).opacity(0.38)
                            : Color.white.opacity(0.35),
                        lineWidth: 0.8
                    )
            )
    }

    private func statusBadge(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 8, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(ink.opacity(label == "read" ? 0.36 : 0.5))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .overlay(Capsule().stroke(ink.opacity(0.08), lineWidth: 0.5))
            )
            .padding(.top, 2)
            .padding(.trailing, 2)
    }
}
