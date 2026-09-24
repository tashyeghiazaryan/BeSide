import SwiftUI
import UIKit

struct PartnerView: View {
    @Bindable var store: MeSessionStore

    /// Composer open for pick emoji + optional note, then one Send.
    @State private var isComposing = false
    @State private var draftEmoji: String?
    @State private var justSentReaction = false
    @State private var noteText = ""
    @State private var fieldError: String?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var noteFocused: Bool

    private let reactionEmojis = ["❤️", "🤗", "😊", "👏", "💪", "🔥", "😍", "💐"]

    private enum ScrollID {
        static let noteField = "partner.note.block"
        static let composerBottom = "partner.composer.bottom"
        static let week = "partner.week"
        static let weekBottom = "partner.weekBottom"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pairedContent
                    .blur(radius: store.isPaired ? 0 : 5)
                    .opacity(store.isPaired ? 1 : 0.72)
                    .scaleEffect(store.isPaired ? 1 : 1.02, anchor: .top)
                    .allowsHitTesting(store.isPaired)

                if !store.isPaired {
                    PartnerPairingModal(inviteCode: store.inviteCode) {
                        store.completePairing()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                        .fontWeight(.semibold)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AppTab.partner.screenIdentifier)
            .onAppear {
                noteText = store.myNoteToPartner ?? ""
                draftEmoji = store.myReactionToPartner
            }
            .onChange(of: store.partnerCurrentMood.id) { _, _ in
                dismissKeyboard()
                isComposing = false
                justSentReaction = false
                fieldError = nil
                noteText = store.myNoteToPartner ?? ""
                draftEmoji = store.myReactionToPartner
            }
            .onChange(of: isComposing) { _, composing in
                if composing {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        guard isComposing else { return }
                        noteFocused = true
                    }
                } else {
                    noteFocused = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
                updateKeyboardHeight(from: note)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
    }

    private var pairedContent: some View {
        ZStack {
            BeSideBackground.softCanvas
                .ignoresSafeArea()

            if let mood = store.partnerCurrentMood.mood {
                BeSideBackground.moodAmbient(
                    color: mood.color,
                    gradientColors: mood.gradientColors
                )
                .ignoresSafeArea()
            } else {
                BeSideBackground.defaultAmbientBlobs()
                    .ignoresSafeArea()
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 16)

                        Text("Your partner's mood")
                            .font(.system(size: 28, weight: .ultraLight))
                            .tracking(0.4)
                            .foregroundStyle(BeSideColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)

                        if let mood = store.partnerCurrentMood.mood {
                            Text(
                                "\(store.partnerDisplayName) feels \(PartnerCareSuggestions.feelingPhrase(for: mood.id)) today"
                            )
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(mood.color.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 22)

                            heroCard(mood: mood)
                                .padding(.bottom, 28)

                            if isComposing {
                                Color.clear
                                    .frame(height: max(keyboardHeight, BeSideMetrics.tabBarClearance) + 24)
                                    .id(ScrollID.composerBottom)
                                    .allowsHitTesting(false)
                            }

                            careSection(moodID: mood.id)
                                .padding(.bottom, 24)

                            WeekMoodStrip(
                                title: "Mood this week",
                                accessibilityID: "partner.week.strip",
                                buckets: store.partnerWeekBuckets(),
                                expandedDayKey: store.expandedPartnerDayKey,
                                onTapDay: { bucket in
                                    dismissKeyboard()
                                    store.togglePartnerDay(bucket.id, hasEntries: !bucket.entries.isEmpty)
                                }
                            )
                            .id(ScrollID.week)
                            .padding(.bottom, 28)

                            Color.clear
                                .frame(height: store.expandedPartnerDayKey == nil ? 8 : 32)
                                .id(ScrollID.weekBottom)
                                .allowsHitTesting(false)
                        } else {
                            GlassPanel {
                                Text("\(store.partnerDisplayName) hasn’t shared a mood yet")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundStyle(BeSideColor.textMuted)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(20)
                            }
                            .padding(.bottom, 28)
                        }

                        Color.clear.frame(height: BeSideMetrics.tabBarClearance)
                    }
                    .padding(.horizontal, BeSideMetrics.pageInset)
                    .padding(.bottom, BeSideMetrics.tabBarClearance + (noteFocused ? keyboardHeight : 0))
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: noteFocused) { _, focused in
                    guard focused else { return }
                    scrollNoteAboveKeyboard(proxy: proxy)
                }
                .onChange(of: keyboardHeight) { _, height in
                    guard height > 0, noteFocused else { return }
                    scrollNoteAboveKeyboard(proxy: proxy)
                }
                .onChange(of: fieldError) { _, error in
                    guard error != nil, noteFocused || isComposing else { return }
                    scrollNoteAboveKeyboard(proxy: proxy)
                }
                .onChange(of: store.expandedPartnerDayKey) { _, key in
                    guard key != nil else { return }
                    scrollWeekDropdownIntoView(proxy: proxy)
                }
            }
        }
    }

    private func heroCard(mood: Mood) -> some View {
        let shared = store.partnerCurrentMood

        return VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    mood.color.opacity(0.7),
                    mood.color.opacity(0.35),
                    mood.color.opacity(0.08),
                    Color.clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    heroSphere(mood: mood)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(mood.name)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(BeSideColor.textPrimary)
                        Text("\"\(shared.wish)\"")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(BeSideColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(Self.formatTimestamp(shared.timestamp))
                                .font(.system(size: 11, weight: .light))
                        }
                        .foregroundStyle(BeSideColor.textMutedSoft)
                        .padding(.top, 6)
                    }
                    Spacer(minLength: 0)
                }

                Divider()
                    .overlay(mood.color.opacity(0.12))
                    .padding(.vertical, 14)

                reactionComposer(mood: mood)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            LinearGradient(
                colors: [Color.clear, mood.color.opacity(0.12), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.color.opacity(0.14),
                                    mood.color.opacity(0.05),
                                    Color.white.opacity(0.55),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(mood.color.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: mood.color.opacity(0.16), radius: 20, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityIdentifier("partner.current.mood")
    }

    private func heroSphere(mood: Mood) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: mood.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 92)
                .blur(radius: 18)
                .opacity(0.55)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [mood.color.opacity(0.95), mood.color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: mood.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 14)
                        .opacity(0.5)
                        .clipShape(Circle())
                }
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    MoodIcon(kind: mood.icon, size: 30)
                        .foregroundStyle(.white.opacity(0.95))
                }
                .overlay {
                    Circle().stroke(Color.white.opacity(0.75), lineWidth: 2.5)
                }
                .shadow(color: mood.color.opacity(0.4), radius: 14, y: 4)
        }
        .frame(width: 92, height: 92)
    }

    @ViewBuilder
    private func reactionComposer(mood: Mood) -> some View {
        Group {
            if justSentReaction, let reaction = store.myReactionToPartner {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text(reaction)
                            .font(.system(size: 22))
                        Text("Reaction sent!")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.textMutedSoft)
                    }
                    if let note = store.myNoteToPartner, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.wishTextIdle)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityIdentifier("partner.reaction.sent")
            } else if let reaction = store.myReactionToPartner {
                // One reaction per partner mood — display only.
                VStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(reaction)
                            .font(.system(size: 18))
                        Text("You reacted")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.textMutedSoft)
                    }
                    .frame(maxWidth: .infinity)

                    if let note = store.myNoteToPartner, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(BeSideColor.wishTextIdle)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityIdentifier("partner.reaction.locked")
            } else if isComposing {
                VStack(alignment: .leading, spacing: 12) {
                    Text("React to \(store.partnerDisplayName)'s mood")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(BeSideColor.textMutedSoft)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        ForEach(Array(reactionEmojis.enumerated()), id: \.element) { index, emoji in
                            let isSelected = draftEmoji == emoji
                            Button {
                                draftEmoji = emoji
                                fieldError = nil
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 18))
                                    .frame(width: 36, height: 36)
                                    .background {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        mood.color.opacity(isSelected ? 0.28 : 0.12),
                                                        mood.color.opacity(isSelected ? 0.14 : 0.05),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay {
                                                Circle().stroke(
                                                    mood.color.opacity(isSelected ? 0.45 : 0.15),
                                                    lineWidth: isSelected ? 1.5 : 1
                                                )
                                            }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("partner.reaction.\(index)")
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Add a note to their mood…", text: $noteText)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(BeSideColor.wishText)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                            .focused($noteFocused)
                            .submitLabel(.done)
                            .onSubmit { dismissKeyboard() }
                            .onChange(of: noteText) { _, newValue in
                                let limited = PartnerNoteRules.limitLength(
                                    PartnerNoteRules.normalizeInput(newValue)
                                )
                                if limited != newValue { noteText = limited }
                                fieldError = nil
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.45))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                fieldError == nil
                                                    ? Color.white.opacity(0.55)
                                                    : Color.red.opacity(0.55),
                                                lineWidth: fieldError == nil ? 1 : 1.5
                                            )
                                    }
                            }
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("partner.note.field")

                        HStack(alignment: .top) {
                            if let fieldError {
                                Text(fieldError)
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundStyle(Color.red.opacity(0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityIdentifier("partner.note.error")
                            }
                            Spacer(minLength: 8)
                            Text("\(noteText.count)/\(PartnerNoteRules.maxLength)")
                                .font(.system(size: 10, weight: .light))
                                .foregroundStyle(
                                    noteText.count >= PartnerNoteRules.maxLength
                                        ? Color.red.opacity(0.65)
                                        : BeSideColor.textMutedSoft
                                )
                        }
                    }
                    .id(ScrollID.noteField)

                    Button(action: {
                        dismissKeyboard()
                        sendReaction()
                    }) {
                        Text("Send reaction")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(BeSideColor.shareIdleText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(mood.color.opacity(0.22))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(mood.color.opacity(0.28), lineWidth: 1.2)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("partner.reaction.send")

                    Button("Cancel") {
                        dismissKeyboard()
                        isComposing = false
                        fieldError = nil
                        draftEmoji = nil
                        noteText = ""
                    }
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color.gray.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    draftEmoji = nil
                    noteText = ""
                    fieldError = nil
                    isComposing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.gray.opacity(0.55))
                        Text("Send a reaction")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.gray.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [mood.color.opacity(0.12), mood.color.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(mood.color.opacity(0.15), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("partner.reaction.open")
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func careSection(moodID: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Small ways to show you care")
                .font(.system(size: 12, weight: .light))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.25))
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(PartnerCareSuggestions.lines(for: moodID), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color(hex: 0x666666))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.25),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 0.8)
                                }
                                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                        }
                }
            }
        }
        .accessibilityIdentifier("partner.care.suggestions")
    }

    private func sendReaction() {
        guard store.myReactionToPartner == nil else { return }
        // Emoji is required — alert under the note field (same place as note errors).
        guard let emoji = draftEmoji else {
            fieldError = "Choose an emoji reaction before sending."
            return
        }
        if let noteError = PartnerNoteRules.validate(noteText) {
            fieldError = noteError.inlineMessage
            return
        }
        dismissKeyboard()
        store.respondToPartnerMood(reaction: emoji, note: noteText)
        fieldError = nil
        isComposing = false
        justSentReaction = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            justSentReaction = false
        }
    }

    private func dismissKeyboard() {
        noteFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
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
        // Ignore tiny accessory-only frames (hardware keyboard / Done strip).
        keyboardHeight = overlap > 80 ? overlap : 0
    }

    private func scrollNoteAboveKeyboard(proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(ScrollID.noteField, anchor: .center)
            }
        }
    }

    private func scrollWeekDropdownIntoView(proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(ScrollID.weekBottom, anchor: .bottom)
            }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(ScrollID.weekBottom, anchor: .bottom)
            }
        }
    }

    private static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d 'at' HH:mm"
        return formatter.string(from: date)
    }
}
