import SwiftUI

/// Index of Connection carousel sections — large horizontal photo cards stacked to fit three on screen.
struct ConnectionSectionsPage: View {
    let slides: [ConnectionCarouselSlide]
    let onClose: () -> Void
    let onOpen: (ConnectionCarouselSlide) -> Void

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private let cardSpacing: CGFloat = 12
    private let horizontalInset: CGFloat = 16
    private let stackTopPad: CGFloat = 12

    var body: some View {
        ZStack {
            BeSideBackground.activityCanvas
                .ignoresSafeArea()
            BeSideBackground.activityAmbientBlobs()

            VStack(spacing: 0) {
                header
                cardsStack
            }
        }
        .transition(.move(edge: .trailing))
        .accessibilityIdentifier("connection.sections.page")
    }

    private var header: some View {
        HStack(spacing: 4) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ink.opacity(0.55))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("connection.sections.back")

            Text("Sections")
                .font(.system(size: 17, weight: .light))
                .tracking(0.4)
                .foregroundStyle(ink.opacity(0.75))
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .padding(.top, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var cardsStack: some View {
        GeometryReader { geo in
            let bottomPad = BeSideMetrics.tabBarClearance + 8
            let usableHeight = max(geo.size.height - stackTopPad - bottomPad, 0)
            let count = max(slides.count, 1)
            let evenly = (usableHeight - cardSpacing * CGFloat(count - 1)) / CGFloat(count)
            // Prefer fitting all cards on screen; allow a shorter floor when there are four+ sections.
            let cardHeight = max(evenly, count > 3 ? 110 : 132)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: cardSpacing) {
                    ForEach(slides) { slide in
                        sectionCard(slide, height: cardHeight)
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.top, stackTopPad)
                .padding(.bottom, bottomPad)
                .frame(minHeight: usableHeight + stackTopPad + bottomPad, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func sectionCard(_ slide: ConnectionCarouselSlide, height: CGFloat) -> some View {
        ZStack {
            // Full-bleed photo, clipped to the card bounds.
            previewImage(slide)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // Darken right side for readable copy.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.55),
                    Color(hex: 0x0A0A12).opacity(0.92),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text(slide.title ?? "Section")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let body = slide.body {
                        Text(body)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.82))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 4)

                    Button {
                        onOpen(slide)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Open")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(BeSideColor.tabActive)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .beSideGlassChrome(cornerRadius: BeSideMetrics.tabBarItemCorner, style: .solidOnDark)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(slide.title ?? "section")")
                    .accessibilityIdentifier("connection.sections.open.\(slide.id)")
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: ink.opacity(0.12), radius: 14, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture { onOpen(slide) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.sections.row.\(slide.id)")
        // Named so UITests can find the row even when child Open buttons own the focus.
        .accessibilityLabel(slide.title ?? "Section")
    }

    @ViewBuilder
    private func previewImage(_ slide: ConnectionCarouselSlide) -> some View {
        Group {
            if let assetName = slide.imageAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = slide.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        previewFallback
                    case .empty:
                        ZStack {
                            previewFallback
                            ProgressView().tint(.white.opacity(0.65))
                        }
                    @unknown default:
                        previewFallback
                    }
                }
            } else {
                previewFallback
            }
        }
        // Force the image into the offered size so scaledToFill cannot inflate the card.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
    }

    private var previewFallback: some View {
        LinearGradient(
            colors: [Color(hex: 0x3A3A4A), Color(hex: 0x1A1A2E)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    ConnectionSectionsPage(
        slides: ConnectionCarousel.demoSlides(),
        onClose: {},
        onOpen: { _ in }
    )
}
