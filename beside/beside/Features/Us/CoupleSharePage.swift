import SwiftUI

/// Full-screen couple share — navy shell like Daily Task, light card for Stories.
struct CoupleSharePage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private let rose = Color(hex: 0xC48A9A)

    var body: some View {
        ZStack {
            BeSideColor.navyFill
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -100, y: -180)
                .allowsHitTesting(false)

            Circle()
                .fill(Color(hex: 0xFBCFE8).opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 120, y: 280)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 22) {
                        Text("Share your story")
                            .font(.system(size: 11, weight: .regular))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white.opacity(0.45))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)

                        sharePreviewCard
                            .padding(.horizontal, 28)

                        stylePicker
                            .padding(.horizontal, 28)

                        Text("Tap a look, then share to Instagram Stories")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 24)
                }

                softPinkButton(title: "Share to Instagram", showArrow: true) {
                    InstagramStoriesShare.shareCoupleStory(
                        meName: store.displayName,
                        partnerName: store.partnerDisplayName,
                        style: store.timeTogetherStyle,
                        relationshipStart: store.relationshipStartDate
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityIdentifier("us.couple.share.instagram")
            }
        }
        .hidesFloatingTabBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.couple.share")
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
                    .foregroundStyle(Color.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("us.couple.share.back")

                Spacer()
            }

            HStack(spacing: 8) {
                BesideLogoMark(size: 28)
                Text("beside")
                    .font(.system(size: 22, weight: .ultraLight))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var sharePreviewCard: some View {
        CoupleStoryShareCard(
            meName: store.displayName,
            partnerName: store.partnerDisplayName,
            style: store.timeTogetherStyle,
            relationshipStart: store.relationshipStartDate
        )
        .frame(maxWidth: .infinity)
        .scaleEffect(1.05)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.coupleHeroTitle). \(store.timeTogetherPhrase)")
        .animation(.easeInOut(duration: 0.2), value: store.timeTogetherStyle)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Look")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.4))

            HStack(spacing: 8) {
                ForEach(UsTimeTogether.Style.allCases, id: \.self) { style in
                    let selected = store.timeTogetherStyle == style
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.timeTogetherStyle = style
                        }
                    } label: {
                        Text(style.pickerLabel)
                            .font(.system(size: 13, weight: selected ? .medium : .light))
                            .foregroundStyle(selected ? ink.opacity(0.82) : Color.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        selected
                                            ? AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: 0xFFF7FB),
                                                        Color(hex: 0xFBCFE8),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            : AnyShapeStyle(Color.white.opacity(0.1))
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                selected
                                                    ? Color.white.opacity(0.2)
                                                    : Color.white.opacity(0.14),
                                                lineWidth: 1
                                            )
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .accessibilityIdentifier("us.couple.share.style")
    }

    private func softPinkButton(title: String, showArrow: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.4)
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .medium))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(ink.opacity(0.78))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFDF2F8), Color(hex: 0xFBCFE8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: 0xFBCFE8).opacity(0.35), radius: 10, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension UsTimeTogether.Style {
    var pickerLabel: String {
        switch self {
        case .detailed: return "Full"
        case .daysOnly: return "Days"
        case .sinceDate: return "Since"
        }
    }
}
