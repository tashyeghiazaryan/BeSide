import SwiftUI

/// Current Shared Moments photo for the home-screen widget + entry to archive.
struct ScreenPhotoPage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void
    var onPickPhoto: (() -> Void)? = nil

    @State private var showArchive = false

    private var ink: Color { Color(hex: 0x26282B) }
    private var partnerName: String { store.partnerDisplayName }

    var body: some View {
        ZStack {
            BeSideBackground.softCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        currentPreview
                        chooseButton
                        archiveEntry
                        widgetHelp
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }

            if showArchive {
                ScreenPhotoArchivePage(
                    partnerName: partnerName,
                    onClose: { showArchive = false }
                )
                .zIndex(10)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showArchive)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.screen.page")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .overlay {
                                Circle().stroke(ink.opacity(0.08), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("us.screen.back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Shared Moments")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ink.opacity(0.88))
                Text("Photos you share, ready for the home-screen widget")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private var currentPreview: some View {
        let photo = store.sharedMomentPhotoJPEG.flatMap { UIImage(data: $0) }

        return VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0xE8EEF8),
                                Color(hex: 0xF8F0F4),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(spacing: 6) {
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(ink.opacity(0.06))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.top, 14)
                    Spacer(minLength: 0)
                }

                Group {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: 0xE8BEC9).opacity(0.45),
                                        Color(hex: 0xC7D2FE).opacity(0.4),
                                        Color.white.opacity(0.55),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundStyle(ink.opacity(0.35))
                                    Text("Nothing here yet")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(ink.opacity(0.55))
                                    Text("Take a photo or pick one from your library")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundStyle(ink.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                }
                            }
                    }
                }
                .frame(maxWidth: 220)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.12), radius: 12, y: 6)
                .offset(y: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityIdentifier("us.screen.preview")
        }
    }

    private var chooseButton: some View {
        Button {
            onPickPhoto?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(store.sharedMomentPhotoJPEG == nil ? "Add a photo" : "Replace photo")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                Capsule().fill(BeSideColor.navyStart)
            }
        }
        .buttonStyle(.plain)
        .disabled(onPickPhoto == nil)
        .opacity(onPickPhoto == nil ? 0.55 : 1)
        .accessibilityIdentifier("us.screen.choose")
    }

    private var archiveEntry: some View {
        Button {
            showArchive = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archive")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ink.opacity(0.82))
                    Text("Past Shared Moments")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(ink.opacity(0.45))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.28))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.5))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                    }
            }
            .environment(\.colorScheme, .light)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("us.screen.archive")
    }

    private var widgetHelp: some View {
        Text("On your iPhone: long-press Home Screen → + → BeSide → add the Shared Moments widget.")
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(ink.opacity(0.4))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("us.screen.widget.help")
    }
}
