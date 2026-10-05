import SwiftUI

/// Notifications feed — Figma Make `NotificationsScreen`.
struct NotificationsPage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void
    var onOpen: ((UsNotification) -> Void)? = nil

    @State private var openSwipeID: String?

    private var ink: Color { Color(hex: 0x1A1A2E) }

    var body: some View {
        ZStack {
            Color(hex: 0xF2EDE4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
        .transition(.move(edge: .trailing))
        .accessibilityIdentifier("us.notifications.page")
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
            .accessibilityIdentifier("us.notifications.back")

            Text("Notifications")
                .font(.system(size: 17, weight: .light))
                .tracking(0.4)
                .foregroundStyle(ink.opacity(0.75))
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
        .padding(.top, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.notifications.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(store.notifications) { item in
                        notificationRow(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, BeSideMetrics.tabBarClearance + 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 48)
            Image(systemName: "bell")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ink.opacity(0.25))
                .frame(width: 56, height: 56)
                .background {
                    Circle().fill(Color.black.opacity(0.04))
                }
            Text("No notifications yet")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(ink.opacity(0.45))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .accessibilityIdentifier("us.notifications.empty")
    }

    private func notificationRow(_ item: UsNotification) -> some View {
        SwipeToDeleteRow(
            isOpen: Binding(
                get: { openSwipeID == item.id },
                set: { open in
                    if open {
                        openSwipeID = item.id
                    } else if openSwipeID == item.id {
                        openSwipeID = nil
                    }
                }
            ),
            onDelete: {
                openSwipeID = nil
                withAnimation(.easeOut(duration: 0.2)) {
                    store.deleteNotification(id: item.id)
                }
            },
            deleteAccessibilityLabel: "Delete notification",
            deleteAccessibilityIdentifier: "us.notifications.delete"
        ) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 14, weight: item.read ? .regular : .semibold))
                        .foregroundStyle(ink.opacity(0.82))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.timeLabel)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(ink.opacity(0.35))
                }

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(ink.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                item.read
                                    ? Color.black.opacity(0.06)
                                    : Color(hex: 0xFBBF24).opacity(0.35),
                                lineWidth: item.read ? 1 : 1.2
                            )
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.markNotificationRead(id: item.id)
                onOpen?(item)
            }
        }
        .accessibilityIdentifier("us.notifications.row.\(item.id)")
    }
}
