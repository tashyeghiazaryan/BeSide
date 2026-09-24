import SwiftUI

struct PartnerView: View {
    @Bindable var store: MeSessionStore

    @State private var selectedReaction: String?
    @State private var noteText = ""
    @State private var fieldError: String?
    @State private var justSent = false

    private let reactionEmojis = ["❤️", "🤗", "😊", "👏", "💪", "🔥", "😍", "💐"]

    var body: some View {
        ZStack {
            BeSideBackground.softCanvas
                .ignoresSafeArea()
            BeSideBackground.defaultAmbientBlobs()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 12)

                    Text("Your partner's mood")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(BeSideColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)

                    if let mood = store.partnerCurrentMood.mood {
                        partnerMoodCard(mood: mood)
                            .padding(.bottom, 18)
                        reactionSection(mood: mood)
                    } else {
                        GlassPanel {
                            Text("\(store.partnerDisplayName) hasn’t shared a mood yet")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(BeSideColor.textMuted)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        }
                    }

                    Color.clear.frame(height: BeSideMetrics.tabBarClearance)
                }
                .padding(.horizontal, BeSideMetrics.pageInset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.partner.screenIdentifier)
        .onAppear(perform: syncDraft)
        .onChange(of: store.partnerCurrentMood.id) { _, _ in
            syncDraft()
            justSent = false
            fieldError = nil
        }
    }

    private func partnerMoodCard(mood: Mood) -> some View {
        let shared = store.partnerCurrentMood
        return GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [mood.color.opacity(0.56), mood.color.opacity(0.31)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        MoodIcon(kind: mood.icon, size: 20)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mood.name)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(BeSideColor.textPrimary)
                        Text(shared.wish)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BeSideColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(store.partnerDisplayName)
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(BeSideColor.textMutedSoft)
                    }
                    Spacer(minLength: 0)
                }

                if store.hasResponseToPartner {
                    myNoteOnPartnerMood(mood: mood)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .accessibilityIdentifier("partner.current.mood")
    }

    @ViewBuilder
    private func myNoteOnPartnerMood(mood: Mood) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let reaction = store.myReactionToPartner {
                HStack(spacing: 6) {
                    Text(reaction)
                        .font(.system(size: 14))
                    Text("You reacted")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(BeSideColor.textMutedSoft)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [mood.color.opacity(0.10), mood.color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(mood.color.opacity(0.15), lineWidth: 1)
                        }
                }
                .accessibilityIdentifier("partner.my.reaction.chip")
            }

            if let note = store.myNoteToPartner?.trimmingCharacters(in: .whitespacesAndNewlines),
               !note.isEmpty
            {
                Text(note)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(BeSideColor.wishTextIdle)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("partner.my.note")
            }
        }
        .padding(.top, 2)
    }

    private func reactionSection(mood: Mood) -> some View {
        GlassPanel(cornerRadius: BeSideMetrics.glassCornerLarge) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.hasResponseToPartner ? "Update your note" : "React to their mood")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(BeSideColor.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(Array(reactionEmojis.enumerated()), id: \.element) { index, emoji in
                        let isSelected = selectedReaction == emoji
                        Button {
                            selectedReaction = emoji
                            fieldError = nil
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected ? mood.color.opacity(0.18) : Color.white.opacity(0.35))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(
                                                    isSelected ? mood.color.opacity(0.45) : Color.white.opacity(0.5),
                                                    lineWidth: isSelected ? 1.5 : 1
                                                )
                                        }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("partner.reaction.\(index)")
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Add a note to their mood…", text: $noteText)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(BeSideColor.wishText)
                        .onChange(of: noteText) { _, newValue in
                            let limited = PartnerNoteRules.limitLength(newValue)
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
                                            fieldError == nil ? Color.white.opacity(0.55) : Color.red.opacity(0.55),
                                            lineWidth: fieldError == nil ? 1 : 1.5
                                        )
                                }
                        }
                        .accessibilityIdentifier("partner.note.field")

                    HStack {
                        if let fieldError {
                            Text(fieldError)
                                .font(.system(size: 11, weight: .light))
                                .foregroundStyle(Color.red.opacity(0.75))
                        }
                        Spacer()
                        Text("\(noteText.count)/\(PartnerNoteRules.maxLength)")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(
                                noteText.count >= PartnerNoteRules.maxLength
                                    ? Color.red.opacity(0.65)
                                    : BeSideColor.textMutedSoft
                            )
                    }
                }

                Button(action: send) {
                    Text(justSent ? "Sent!" : (store.hasResponseToPartner ? "Update" : "Send"))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(justSent ? BeSideColor.navyLabel : BeSideColor.shareIdleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if justSent {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(BeSideColor.navyFill)
                            } else {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(mood.color.opacity(0.22))
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(mood.color.opacity(0.28), lineWidth: 1.2)
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(selectedReaction == nil)
                .opacity(selectedReaction == nil ? 0.55 : 1)
                .accessibilityIdentifier("partner.reaction.send")
            }
            .padding(16)
        }
        .accessibilityIdentifier("partner.reaction.panel")
    }

    private func syncDraft() {
        selectedReaction = store.myReactionToPartner
        noteText = store.myNoteToPartner ?? ""
    }

    private func send() {
        guard let reaction = selectedReaction else { return }
        if !PartnerNoteRules.isValidOptionalNote(noteText) {
            fieldError = "Only Latin letters, numbers, punctuation (.,!?-:\"), spaces, and emoji. Max \(PartnerNoteRules.maxLength) characters."
            return
        }
        store.respondToPartnerMood(reaction: reaction, note: noteText)
        fieldError = nil
        justSent = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            justSent = false
        }
    }
}
