import SwiftUI

/// Past photos that were once on a partner’s Home Screen — replaces a separate Memories gallery.
struct ScreenPhotoArchivePage: View {
    let partnerName: String
    let onClose: () -> Void

    private var ink: Color { Color(hex: 0x26282B) }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

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
                    if demoItems.isEmpty {
                        emptyState
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(demoItems) { item in
                                archiveCell(item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    Color.clear.frame(height: 40)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.screen.archive.page")
    }

    /// Empty until send/replace lands; structure ready for a 2-column archive grid.
    private var demoItems: [ArchiveDemoItem] { [] }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ink.opacity(0.35))
            Text("No archived photos yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.62))
            Text("When you replace a photo on \(partnerName)’s screen, the previous one lands here — your screen history, not a separate album.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(ink.opacity(0.42))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.48))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
        }
        .environment(\.colorScheme, .light)
    }

    private func archiveCell(_ item: ArchiveDemoItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(item.wash)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
            Text(item.label)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(ink.opacity(0.45))
        }
        .accessibilityIdentifier("us.screen.archive.item.\(item.id)")
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
            .accessibilityIdentifier("us.screen.archive.back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Archive")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ink.opacity(0.88))
                Text("Earlier photos on \(partnerName)’s screen")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ArchiveDemoItem: Identifiable {
    let id: String
    let label: String
    let wash: LinearGradient
}
