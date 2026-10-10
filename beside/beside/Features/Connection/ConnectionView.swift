import SwiftUI

/// Connection tab — Figma Make `ConnectionScreen` carousel + Today's Activity hub.
struct ConnectionView: View {
    @Bindable var store: MeSessionStore

    @State private var slides = ConnectionCarousel.demoSlides()
    @State private var carouselIndex = 0
    @State private var showTodaysActivity = false
    @State private var showQuestionOfTheDay = false
    @State private var showPartnerQuiz = false
    @State private var showSections = false
    @State private var autoAdvanceToken = UUID()

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
        showTodaysActivity || showQuestionOfTheDay || showPartnerQuiz || showSections
    }

    private var activitySlide: ConnectionCarouselSlide {
        slides.first(where: \.isTodaysActivity) ?? currentSlide
    }

    var body: some View {
        ZStack {
            // Bound the carousel to the offered size so AsyncImage cannot inflate the root shell / tab bar.
            GeometryReader { geo in
                carouselLayer(size: geo.size)
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

            if showSections {
                ConnectionSectionsPage(
                    slides: slides,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.28)) {
                            showSections = false
                        }
                        bumpAutoAdvance()
                    },
                    onOpen: openSection
                )
                .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
        .animation(.easeOut(duration: 0.28), value: showTodaysActivity)
        .animation(.easeOut(duration: 0.28), value: showQuestionOfTheDay)
        .animation(.easeOut(duration: 0.28), value: showPartnerQuiz)
        .animation(.easeOut(duration: 0.28), value: showSections)
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
        .onChange(of: showSections) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: autoAdvanceToken) { _, token in
            scheduleAutoAdvance(token: token)
        }
        // Dark tab chrome only over the carousel; light bar inside hubs / Sections.
        .prefersDarkFloatingTabBar(!isOverlayOpen)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.connection.screenIdentifier)
    }

    private func carouselLayer(size: CGSize) -> some View {
        ZStack {
            slideMedia(currentSlide, size: size)
                .id(currentSlide.id)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.35), value: currentSlide.id)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.5),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Top chrome — pill centered, sections badge trailing
            VStack(spacing: 0) {
                ZStack {
                    connectionPill
                    HStack {
                        Spacer(minLength: 0)
                        sectionsBadge
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)

                if slides.count > 1 {
                    HStack {
                        Spacer(minLength: 0)
                        pageDots
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 10)
                }

                Spacer(minLength: 0)
            }

            // Copy — upper third, left-aligned (Figma top overlay ~5.5rem from safe top)
            VStack(spacing: 0) {
                slideCopy
                    .padding(.horizontal, 16)
                    .padding(.top, 88)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)

            // CTA — vertically centered (Figma `inset-0 flex items-center justify-center`)
            startButton

            // Dedicated AX marker — avoid putting the carousel id on the drag container
            // (that overwrites child identifiers like pill / sections / CTA).
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("connection.carousel")
                .accessibilityLabel("Connection carousel")
                .allowsHitTesting(false)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .contentShape(Rectangle())
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
    }

    private var connectionPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BeSideColor.tabActiveOnDark.opacity(0.85))
            Text("Connection")
                .font(.system(size: 10, weight: .light))
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(BeSideColor.tabActiveOnDark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .beSideGlassChrome(cornerRadius: 20, style: .dark)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("connection.pill")
    }

    private var sectionsBadge: some View {
        Button {
            withAnimation(.easeOut(duration: 0.28)) {
                showSections = true
            }
        } label: {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BeSideColor.tabActiveOnDark)
                .frame(width: 40, height: 40)
                .beSideGlassChrome(cornerRadius: 20, style: .dark)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Connection sections")
        .accessibilityIdentifier("connection.sections")
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(slides.enumerated()), id: \.element.id) { index, _ in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        carouselIndex = index
                    }
                    bumpAutoAdvance()
                } label: {
                    Capsule()
                        .fill(index == safeIndex ? Color.white : Color.white.opacity(0.35))
                        .frame(width: index == safeIndex ? 20 : 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Slide \(index + 1)")
            }
        }
        .accessibilityIdentifier("connection.dots")
    }

    private var slideCopy: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = currentSlide.title {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let body = currentSlide.body {
                Text(body)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineSpacing(3)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 360, alignment: .leading)
        .accessibilityIdentifier("connection.slide.copy")
    }

    private var startButton: some View {
        Button {
            handleStart()
        } label: {
            Text(currentSlide.isTodaysActivity ? "Open your task for today!" : "Start")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BeSideColor.tabActive)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .beSideGlassChrome(cornerRadius: BeSideMetrics.tabBarCorner, style: .solidOnDark)
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
                            ProgressView().tint(.white.opacity(0.7))
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
        .background(Color(hex: 0x0A0A0A))
        .clipped()
    }

    private var mediaFallback: some View {
        LinearGradient(
            colors: [Color(hex: 0x262626), Color(hex: 0x0A0A0A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Text("Add photos or video")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.white.opacity(0.35))
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

    private func openSection(_ slide: ConnectionCarouselSlide) {
        if let index = slides.firstIndex(where: { $0.id == slide.id }) {
            carouselIndex = index
        }

        withAnimation(.easeOut(duration: 0.28)) {
            showSections = false
            showTodaysActivity = slide.isTodaysActivity
            showQuestionOfTheDay = slide.isQuestionOfTheDay
            showPartnerQuiz = slide.isPartnerQuiz
        }
        if !slide.isTodaysActivity && !slide.isQuestionOfTheDay && !slide.isPartnerQuiz {
            bumpAutoAdvance()
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

#Preview {
    ConnectionView(store: MeSessionStore())
}
