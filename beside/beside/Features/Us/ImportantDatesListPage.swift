import SwiftUI

/// Full-screen Important Dates list — all events, add opens the calendar page.
struct ImportantDatesListPage: View {
    let dates: [UsImportantDate]
    let onClose: () -> Void
    var onAddDate: (() -> Void)? = nil
    var onWishlistIdeas: (() -> Void)? = nil
    var onDeleteDate: ((UsImportantDate) -> Void)? = nil

    @State private var openSwipeDateID: String?

    private var ink: Color { BeSideColor.navyStart }

    var body: some View {
        ZStack {
            background
            content
        }
        .hidesFloatingTabBar()
        .transition(.move(edge: .trailing))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.list.page")
    }

    private var background: some View {
        ZStack {
            BeSideBackground.widgetCanvas
                .ignoresSafeArea()
            BeSideBackground.widgetAmbientBlobs()
                .ignoresSafeArea()
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 10)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if dates.isEmpty {
                        emptyState
                    } else {
                        ForEach(dates) { item in
                            row(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .padding(.top, 4)
            }

            bottomActions
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .safeAreaPadding(.bottom, 8)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.65))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .accessibilityLabel("Back")
            .accessibilityIdentifier("us.dates.list.back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Important dates")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.88))
                Text("All your moments together")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onAddDate {
                Button(action: onAddDate) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .frame(width: 40, height: 40)
                        .background { Circle().fill(BeSideColor.navyFill) }
                        .shadow(color: ink.opacity(0.18), radius: 6, y: 2)
                }
                .accessibilityLabel("Add a date")
                .accessibilityIdentifier("us.dates.list.add")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No dates yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.78))
            Text("Tap + to add a shared day worth remembering.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(ink.opacity(0.42))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 16)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            if onWishlistIdeas != nil {
                Button {
                    onWishlistIdeas?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gift")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Wishlist ideas")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(ink.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.62))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(ink.opacity(0.12), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("us.dates.list.wishlist")
            }

            if let onAddDate {
                Button(action: onAddDate) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Add a date")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(BeSideColor.navyLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BeSideColor.navyFill)
                            .shadow(color: ink.opacity(0.22), radius: 10, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("us.dates.list.add.cta")
            }
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
            HStack(spacing: 10) {
                if let preset = item.iconPreset {
                    UsDateIconSphere(preset: preset, size: 36)
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.95))
                    }
                    .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ink.opacity(0.9))
                        .lineLimit(1)
                    if let note = item.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(ink.opacity(0.48))
                            .lineLimit(1)
                    }
                    Text(UsImportantDates.shortDate(item.date))
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(ink.opacity(0.42))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(UsImportantDates.countdownLabel(days))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(days <= 0 ? Color.white.opacity(0.95) : ink.opacity(0.46))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background {
                        if days <= 0 {
                            Capsule().fill(BeSideColor.navyFill)
                        } else {
                            Capsule()
                                .fill(Color.white.opacity(0.55))
                                .overlay {
                                    Capsule().stroke(ink.opacity(0.22), lineWidth: 1)
                                }
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    }
            }
        }
        .accessibilityIdentifier("us.dates.list.row.\(item.id)")
    }
}
