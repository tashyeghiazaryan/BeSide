import SwiftUI
import UIKit

/// Question of the day — shared prompt, private answers, dialogue when both have submitted.
struct QuestionOfTheDayHub: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void

    @State private var draft = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var composerFocused: Bool

    private var ink: Color { Color(hex: 0x1A1A2E) }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsComposer: Bool {
        !store.hasMeQuestionAnswer
    }

    var body: some View {
        // NavigationStack makes FocusState / keyboard reliable on Connection overlays
        // (same pattern as LoveNoteComposeModal).
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 0) {
                    header

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            questionCard
                            if store.bothQuestionAnswersReady {
                                dialogue
                            } else if store.hasMeQuestionAnswer {
                                waitingState
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, showsComposer ? 24 : 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        // Tap outside the field dismisses keyboard without fighting focus.
                        composerFocused = false
                    }

                    if showsComposer {
                        composerBar
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(
                                .bottom,
                                keyboardHeight > 0
                                    ? keyboardHeight + 8
                                    : 12
                            )
                            .background {
                                composerChrome
                            }
                            // Animate only the lift — not the whole hub (avoids sluggish first focus).
                            .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(.keyboard)
        }
        .hidesFloatingTabBar()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.qotd.hub")
    }

    private var background: some View {
        ZStack {
            BeSideBackground.activityCanvas
                .ignoresSafeArea()
            BeSideBackground.activityAmbientBlobs()
        }
    }

    private var composerChrome: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 12, weight: .light))
                    }
                    .foregroundStyle(Color.black.opacity(0.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("connection.qotd.back")

                Spacer()
            }

            HStack(spacing: 8) {
                BesideLogoMark(size: 28)
                Text("beside")
                    .font(.system(size: 22, weight: .ultraLight))
                    .tracking(1.2)
                    .foregroundStyle(ink.opacity(0.88))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question of the day")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.35))

            Text(store.questionOfTheDayPrompt)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(ink.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
        }
        .accessibilityIdentifier("connection.qotd.question")
    }

    private var composerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your answer")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.4))

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Write something kind and specific…", text: $draft, axis: .vertical)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ink.opacity(0.9))
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            }
                    }
                    .focused($composerFocused)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.return)
                    .accessibilityIdentifier("connection.qotd.composer")

                Button {
                    guard store.submitQuestionOfTheDayAnswer(draft) else { return }
                    draft = ""
                    composerFocused = false
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(canSend ? Color.white : Color.white.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(canSend ? BeSideColor.navyStart : BeSideColor.navyStart.opacity(0.35))
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send answer")
                .accessibilityIdentifier("connection.qotd.send")
            }
        }
    }

    private var waitingState: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BeSideColor.navyStart.opacity(0.75))
                Text("You answered")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.7))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.7))
            }
            .accessibilityIdentifier("connection.qotd.you-answered")

            VStack(spacing: 8) {
                ProgressView()
                    .tint(ink.opacity(0.45))
                Text("Waiting for \(store.partnerDisplayName)…")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ink.opacity(0.55))
                Text("Answers open as a dialogue once you both write something.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.38))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            }
            .accessibilityIdentifier("connection.qotd.waiting")
        }
    }

    private var dialogue: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your dialogue")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.4))

            if let partner = store.partnerQuestionAnswer {
                dialogueBubble(
                    name: store.partnerDisplayName,
                    text: partner,
                    alignment: .leading,
                    isPartner: true,
                    accessibilityID: "connection.qotd.bubble.partner"
                )
            }

            if let me = store.meQuestionAnswer {
                dialogueBubble(
                    name: "You",
                    text: me,
                    alignment: .trailing,
                    isPartner: false,
                    accessibilityID: "connection.qotd.bubble.you"
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.qotd.dialogue")
    }

    private func dialogueBubble(
        name: String,
        text: String,
        alignment: HorizontalAlignment,
        isPartner: Bool,
        accessibilityID: String
    ) -> some View {
        HStack {
            if !isPartner { Spacer(minLength: 48) }
            VStack(alignment: alignment, spacing: 6) {
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.38))
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isPartner ? ink.opacity(0.9) : Color.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isPartner ? Color.white.opacity(0.88) : BeSideColor.navyStart)
                    }
            }
            .frame(maxWidth: 280, alignment: isPartner ? .leading : .trailing)
            if isPartner { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
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
        // Height is animated via the composer padding modifier — keep assignment plain
        // so FocusState isn’t delayed by a nested withAnimation.
        keyboardHeight = next
    }
}

#Preview {
    QuestionOfTheDayHub(store: MeSessionStore(), onClose: {})
}
