import SwiftUI

/// Today's Activity hub — Figma Make `TodaysActivityScreen`.
struct TodaysActivityHub: View {
    @Bindable var store: MeSessionStore
    let userTask: String
    let partnerTask: String
    let onClose: () -> Void

    @State private var showDailyTaskDetail = false
    @State private var celebrateTogether = false
    @State private var celebrationBurst = false
    @State private var celebrationLoopID = UUID()

    private let celebrationRepeatSeconds: TimeInterval = 5
    private let celebrationBurstSeconds: TimeInterval = 2.4

    private var ink: Color { Color(hex: 0x1A1A2E) }

    private var hasPendingApprovals: Bool {
        !store.connectionPendingAnswers.isEmpty
    }

    private var bothCompletedToday: Bool {
        store.meActivityDoneToday && store.partnerActivityDoneToday
    }

    var body: some View {
        GeometryReader { geo in
            // Past mid-screen with breathing room below — not a stretched full-height slab.
            let dailyCardHeight = max(
                geo.size.height * (hasPendingApprovals && !bothCompletedToday ? 0.38 : 0.56),
                hasPendingApprovals && !bothCompletedToday ? 240 : 320
            )

            ZStack {
                background
                VStack(spacing: 0) {
                    header
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 18) {
                            if store.connectionDailyPhase == .waiting {
                                sectionEyebrow
                            }
                            dailyTaskCard(height: dailyCardHeight)
                            if hasPendingApprovals {
                                awaitingApprovalCard
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, BeSideMetrics.tabBarClearance + 28)
                    }
                }

                if showDailyTaskDetail {
                    DailyTaskDetailPage(
                        userTask: userTask,
                        onBack: {
                            withAnimation(.easeOut(duration: 0.28)) {
                                showDailyTaskDetail = false
                            }
                        },
                        onMarkDone: {
                            store.markDailyActivityDone()
                            withAnimation(.easeOut(duration: 0.28)) {
                                showDailyTaskDetail = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(20)
                }
            }
        }
        .animation(.easeOut(duration: 0.28), value: showDailyTaskDetail)
        .animation(.easeOut(duration: 0.28), value: hasPendingApprovals)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: bothCompletedToday)
        .onChange(of: bothCompletedToday) { _, both in
            if both {
                startCelebrationLoop()
            } else {
                stopCelebrationLoop()
            }
        }
        .onAppear {
            if bothCompletedToday {
                startCelebrationLoop()
            }
        }
        .onDisappear {
            stopCelebrationLoop()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.hub")
    }

    private func startCelebrationLoop() {
        celebrateTogether = true
        let loopID = UUID()
        celebrationLoopID = loopID
        Task { @MainActor in
            while !Task.isCancelled, celebrationLoopID == loopID, bothCompletedToday {
                playCelebrationBurst()
                try? await Task.sleep(nanoseconds: UInt64(celebrationRepeatSeconds * 1_000_000_000))
            }
        }
    }

    private func stopCelebrationLoop() {
        celebrationLoopID = UUID()
        celebrateTogether = false
        withAnimation(.easeOut(duration: 0.35)) {
            celebrationBurst = false
        }
    }

    private func playCelebrationBurst() {
        celebrationBurst = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            celebrationBurst = true
        }
        let loopID = celebrationLoopID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(celebrationBurstSeconds * 1_000_000_000))
            guard celebrationLoopID == loopID else { return }
            withAnimation(.easeOut(duration: 0.45)) {
                celebrationBurst = false
            }
        }
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
                .accessibilityIdentifier("connection.activity.back")

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

    private var sectionEyebrow: some View {
        Text(bothCompletedToday ? "Together today" : "One step closer together")
            .font(.system(size: 11, weight: .regular))
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(Color.black.opacity(0.32))
            .frame(maxWidth: .infinity)
    }

    private func dailyTaskCard(height: CGFloat) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Daily Task")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.bottom, 14)

                Group {
                    switch store.connectionDailyPhase {
                    case .closed, .open:
                        // `.open` is unused for in-card UI — task detail is its own page.
                        closedPhase
                    case .waiting:
                        if bothCompletedToday {
                            togetherPhase
                        } else {
                            waitingPhase
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 20)

            if celebrationBurst {
                DailyTaskTogetherBurst()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BeSideColor.navyFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            bothCompletedToday
                                ? Color(hex: 0xFBCFE8).opacity(0.35)
                                : Color.white.opacity(0.1),
                            lineWidth: bothCompletedToday ? 1.5 : 1
                        )
                }
                .shadow(
                    color: bothCompletedToday
                        ? Color(hex: 0xFBCFE8).opacity(0.28)
                        : BeSideColor.navyStart.opacity(0.22),
                    radius: bothCompletedToday ? 28 : 24,
                    y: 10
                )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.daily")
    }

    private var closedPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ConnectionCarousel.closedHint)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300, alignment: .leading)

            Spacer(minLength: 16)

            DailyTaskPhonesIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 132)

            Spacer(minLength: 28)

            softPinkButton(title: "Open your daily task", showArrow: true) {
                withAnimation(.easeOut(duration: 0.28)) {
                    showDailyTaskDetail = true
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("connection.activity.open")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var waitingPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "heart.fill")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color(hex: 0xFB7185))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFDF2F8), Color(hex: 0xFBCFE8).opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 14)

            Text("Waiting for partner")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))
                .padding(.bottom, 8)

            Text(ConnectionCarousel.pendingMessage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 24)

            progressChipsRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.waiting")
    }

    private var togetherPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xFBCFE8).opacity(0.22))
                    .frame(width: 64, height: 64)
                    .scaleEffect(celebrateTogether ? 1.12 : 0.92)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: celebrateTogether
                    )

                Image(systemName: "heart.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color(hex: 0xFB7185))
                    .scaleEffect(celebrateTogether ? 1.08 : 0.96)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: celebrateTogether
                    )
            }
            .frame(width: 64, height: 64)
            .padding(.bottom, 16)

            Text(ConnectionCarousel.togetherTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.98))
                .padding(.bottom, 10)

            Text(ConnectionCarousel.togetherMessage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 24)

            Text(ConnectionCarousel.tomorrowHint)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
                .accessibilityIdentifier("connection.activity.tomorrow")

            progressChipsRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.together")
    }

    private var progressChipsRow: some View {
        HStack(spacing: 10) {
            progressChip(
                title: "You",
                done: store.meActivityDoneToday,
                accessibilityID: "connection.activity.chip.you"
            )
            progressChip(
                title: "Partner",
                done: store.partnerActivityDoneToday,
                accessibilityID: "connection.activity.chip.partner"
            )
        }
    }

    private func progressChip(title: String, done: Bool, accessibilityID: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(done ? Color(hex: 0xFB7185) : Color.white.opacity(0.18))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(done ? 0.9 : 0.45))
            Spacer(minLength: 0)
            Text(done ? "Done" : "Waiting")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(done ? "Done" : "Waiting")")
        .accessibilityIdentifier(accessibilityID)
    }

    private var awaitingApprovalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Awaiting your approval")
                    .font(.system(size: 10, weight: .regular))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.black.opacity(0.3))
                Spacer()
                if !store.connectionPendingAnswers.isEmpty {
                    Text("\(store.connectionPendingAnswers.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: 0xFB7185))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().fill(Color(hex: 0xFB7185).opacity(0.12))
                        }
                }
            }

            Text("Tasks your partner finished today. Count them when they feel right — or gently pass for now.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(hex: 0x86868B))

            if store.connectionPendingAnswers.isEmpty {
                Text("No partner tasks waiting yet.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: 0x86868B))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.03))
                    }
                    .accessibilityIdentifier("connection.activity.pending.empty")
            } else {
                ForEach(store.connectionPendingAnswers) { answer in
                    pendingAnswerRow(answer)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                }
                .shadow(color: Color(hex: 0x504670).opacity(0.08), radius: 20, y: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.pending")
    }

    private func pendingAnswerRow(_ answer: ConnectionPendingAnswer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(answer.partnerName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: 0x1D1D1F))
                Spacer()
                Text(answer.submittedAt)
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color(hex: 0x86868B))
            }

            Text("Partner’s task")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.28))

            Text(answer.task)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(hex: 0x6E6E73))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        _ = store.declinePendingAnswer(id: answer.id)
                    }
                } label: {
                    Text("Not this time")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(0.2)
                        .foregroundStyle(ink.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .overlay {
                                    Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Not this time")
                .accessibilityIdentifier("connection.activity.decline.\(answer.id)")

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        _ = store.approvePendingAnswer(id: answer.id)
                    }
                } label: {
                    Text("Count it")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(0.2)
                        .foregroundStyle(BeSideColor.navyLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            Capsule()
                                .fill(BeSideColor.navyFill)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Count it")
                .accessibilityIdentifier("connection.activity.approve.\(answer.id)")
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                }
        }
    }

    private func softPinkButton(title: String, showArrow: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(0.2)
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .opacity(0.55)
                }
            }
            .foregroundStyle(ink.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF7FB), Color(hex: 0xFBCFE8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: 0xFBCFE8).opacity(0.45), radius: 14, y: 4)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Soft pink hearts + sparkles that burst when both partners finish today's task.
private struct DailyTaskTogetherBurst: View {
    private let pieces: [(symbol: String, x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        ("heart.fill", -0.28, -0.18, 14, 0.00),
        ("sparkle", 0.30, -0.22, 12, 0.05),
        ("heart.fill", 0.22, 0.12, 11, 0.08),
        ("sparkle", -0.32, 0.16, 10, 0.10),
        ("heart.fill", 0.05, -0.32, 13, 0.04),
        ("sparkle", -0.08, 0.30, 11, 0.12),
        ("heart.fill", 0.34, -0.02, 10, 0.07),
        ("sparkle", -0.18, -0.30, 9, 0.09),
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width * 0.5
            let cy = geo.size.height * 0.38
            ZStack {
                ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                    Image(systemName: piece.symbol)
                        .font(.system(size: piece.size, weight: .medium))
                        .foregroundStyle(
                            piece.symbol == "heart.fill"
                                ? Color(hex: 0xFB7185).opacity(0.9)
                                : Color(hex: 0xF9A8D4).opacity(0.85)
                        )
                        .position(
                            x: cx + piece.x * geo.size.width,
                            y: cy + piece.y * geo.size.height
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.2)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(piece.delay)),
                                removal: .opacity
                            )
                        )
                }
            }
        }
        .accessibilityHidden(true)
    }
}
