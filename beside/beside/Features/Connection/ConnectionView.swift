import SwiftUI

/// Connection tab — Figma Make `ConnectionScreen` carousel + Today's Activity hub.
struct ConnectionView: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore? = nil

    @State private var slides = ConnectionCarousel.demoSlides()
    @State private var carouselIndex = 0
    @State private var showTodaysActivity = false
    @State private var showQuestionOfTheDay = false
    @State private var showPartnerQuiz = false
    @State private var autoAdvanceToken = UUID()
    @State private var layout = BeSideMetrics.ConnectionLayout.standard

    private let autoAdvanceSeconds: TimeInterval = 8
    private let swipeThreshold: CGFloat = 48

    private var safeIndex: Int {
        guard !slides.isEmpty else { return 0 }
        return ((carouselIndex % slides.count) + slides.count) % slides.count
    }

    private var currentSlide: ConnectionCarouselSlide {
        slides[safeIndex]
    }

    private var isOverlayOpen: Bool {
        showTodaysActivity || showQuestionOfTheDay || showPartnerQuiz
    }

    private var activitySlide: ConnectionCarouselSlide {
        slides.first(where: \.isTodaysActivity) ?? currentSlide
    }

    var body: some View {
        ZStack {
            // Bound the carousel to the offered size so AsyncImage cannot inflate the root shell / tab bar.
            GeometryReader { geo in
                carouselLayer(size: geo.size, layout: layout)
            }

            if showTodaysActivity {
                TodaysActivityHub(
                    store: store,
                    userTask: activitySlide.userTask ?? ConnectionCarousel.defaultUserTask,
                    partnerTask: activitySlide.partnerTask ?? ConnectionCarousel.defaultPartnerTask,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showTodaysActivity = false
                        }
                        bumpAutoAdvance()
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }

            if showQuestionOfTheDay {
                QuestionOfTheDayHub(
                    store: store,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showQuestionOfTheDay = false
                        }
                        bumpAutoAdvance()
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }

            if showPartnerQuiz {
                PartnerQuizHub(
                    store: store,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showPartnerQuiz = false
                        }
                        bumpAutoAdvance()
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BeSideBackground.softCanvas.ignoresSafeArea())
        .animation(.easeOut(duration: 0.28), value: showTodaysActivity)
        .animation(.easeOut(duration: 0.28), value: showQuestionOfTheDay)
        .animation(.easeOut(duration: 0.28), value: showPartnerQuiz)
        .onAppear { bumpAutoAdvance() }
        .onChange(of: showTodaysActivity) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: showQuestionOfTheDay) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: showPartnerQuiz) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: autoAdvanceToken) { _, token in
            scheduleAutoAdvance(token: token)
        }
        // Same light floating tab bar as Me / Partner / Us / More.
        .prefersDarkFloatingTabBar(false)
        .onGeometryChange(for: BeSideMetrics.ConnectionLayout.self) { proxy in
            BeSideMetrics.ConnectionLayout.resolve(
                width: proxy.size.width,
                height: max(proxy.size.height, UIScreen.main.bounds.height),
                safeBottom: proxy.safeAreaInsets.bottom
            )
        } action: { newLayout in
            layout = newLayout
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.connection.screenIdentifier)
        .pairingRequiredGate(store: store, session: session)
    }

    private func carouselLayer(size: CGSize, layout: BeSideMetrics.ConnectionLayout) -> some View {
        let horizontalInset = layout.pageInset
        let topPad: CGFloat = 4
        let contentHeight = max(size.height - layout.tabBarClearance - topPad, 1)
        let mediaHeight = contentHeight * layout.mediaFraction
        let mediaWidth = size.width - horizontalInset * 2
        let mediaSize = CGSize(width: mediaWidth, height: mediaHeight)
        let corner = BeSideMetrics.glassCornerLarge

        return VStack(spacing: layout.gap) {
            ZStack {
                slideMedia(currentSlide, size: mediaSize)
                    .id(currentSlide.id)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.35), value: currentSlide.id)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.05),
                        Color(hex: 0xFCE7F3).opacity(0.28),
                        Color.white.opacity(0.72),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    if store.coupleSurfaceState == .pairedWaiting {
                        Text("Waiting for \(store.partnerDisplayName) to join today’s prompts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BeSideColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .beSideGlassChrome(cornerRadius: 20, style: .widgetFrosted)
                            .padding(.top, 14)
                            .padding(.horizontal, 16)
                            .accessibilityIdentifier("connection.waiting.banner")
                    }

                    Spacer(minLength: 0)

                    slideCopy(layout: layout)
                        .padding(.horizontal, 16)
                        .padding(.bottom, layout.mediaBottomPad)
                }

                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("connection.carousel")
                    .accessibilityLabel("Connection carousel")
                    .allowsHitTesting(false)
            }
            .frame(width: mediaWidth, height: mediaHeight)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
            .shadow(color: BeSideColor.loveNotePinkDeep.opacity(0.12), radius: 22, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 16)
                    .onEnded { value in
                        let dx = value.translation.width
                        if dx > swipeThreshold {
                            goPrev()
                        } else if dx < -swipeThreshold {
                            goNext()
                        }
                    }
            )
            .padding(.horizontal, horizontalInset)

            slideTileGrid(layout: layout)
                .padding(.horizontal, horizontalInset)

            startButton
                .padding(.horizontal, horizontalInset)

            Spacer(minLength: 0)
        }
        .padding(.top, topPad)
        .padding(.bottom, layout.tabBarClearance)
        .frame(width: size.width, height: size.height)
    }

    private func slideTileGrid(layout: BeSideMetrics.ConnectionLayout) -> some View {
        let spacing = layout.gridSpacing
        let tileHeight: CGFloat = layout.tileLabelSize <= 12 ? 54 : 58
        let rows: [[Int]] = [
            Array(0..<min(2, slides.count)),
            Array(2..<min(4, slides.count)),
        ].filter { !$0.isEmpty }

        return VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, columns in
                HStack(spacing: spacing) {
                    ForEach(columns, id: \.self) { index in
                        let slide = slides[index]
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                carouselIndex = index
                            }
                            bumpAutoAdvance()
                        } label: {
                            slideTile(slide, isActive: index == safeIndex, layout: layout)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: tileHeight)
                        .accessibilityLabel(tileTitle(for: slide))
                        .accessibilityIdentifier("connection.tile.\(slide.id)")
                        .accessibilityAddTraits(index == safeIndex ? .isSelected : AccessibilityTraits())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.28), value: safeIndex)
        .accessibilityIdentifier("connection.dots")
    }

    private func slideTile(
        _ slide: ConnectionCarouselSlide,
        isActive: Bool,
        layout: BeSideMetrics.ConnectionLayout
    ) -> some View {
        Text(tileTitle(for: slide))
            .font(.system(size: layout.tileLabelSize, weight: .semibold))
            .foregroundStyle(BeSideColor.navyStart.opacity(isActive ? 0.9 : 0.62))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
            .overlay {
                RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous)
                    .stroke(
                        isActive
                            ? BeSideColor.loveNotePinkDeep.opacity(0.75)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            }
            .scaleEffect(isActive ? 1.015 : 1)
            .opacity(isActive ? 1 : 0.88)
    }

    private func tileTitle(for slide: ConnectionCarouselSlide) -> String {
        if slide.isTodaysActivity { return "Today's Activity" }
        if slide.isQuestionOfTheDay { return "Question of the day" }
        if slide.isPartnerQuiz { return "How well do you know your partner" }
        if slide.id == "try-premium" { return "Premium" }
        return slide.title ?? "Connection"
    }

    private func slideCopy(layout: BeSideMetrics.ConnectionLayout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = currentSlide.title {
                Text(title)
                    .font(.system(size: layout.titleSize, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(BeSideColor.navyStart.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let body = currentSlide.body {
                Text(body)
                    .font(.system(size: layout.bodySize, weight: .regular))
                    .foregroundStyle(BeSideColor.navyStart.opacity(0.58))
                    .lineSpacing(3)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(layout.copyPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
        .accessibilityIdentifier("connection.slide.copy")
    }

    private var startButton: some View {
        Button {
            handleStart()
        } label: {
            Text(currentSlide.isTodaysActivity ? "Open your task for today!" : "Start")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BeSideColor.navyLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    Capsule().fill(BeSideColor.navyFill)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.18), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(startAccessibilityID)
    }

    private var startAccessibilityID: String {
        if currentSlide.isTodaysActivity { return "connection.cta.activity" }
        if currentSlide.isQuestionOfTheDay { return "connection.cta.qotd" }
        if currentSlide.isPartnerQuiz { return "connection.cta.quiz" }
        return "connection.cta.start"
    }

    @ViewBuilder
    private func slideMedia(_ slide: ConnectionCarouselSlide, size: CGSize) -> some View {
        Group {
            if let assetName = slide.imageAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
            } else if let urlString = slide.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        // Portrait seed stills (~9:16) — fill the phone edge-to-edge.
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                    case .failure:
                        mediaFallback
                    case .empty:
                        ZStack {
                            mediaFallback
                            ProgressView().tint(BeSideColor.navyStart.opacity(0.45))
                        }
                    @unknown default:
                        mediaFallback
                    }
                }
            } else {
                mediaFallback
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color(hex: 0xF7F4F8))
        .clipped()
    }

    private var mediaFallback: some View {
        LinearGradient(
            colors: [
                Color(hex: 0xFCE7F3),
                Color(hex: 0xF3EEF6),
                Color(hex: 0xEDE4F5),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Text("Add photos or video")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.35))
        }
    }

    private func handleStart() {
        if currentSlide.isTodaysActivity {
            withAnimation(.easeOut(duration: 0.28)) {
                showTodaysActivity = true
            }
            return
        }
        if currentSlide.isQuestionOfTheDay {
            withAnimation(.easeOut(duration: 0.28)) {
                showQuestionOfTheDay = true
            }
            return
        }
        if currentSlide.isPartnerQuiz {
            withAnimation(.easeOut(duration: 0.28)) {
                showPartnerQuiz = true
            }
        }
    }

    private func goNext() {
        guard slides.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            carouselIndex = (safeIndex + 1) % slides.count
        }
        bumpAutoAdvance()
    }

    private func goPrev() {
        guard slides.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            carouselIndex = (safeIndex - 1 + slides.count) % slides.count
        }
        bumpAutoAdvance()
    }

    private func bumpAutoAdvance() {
        autoAdvanceToken = UUID()
    }

    private func scheduleAutoAdvance(token: UUID) {
        guard !isOverlayOpen, slides.count > 1 else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoAdvanceSeconds * 1_000_000_000))
            guard token == autoAdvanceToken, !isOverlayOpen else { return }
            goNext()
        }
    }
}

#Preview("Connection · paired active") {
    ConnectionView(store: .previewPairedActive())
}

#Preview("Connection · paired waiting") {
    ConnectionView(store: .previewPairedWaiting())
}

#Preview("Connection · unpaired") {
    ConnectionView(store: .previewUnpaired())
}
