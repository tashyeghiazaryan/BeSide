import SwiftUI

/// Connection tab — Figma Make `ConnectionScreen` carousel + Today's Activity hub.
struct ConnectionView: View {
    @Bindable var store: MeSessionStore

    @State private var slides = ConnectionCarousel.demoSlides()
    @State private var carouselIndex = 0
    @State private var showTodaysActivity = false
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
        showTodaysActivity || showSections
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
        .animation(.easeOut(duration: 0.28), value: showSections)
        .onAppear { bumpAutoAdvance() }
        .onChange(of: showTodaysActivity) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: showSections) { _, open in
            if !open { bumpAutoAdvance() }
        }
        .onChange(of: autoAdvanceToken) { _, token in
            scheduleAutoAdvance(token: token)
        }
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
        .accessibilityIdentifier("connection.carousel")
    }

    private var connectionPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.75))
            Text("Connection")
                .font(.system(size: 10, weight: .light))
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
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
                .foregroundStyle(Color.white.opacity(0.9))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                }
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
        VStack(alignment: .leading, spacing: 10) {
            if let title = currentSlide.title {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 1)
            }
            if let body = currentSlide.body {
                Text(body)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 336, alignment: .leading)
        .accessibilityIdentifier("connection.slide.copy")
    }

    private var startButton: some View {
        Button {
            handleStart()
        } label: {
            Text(currentSlide.isTodaysActivity ? "Open your task for today!" : "Start")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: 0x171717))
                .padding(.horizontal, 28)
                .padding(.vertical, 11)
                .background {
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.35), radius: 16, y: 4)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            currentSlide.isTodaysActivity ? "connection.cta.activity" : "connection.cta.start"
        )
    }

    @ViewBuilder
    private func slideMedia(_ slide: ConnectionCarouselSlide, size: CGSize) -> some View {
        Group {
            if let urlString = slide.imageURL, let url = URL(string: urlString) {
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
        guard currentSlide.isTodaysActivity else { return }
        withAnimation(.easeOut(duration: 0.28)) {
            showTodaysActivity = true
        }
    }

    private func openSection(_ slide: ConnectionCarouselSlide) {
        if let index = slides.firstIndex(where: { $0.id == slide.id }) {
            carouselIndex = index
        }

        withAnimation(.easeOut(duration: 0.28)) {
            showSections = false
            // Today's Activity has a dedicated hub; other sections land on their carousel slide.
            showTodaysActivity = slide.isTodaysActivity
        }
        if !slide.isTodaysActivity {
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
