import SwiftUI

struct LoveNoteComposeModal: View {
    let onClose: () -> Void
    /// Returns true when the note was accepted; modal shows navy success then dismisses.
    let onSend: (String) -> Bool

    @State private var noteBody = ""
    @State private var showSuccess = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var bodyFocused: Bool

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private let pink = Color(hex: 0xF8BBD0)
    private var charCount: Int { LoveNoteBody.characterCount(noteBody) }
    private var canSend: Bool {
        !noteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        // NavigationStack is required for reliable FocusState/keyboard on Us overlays
        // (same pattern as Me). Background stays clear so this stays a centered card, not a page.
        NavigationStack {
            ZStack {
                scrim
                    .onTapGesture {
                        guard !showSuccess else { return }
                        if bodyFocused {
                            bodyFocused = false
                        } else {
                            close()
                        }
                    }

                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    card
                        .padding(.horizontal, 20)

                    if keyboardHeight > 80 {
                        Color.clear
                            .frame(height: keyboardHeight + 10)
                            .allowsHitTesting(false)
                    } else {
                        Spacer(minLength: 16)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { bodyFocused = false }
                        .fontWeight(.semibold)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .background(Color.clear)
        .onAppear {
            // Delay until overlay is in the window — immediate focus often no-ops.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                guard !showSuccess else { return }
                bodyFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .accessibilityIdentifier("us.lovenotes.compose.modal")
    }

    private var scrim: some View {
        ZStack {
            Color(hex: 0x26282B).opacity(0.26)
            RadialGradient(
                colors: [pink.opacity(0.14), .clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 0) {
            closeButton

            VStack(spacing: 0) {
                Text("Write a note")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.88))
                    .padding(.bottom, 16)

                textArea

                HStack(alignment: .top) {
                    Text("Latin letters, numbers, punctuation & emoji — max \(LoveNoteBody.maxLength) characters.")
                        .font(.system(size: 9, weight: .light))
                        .foregroundStyle(ink.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(charCount)/\(LoveNoteBody.maxLength)")
                        .font(.system(size: 10, weight: .light).monospacedDigit())
                        .foregroundStyle(ink.opacity(0.42))
                }
                .padding(.bottom, 16)

                sendButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 8)
        }
        .frame(maxWidth: 360)
        .fixedSize(horizontal: false, vertical: true)
        .background { glassBackground }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(pink.opacity(0.38), lineWidth: 0.9)
        }
        .shadow(color: pink.opacity(0.22), radius: 36, y: 8)
        .shadow(color: Color(hex: 0xEC4899).opacity(0.18), radius: 56, y: 0)
        .shadow(color: Color.black.opacity(0.10), radius: 20, y: 10)
        .environment(\.colorScheme, .light)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
    }

    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            Color(hex: 0xFFFAFD).opacity(0.28),
                            Color(hex: 0xFDECF6).opacity(0.32),
                            Color.white.opacity(0.30),
                        ],
                        startPoint: UnitPoint(x: 0.15, y: 0),
                        endPoint: UnitPoint(x: 0.85, y: 1)
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [pink.opacity(0.28), .clear],
                        center: UnitPoint(x: 0.5, y: -0.08),
                        startRadius: 0,
                        endRadius: 220
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xF472B6).opacity(0.14), .clear],
                        center: UnitPoint(x: 0.8, y: 1.05),
                        startRadius: 0,
                        endRadius: 180
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.88), Color.white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                guard !showSuccess else { return }
                bodyFocused = false
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay { Circle().fill(Color.white.opacity(0.45)) }
                            .overlay { Circle().stroke(Color.white.opacity(0.55), lineWidth: 0.6) }
                    }
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .padding(.top, 14)
            .zIndex(20)
            .accessibilityLabel("Close")
        }
    }

    private var textArea: some View {
        TextField("Something warm for them…", text: $noteBody, axis: .vertical)
            .lineLimit(4...7)
            .font(.system(size: 13))
            .foregroundStyle(ink)
            .focused($bodyFocused)
            .submitLabel(.done)
            .onSubmit { bodyFocused = false }
            .disabled(showSuccess)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 110, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ink.opacity(0.12), lineWidth: 0.8)
                    )
            )
            .onChange(of: noteBody) { _, newValue in
                let sanitized = LoveNoteBody.sanitize(newValue)
                if sanitized != newValue { noteBody = sanitized }
            }
            .padding(.bottom, 6)
            .accessibilityIdentifier("us.lovenotes.compose.body")
    }

    private var sendButton: some View {
        Button(action: send) {
            HStack(spacing: 8) {
                if showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                }
                Text(showSuccess ? "Sent" : "Send note")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(showSuccess ? BeSideColor.navyLabel : ink.opacity(canSend ? 0.88 : 0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        showSuccess
                            ? AnyShapeStyle(BeSideColor.navyFill)
                            : AnyShapeStyle(Color.white.opacity(0.55))
                    )
                    .background {
                        if !showSuccess {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay {
                        if !showSuccess {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(ink.opacity(0.12), lineWidth: 0.8)
                        }
                    }
                    .shadow(
                        color: showSuccess
                            ? BeSideColor.navyStart.opacity(0.22)
                            : Color.black.opacity(0.06),
                        radius: showSuccess ? 10 : 4,
                        y: showSuccess ? 4 : 2
                    )
            }
            .opacity(showSuccess || canSend ? 1 : 0.55)
            .animation(.easeOut(duration: 0.2), value: showSuccess)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!showSuccess && canSend)
        .accessibilityLabel(showSuccess ? "Sent" : "Send note")
        .accessibilityIdentifier("us.lovenotes.compose.send")
    }

    private func close() {
        bodyFocused = false
        onClose()
    }

    private func send() {
        guard canSend, !showSuccess else { return }
        bodyFocused = false
        guard onSend(noteBody) else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            showSuccess = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            onClose()
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            keyboardHeight = 0
            return
        }
        let screenHeight = UIScreen.main.bounds.height
        let overlap = max(0, screenHeight - frame.origin.y)
        let next = overlap > 80 ? overlap : 0
        guard next != keyboardHeight else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardHeight = next
        }
    }
}
