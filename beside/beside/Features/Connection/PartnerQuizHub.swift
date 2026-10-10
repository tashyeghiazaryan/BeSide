import SwiftUI

/// How well do you know your partner — how-to card, then guess seeded truths, then score.
struct PartnerQuizHub: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void

    @State private var showCustomCompose = false
    @State private var showPremiumTeaser = false
    @State private var customPrompt = ""
    @State private var customOptionA = ""
    @State private var customOptionB = ""
    @State private var customOptionC = ""
    @State private var customTruthID = "a"
    @FocusState private var composeFocused: Bool

    private var ink: Color { Color(hex: 0x1A1A2E) }

    private var canSaveCustomQuestion: Bool {
        let promptOK = !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let optionsOK = [customOptionA, customOptionB, customOptionC]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return promptOK && optionsOK
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                switch store.partnerQuizPhase {
                case .howToPlay:
                    howToPlayContent
                case .roleReveal:
                    roleRevealContent
                case .playing, .results:
                    ScrollView(.vertical, showsIndicators: false) {
                        Group {
                            switch store.partnerQuizPhase {
                            case .playing:
                                playingContent
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                            case .results:
                                resultsContent
                            case .howToPlay, .roleReveal:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, BeSideMetrics.tabBarClearance + 24)
                    }
                }
            }

            if showPremiumTeaser {
                premiumTeaserOverlay
                    .transition(.opacity)
                    .zIndex(20)
            }

            if showCustomCompose {
                customComposeOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: store.partnerQuizPhase)
        .animation(.easeOut(duration: 0.22), value: showCustomCompose)
        .animation(.easeOut(duration: 0.2), value: showPremiumTeaser)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.quiz.hub")
    }

    private var background: some View {
        ZStack {
            BeSideBackground.activityCanvas
                .ignoresSafeArea()
            BeSideBackground.activityAmbientBlobs()
        }
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
                .accessibilityIdentifier("connection.quiz.back")

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

    private var howToPlayContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 22) {
                Text("How to play")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.94))

                Text("4 questions. Secret roles. Unexpected truths.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ink.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("One answers honestly, the other guesses. Roles are on us!")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.52))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    rewardRow(
                        systemImage: "heart.fill",
                        tint: BeSideColor.raspberry.opacity(0.9),
                        text: "+20 for your truth"
                    )
                    rewardRow(
                        systemImage: "sparkles",
                        tint: BeSideColor.navyStart.opacity(0.85),
                        text: "+10 for every correct guess"
                    )
                }
                .padding(.top, 4)

                HStack(spacing: 8) {
                    Text("Play all 4. Win the day together!")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(ink.opacity(0.78))
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BeSideColor.loveNotePinkDeep)
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
            .background {
                RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .overlay {
                        RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("connection.quiz.howto")

            Spacer(minLength: 16)

            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                    store.startPartnerQuiz()
                }
            } label: {
                Text("Play")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        Capsule().fill(BeSideColor.navyStart)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, BeSideMetrics.tabBarClearance + 8)
            .accessibilityIdentifier("connection.quiz.play")
        }
    }

    private var roleRevealContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 20) {
                Text("Today’s roles")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .tracking(0.4)

                Text(roleHeadline)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.94))
                    .fixedSize(horizontal: false, vertical: true)

                Text(roleSubtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.52))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    rolePersonRow(
                        title: "You",
                        avatarName: store.displayName,
                        roleLabel: store.partnerQuizRole == .guessing ? "Guessing" : "Answering",
                        style: .you
                    )
                    rolePersonRow(
                        title: store.partnerDisplayName,
                        avatarName: store.partnerDisplayName,
                        roleLabel: store.partnerQuizRole == .guessing ? "Answering" : "Guessing",
                        style: .partner
                    )
                }
                .padding(.top, 6)

                writeCustomQuestionButton
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
            .background {
                RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .overlay {
                        RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("connection.quiz.role")

            Spacer(minLength: 16)

            Button {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                    store.beginPartnerQuizQuestions()
                }
            } label: {
                Text(roleCTATitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        Capsule().fill(BeSideColor.navyStart)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, BeSideMetrics.tabBarClearance + 8)
            .accessibilityIdentifier("connection.quiz.role.continue")
        }
    }

    private var writeCustomQuestionButton: some View {
        let hasCustom = store.customPartnerQuizQuestion != nil
        return Button {
            if store.isPremium {
                seedComposeFromExistingCustom()
                showCustomCompose = true
            } else {
                showPremiumTeaser = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BeSideColor.loveNotePinkBright.opacity(0.75),
                                    BeSideColor.loveNotePink.opacity(0.45),
                                    Color.white.opacity(0.55),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
                        }
                        .shadow(color: BeSideColor.loveNotePinkDeep.opacity(0.28), radius: 8, y: 3)

                    Image(systemName: hasCustom ? "checkmark" : "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.88))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        hasCustom
                            ? "Edit your question"
                            : "Write a question for \(store.partnerDisplayName)"
                    )
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.9))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                    Text(hasCustom ? "Saved · replaces one of today’s four" : "One personal slot in today’s quiz")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.42))
                }

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Premium")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.2)
                }
                .foregroundStyle(BeSideColor.navyStart.opacity(0.82))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    BeSideColor.loveNotePink.opacity(0.65),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            Capsule().stroke(Color.white.opacity(0.75), lineWidth: 0.8)
                        }
                        .shadow(color: BeSideColor.loveNotePinkDeep.opacity(0.18), radius: 4, y: 1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.28))
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                BeSideColor.loveNotePink.opacity(0.22),
                                Color.white.opacity(0.78),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        BeSideColor.loveNotePinkDeep.opacity(0.28),
                                        Color.white.opacity(0.55),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: BeSideColor.loveNotePinkDeep.opacity(0.14), radius: 14, y: 6)
                    .shadow(color: ink.opacity(0.04), radius: 6, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("connection.quiz.write-custom")
    }

    private var premiumTeaserOverlay: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { showPremiumTeaser = false }

            VStack(alignment: .leading, spacing: 16) {
                Text("Premium")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .tracking(0.6)
                Text("Write your own question")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.94))
                Text("Craft one personal question for \(store.partnerDisplayName). It replaces one of today’s four — no real billing in this demo.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    store.unlockDemoPremium()
                    showPremiumTeaser = false
                    seedComposeFromExistingCustom()
                    showCustomCompose = true
                } label: {
                    Text("Try Premium (demo)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background { Capsule().fill(BeSideColor.navyStart) }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("connection.quiz.premium.unlock")

                Button {
                    showPremiumTeaser = false
                } label: {
                    Text("Not now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .shadow(color: ink.opacity(0.12), radius: 24, y: 10)
            }
            .padding(.horizontal, 28)
            .accessibilityIdentifier("connection.quiz.premium.teaser")
        }
    }

    private var customComposeOverlay: some View {
        NavigationStack {
            ZStack {
                BeSideBackground.activityCanvas.ignoresSafeArea()
                BeSideBackground.activityAmbientBlobs()

                VStack(spacing: 0) {
                    HStack {
                        Button {
                            composeFocused = false
                            showCustomCompose = false
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 12, weight: .light))
                            }
                            .foregroundStyle(Color.black.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("connection.quiz.custom.back")

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Your question for \(store.partnerDisplayName)")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.94))

                            Text("This replaces one of today’s 4 questions.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.45))

                            composeField(
                                label: "Question",
                                placeholder: "Ask something only you two would know…",
                                text: $customPrompt,
                                axis: .vertical
                            )

                            Text("3 answer choices")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.4))
                                .padding(.top, 4)

                            composeOptionRow(id: "a", text: $customOptionA)
                            composeOptionRow(id: "b", text: $customOptionB)
                            composeOptionRow(id: "c", text: $customOptionC)

                            Text("Tap a choice to mark \(store.partnerDisplayName)’s truth (demo).")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.38))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    Button {
                        let saved = store.saveCustomPartnerQuizQuestion(
                            prompt: customPrompt,
                            optionTexts: [customOptionA, customOptionB, customOptionC],
                            truthOptionID: customTruthID
                        )
                        guard saved else { return }
                        composeFocused = false
                        showCustomCompose = false
                    } label: {
                        Text("Save question")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(canSaveCustomQuestion ? Color.white : Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                Capsule()
                                    .fill(
                                        canSaveCustomQuestion
                                            ? BeSideColor.navyStart
                                            : BeSideColor.navyStart.opacity(0.35)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSaveCustomQuestion)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .accessibilityIdentifier("connection.quiz.custom.save")
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .accessibilityIdentifier("connection.quiz.custom.compose")
    }

    private func composeField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.4))
            TextField(placeholder, text: text, axis: axis == .vertical ? .vertical : .horizontal)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(ink.opacity(0.9))
                .lineLimit(axis == .vertical ? 2...4 : 1...1)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        }
                }
                .focused($composeFocused)
        }
    }

    private func composeOptionRow(id: String, text: Binding<String>) -> some View {
        let selected = customTruthID == id
        return HStack(spacing: 12) {
            Button {
                customTruthID = id
            } label: {
                Circle()
                    .strokeBorder(
                        selected ? BeSideColor.navyStart : Color.black.opacity(0.18),
                        lineWidth: selected ? 6 : 1.5
                    )
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark as truth")
            .accessibilityIdentifier("connection.quiz.custom.truth.\(id)")

            TextField("Option \(id.uppercased())", text: text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(ink.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(selected ? 0.96 : 0.82))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selected ? BeSideColor.navyStart.opacity(0.3) : Color.black.opacity(0.05),
                                    lineWidth: 1
                                )
                        }
                }
                .focused($composeFocused)
        }
        .accessibilityIdentifier("connection.quiz.custom.option.\(id)")
    }

    private func seedComposeFromExistingCustom() {
        if let custom = store.customPartnerQuizQuestion {
            customPrompt = custom.prompt
            customOptionA = custom.option(id: "a")?.text ?? ""
            customOptionB = custom.option(id: "b")?.text ?? ""
            customOptionC = custom.option(id: "c")?.text ?? ""
            customTruthID = custom.partnerTruthOptionID
        } else {
            customPrompt = ""
            customOptionA = ""
            customOptionB = ""
            customOptionC = ""
            customTruthID = "a"
        }
    }

    private var roleHeadline: String {
        switch store.partnerQuizRole {
        case .guessing:
            return "You’re guessing today"
        case .answering:
            return "You’re answering today"
        }
    }

    private var roleSubtitle: String {
        switch store.partnerQuizRole {
        case .guessing:
            return "\(store.partnerDisplayName) already picked honest answers. Read their mind — one question at a time."
        case .answering:
            return "Pick your truths. \(store.partnerDisplayName) will try to guess them."
        }
    }

    private var roleCTATitle: String {
        switch store.partnerQuizRole {
        case .guessing:
            return "Start guessing"
        case .answering:
            return "Answer first question"
        }
    }

    private enum RoleAvatarStyle {
        case you
        case partner
    }

    private func rolePersonRow(
        title: String,
        avatarName: String,
        roleLabel: String,
        style: RoleAvatarStyle
    ) -> some View {
        let highlighted = style == .you
        return HStack(spacing: 12) {
            roleAvatar(name: avatarName, style: style)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.9))
                Text(roleLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(highlighted ? Color.white.opacity(0.95) : Color.white.opacity(0.55))
                .overlay {
                    if highlighted {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BeSideColor.navyStart.opacity(0.1), lineWidth: 1)
                    }
                }
        }
    }

    /// Compact avatar: You = soft navy wash; partner = dusty rose (Us hero language).
    @ViewBuilder
    private func roleAvatar(name: String, style: RoleAvatarStyle) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        switch style {
        case .you:
            Text(initial)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.95))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(BeSideColor.navyFill)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.45), lineWidth: 1)
                        }
                        .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 8, y: 3)
                }
                .accessibilityHidden(true)
        case .partner:
            let rose = Color(hex: 0xE8BEC9)
            let roseLight = Color(hex: 0xF3D6DE)
            let roseDeep = Color(hex: 0xD9A8B6)
            Text(initial)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(ink.opacity(0.72))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    roseLight.opacity(0.55),
                                    rose.opacity(0.42),
                                    roseDeep.opacity(0.38),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle().stroke(ink.opacity(0.1), lineWidth: 1)
                        }
                        .shadow(color: ink.opacity(0.08), radius: 5, y: 3)
                }
                .accessibilityHidden(true)
        }
    }

    private func rewardRow(systemImage: String, tint: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(tint.opacity(0.12))
                }
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(ink.opacity(0.88))
        }
    }

    @ViewBuilder
    private var playingContent: some View {
        if let question = store.currentPartnerQuizQuestion {
            VStack(alignment: .leading, spacing: 22) {
                Text(playingEyebrow)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.48))
                    .accessibilityIdentifier("connection.quiz.eyebrow")

                HStack(spacing: 10) {
                    Text("\(store.partnerQuizIndex + 1) / \(store.partnerQuizTotalCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(Color.black.opacity(0.4))
                        .accessibilityIdentifier("connection.quiz.progress")
                    if question.isCustom {
                        Text("Your question")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                Capsule().fill(BeSideColor.loveNotePink.opacity(0.55))
                            }
                            .accessibilityIdentifier("connection.quiz.custom.badge")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(question.prompt)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.94))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        }
                        .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
                }
                .accessibilityIdentifier("connection.quiz.question")

                VStack(spacing: 12) {
                    ForEach(question.options) { option in
                        optionButton(option)
                    }
                }

                Button {
                    _ = store.advancePartnerQuiz()
                } label: {
                    Text(store.partnerQuizIndex + 1 >= store.partnerQuizTotalCount ? "See results" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(store.canAdvancePartnerQuiz ? Color.white : Color.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            Capsule()
                                .fill(
                                    store.canAdvancePartnerQuiz
                                        ? BeSideColor.navyStart
                                        : BeSideColor.navyStart.opacity(0.35)
                                )
                        }
                }
                .buttonStyle(.plain)
                .disabled(!store.canAdvancePartnerQuiz)
                .padding(.top, 8)
                .accessibilityIdentifier("connection.quiz.continue")
            }
        }
    }

    private var playingEyebrow: String {
        switch store.partnerQuizRole {
        case .guessing:
            return "Guessing · \(store.partnerDisplayName)’s answers"
        case .answering:
            return "Your truths · \(store.partnerDisplayName) will guess"
        }
    }

    private func optionButton(_ option: PartnerQuizOption) -> some View {
        let selected = store.partnerQuizSelectedOptionID == option.id
        return Button {
            store.selectPartnerQuizOption(option.id)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(selected ? BeSideColor.navyStart : Color.black.opacity(0.18), lineWidth: selected ? 6 : 1.5)
                    .frame(width: 22, height: 22)
                Text(option.text)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(ink.opacity(0.92))
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.96) : Color.white.opacity(0.78))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                selected ? BeSideColor.navyStart.opacity(0.35) : Color.black.opacity(0.05),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("connection.quiz.option.\(option.id)")
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BeSideColor.loveNotePinkDeep)
                    .padding(12)
                    .background {
                        Circle().fill(BeSideColor.loveNotePink.opacity(0.45))
                    }

                Text(resultsCheerTitle)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(resultsCheerBody)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 6) {
                    Text("Your score")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.4))
                    Text("\(store.partnerQuizCorrectCount) / \(store.partnerQuizTotalCount)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(ink.opacity(0.94))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(store.partnerQuizCorrectCount) of \(store.partnerQuizTotalCount)")
                        .accessibilityIdentifier("connection.quiz.score")
                    Text(resultsScoreLine)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ink.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, 4)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.85))
                    Text("+\(store.partnerQuizPointsEarned) pts")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.9))
                    Text(resultsPointsHint)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.42))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(BeSideColor.navyStart.opacity(0.07))
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("connection.quiz.points")
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.78))
                    .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("connection.quiz.results")

            ForEach(store.partnerQuizQuestions) { question in
                resultRow(question)
            }

            Button {
                _ = store.claimPartnerQuizReward()
                onClose()
            } label: {
                Text("Claim & Reconnect")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        Capsule().fill(BeSideColor.navyStart)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .accessibilityIdentifier("connection.quiz.done")
        }
    }

    private var resultsCheerTitle: String {
        switch store.partnerQuizCorrectCount {
        case 0: return "A blank slate — that’s okay"
        case 1: return "One spark is a start"
        case 2: return "Halfway to knowing more"
        case 3: return "So close — beautiful"
        default: return "You two are in sync"
        }
    }

    private var resultsCheerBody: String {
        let name = store.partnerDisplayName
        switch store.partnerQuizCorrectCount {
        case 0:
            return "Zero hits just means there’s a whole \(name) still to discover. Showing up for the quiz already counts."
        case 1:
            return "One guess landed — a tiny window into \(name). Ask about the rest; curiosity is the win."
        case 2:
            return "Two right, two surprises. That’s a real relationship — keep noticing how \(name) moves through the day."
        case 3:
            return "Almost perfect. You clearly pay attention to \(name) — the last miss is just another story to share."
        default:
            return "Every guess landed. Keep noticing the little things about \(name)."
        }
    }

    private var resultsScoreLine: String {
        let name = store.partnerDisplayName
        switch store.partnerQuizCorrectCount {
        case 0: return "Fresh excuse to ask \(name) everything."
        case 1: return "One truth unlocked — more ahead."
        case 2: return "Even split — keep reading \(name)."
        case 3: return "Nearly a perfect read on \(name)."
        default: return "Perfect read on \(name)."
        }
    }

    private var resultsPointsHint: String {
        switch store.partnerQuizRole {
        case .guessing:
            return "from guesses"
        case .answering:
            return "for your truths"
        }
    }

    private func resultRow(_ question: PartnerQuizQuestion) -> some View {
        let guessID = store.partnerQuizGuesses[question.id]
        let truthID = question.partnerTruthOptionID
        let correct = guessID == truthID
        let guessText = guessID.flatMap { question.option(id: $0)?.text } ?? "—"
        let truthText = question.option(id: truthID)?.text ?? "—"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(correct ? Color(hex: 0x16A34A) : Color(hex: 0xFB7185))
                    .padding(.top, 2)
                Text(question.prompt)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Your guess: \(guessText)")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.5))
            Text("\(store.partnerDisplayName): \(truthText)")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.65))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("connection.quiz.result.\(question.id)")
    }
}

#Preview {
    PartnerQuizHub(store: MeSessionStore(), onClose: {})
}
