import SwiftUI

/// Important Dates full list — Figma Make UsScreen list modal.
struct ImportantDatesListModal: View {
    let dates: [UsImportantDate]
    let onClose: () -> Void
    /// Opens Wishlist (partner tab in Figma Make).
    var onWishlistIdeas: (() -> Void)? = nil
    var onAddDate: (() -> Void)? = nil
    var onDeleteDate: ((UsImportantDate) -> Void)? = nil

    @State private var openSwipeDateID: String?

    private var navy: Color { BeSideColor.navyStart }
    private var inkRGB: Color { Color(hex: 0x1A1A2E) }

    var body: some View {
        ZStack {
            scrim
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.list.modal")
    }

    private var scrim: some View {
        ZStack {
            Color(hex: 0x1A1A2E).opacity(0.28)
            RadialGradient(
                colors: [Color(hex: 0xFBCFE8).opacity(0.22), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
            RadialGradient(
                colors: [Color(hex: 0xC4B5FD).opacity(0.18), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
        .background(.ultraThinMaterial.opacity(0.35))
    }

    private var card: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xE8BED3), Color(hex: 0xD7C8E2), Color(hex: 0xC9D6EE), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)

            VStack(spacing: 0) {
                Text("Important dates")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(inkRGB)
                    .frame(maxWidth: .infinity)
                Text("All your moments together")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(inkRGB.opacity(0.45))
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                if dates.isEmpty {
                    Text("No dates yet — tap + on the card to add one.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(inkRGB.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 32)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(dates) { item in
                                row(item)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .frame(maxHeight: 360)
                }

                VStack(spacing: 8) {
                    Button {
                        onWishlistIdeas?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gift")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(inkRGB.opacity(0.55))
                            Text("Wishlist ideas")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(inkRGB.opacity(0.72))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.55))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(inkRGB.opacity(0.12), lineWidth: 1)
                                }
                                .shadow(color: inkRGB.opacity(0.06), radius: 8, y: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("us.dates.list.wishlist")

                    Button {
                        onAddDate?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add a date")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(BeSideColor.navyLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(BeSideColor.navyFill)
                                .shadow(color: navy.opacity(0.22), radius: 10, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("us.dates.list.add")
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 360)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.92), Color.white.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                }
                .shadow(color: navy.opacity(0.18), radius: 28, y: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(inkRGB.opacity(0.55))
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .overlay { Circle().stroke(inkRGB.opacity(0.12), lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)
            .padding(14)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("us.dates.list.close")
        }
    }

    private func row(_ item: UsImportantDate) -> some View {
        let days = UsImportantDates.daysUntil(item.date)
        return SwipeToDeleteRow(
            isOpen: Binding(
                get: { openSwipeDateID == item.id },
                set: { open in
                    if open {
                        openSwipeDateID = item.id
                    } else if openSwipeDateID == item.id {
                        openSwipeDateID = nil
                    }
                }
            ),
            onDelete: {
                openSwipeDateID = nil
                onDeleteDate?(item)
            },
            deleteAccessibilityLabel: "Delete date",
            deleteAccessibilityIdentifier: "us.dates.list.delete"
        ) {
            HStack(spacing: 8) {
                if let preset = item.iconPreset {
                    UsDateIconSphere(preset: preset, size: 32)
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [item.accentColor.opacity(0.55), item.accentColor.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay { Circle().stroke(Color.white.opacity(0.65), lineWidth: 1) }
                        Image(systemName: item.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.95))
                    }
                    .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(inkRGB)
                        .lineLimit(1)
                    Text(UsImportantDates.shortDate(item.date))
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(inkRGB.opacity(0.42))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(UsImportantDates.countdownLabel(days))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BeSideColor.navyLabel)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(BeSideColor.navyFill)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.82), Color.white.opacity(0.58)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: 0x2D2D44).opacity(0.1), lineWidth: 1)
                    }
            }
        }
        .accessibilityIdentifier("us.dates.list.row.\(item.id)")
    }
}
