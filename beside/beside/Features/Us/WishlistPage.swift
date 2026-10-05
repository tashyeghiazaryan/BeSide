import PhotosUI
import SwiftUI
import UIKit

/// Wishlist full page — Figma Make UsScreen wishlist overlay.
struct WishlistPage: View {
    @Bindable var store: MeSessionStore
    var initialTab: Tab = .mine
    let onClose: () -> Void

    @State private var tab: Tab = .mine
    @State private var showHistory = false
    @State private var showAddWish = false
    @State private var doneArmedIndex: Int?

    enum Tab: Hashable {
        case mine
        case partner
    }

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private var partnerName: String { store.partnerDisplayName }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                if showHistory {
                    historyList
                } else {
                    mainContent
                }
            }
            .padding(.bottom, BeSideMetrics.tabBarClearance)

            if showAddWish {
                WishlistAddModal(
                    onClose: { showAddWish = false },
                    onAdd: { caption, photoData in
                        store.addMyWish(caption: caption, photoData: photoData)
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear { tab = initialTab }
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.wishlist.page")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFAF5FF),
                    Color(hex: 0xFDF2F8),
                    Color(hex: 0xF8FAFC),
                    Color(hex: 0xF0FDF9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hex: 0xC4B5FD).opacity(0.28), .clear],
                center: UnitPoint(x: 0.88, y: -0.08),
                startRadius: 20,
                endRadius: 280
            )
            RadialGradient(
                colors: [Color(hex: 0xFBCFE8).opacity(0.22), .clear],
                center: UnitPoint(x: 0, y: 0.3),
                startRadius: 20,
                endRadius: 240
            )
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xC4B5FD).opacity(0.4),
                            Color(hex: 0xFBCFE8).opacity(0.35),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 120, y: -140)
                .allowsHitTesting(false)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            matteCircleButton(systemName: "chevron.left") {
                if showHistory {
                    showHistory = false
                    doneArmedIndex = nil
                } else {
                    onClose()
                }
            }
            .accessibilityLabel(showHistory ? "Back to wishlist" : "Back to Us")
            .accessibilityIdentifier("us.wishlist.back")

            VStack(spacing: 2) {
                Text(showHistory ? "Wish history" : "Wishlist")
                    .font(.system(size: 11, weight: .light))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.42))
                Text(
                    showHistory
                        ? "Gifts you and \(partnerName) completed"
                        : "Your wishes and \(partnerName)'s ideas"
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ink.opacity(0.82))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            if showHistory {
                Color.clear.frame(width: 40, height: 40)
            } else {
                matteCircleButton(systemName: "clock.arrow.circlepath") {
                    showHistory = true
                    doneArmedIndex = nil
                }
                .accessibilityLabel("Completed wishes history")
                .accessibilityIdentifier("us.wishlist.history")
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    if tab == .mine {
                        if store.myWishlist.isEmpty {
                            emptyCopy("Add a photo and caption — \(partnerName) will see it.")
                        } else {
                            ForEach(Array(store.myWishlist.enumerated()), id: \.element.id) { index, wish in
                                mineRow(wish, index: index)
                            }
                        }
                    } else if store.partnerWishlist.isEmpty {
                        emptyCopy("\(partnerName) hasn't added wishes yet.")
                    } else {
                        ForEach(store.partnerWishlist) { wish in
                            partnerRow(wish)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            if tab == .mine {
                Button {
                    showAddWish = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Add a wish")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(BeSideColor.navyLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 10, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .accessibilityIdentifier("us.wishlist.add")
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            tabButton(title: "Mine", selected: tab == .mine) {
                tab = .mine
                doneArmedIndex = nil
            }
            .accessibilityIdentifier("us.wishlist.tab.mine")

            tabButton(title: partnerName, selected: tab == .partner) {
                tab = .partner
                doneArmedIndex = nil
            }
            .accessibilityIdentifier("us.wishlist.tab.partner")
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.55))
                .overlay {
                    Capsule().stroke(Color(hex: 0x2D2D44).opacity(0.1), lineWidth: 1)
                }
                .shadow(color: Color.white.opacity(0.8), radius: 0, y: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.wishlist.tabs")
    }

    private func tabButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? BeSideColor.navyLabel : ink.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        Capsule()
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.18), radius: 8, y: 3)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var historyList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                if store.wishlistHistory.isEmpty {
                    emptyCopy("Completed wishes will show up here.")
                } else {
                    ForEach(store.wishlistHistory) { item in
                        historyRow(item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .accessibilityIdentifier("us.wishlist.history.list")
    }

    private func emptyCopy(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .light))
            .foregroundStyle(ink.opacity(0.4))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    private func mineRow(_ wish: UsWishlistItem, index: Int) -> some View {
        let armed = doneArmedIndex == index
        return HStack(spacing: 12) {
            wishThumb(wish)
            Text(wish.caption)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            HStack(spacing: 6) {
                Button {
                    store.removeMyWish(at: index)
                    if doneArmedIndex == index { doneArmedIndex = nil }
                    else if let armed = doneArmedIndex, armed > index { doneArmedIndex = armed - 1 }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 28, height: 28)
                        .background { chromeCircle }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(wish.caption)")

                Button {
                    if armed {
                        store.markMyWishDone(at: index)
                        doneArmedIndex = nil
                    } else {
                        doneArmedIndex = index
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text(armed ? "Confirm" : "Done")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(armed ? Color(hex: 0x047857) : ink.opacity(0.45))
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background {
                        Capsule()
                            .fill(armed ? Color(hex: 0xECFDF5).opacity(0.9) : Color.white.opacity(0.55))
                            .overlay {
                                Capsule().stroke(
                                    armed ? Color(hex: 0x10B981).opacity(0.28) : ink.opacity(0.12),
                                    lineWidth: 1
                                )
                            }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(armed ? "Confirm \(wish.caption) as done" : "Mark \(wish.caption) as done")
            }
        }
        .padding(10)
        .background { wishCardBackground }
        .accessibilityIdentifier("us.wishlist.mine.row.\(wish.id)")
    }

    private func partnerRow(_ wish: UsWishlistItem) -> some View {
        HStack(spacing: 12) {
            wishThumb(wish)
            Text(wish.caption)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(10)
        .background { wishCardBackground }
        .accessibilityIdentifier("us.wishlist.partner.row.\(wish.id)")
    }

    private func historyRow(_ item: UsCompletedWish) -> some View {
        let forMe = item.direction == .forMe
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(forMe ? Color(hex: 0x047857) : Color(hex: 0xBE185D))
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(forMe ? Color(hex: 0xECFDF5).opacity(0.9) : Color(hex: 0xFDF2F8).opacity(0.9))
                        .overlay {
                            Circle().stroke(
                                forMe ? Color(hex: 0x10B981).opacity(0.28) : Color(hex: 0xFB7185).opacity(0.22),
                                lineWidth: 1
                            )
                        }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.88))
                Text(
                    forMe
                        ? "\(partnerName) fulfilled this for you"
                        : "You fulfilled this for \(partnerName)"
                )
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(ink.opacity(0.5))
                Text(UsWishlist.historyDateLabel(item.completedAt))
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(ink.opacity(0.38))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background { wishCardBackground }
    }

    @ViewBuilder
    private func wishThumb(_ wish: UsWishlistItem) -> some View {
        if !wish.photoURL.isEmpty {
            Group {
                if wish.photoURL.hasPrefix("data:") || wish.photoURL.hasPrefix("file:") {
                    if let ui = localImage(from: wish.photoURL) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        thumbPlaceholder
                    }
                } else {
                    AsyncImage(url: URL(string: wish.photoURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            thumbPlaceholder
                        }
                    }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: 0x2D2D44).opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var thumbPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(ink.opacity(0.06))
            .frame(width: 72, height: 72)
    }

    private var wishCardBackground: some View {
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
            .shadow(color: ink.opacity(0.04), radius: 5, y: 2)
    }

    private var chromeCircle: some View {
        Circle()
            .fill(Color.white.opacity(0.55))
            .overlay {
                Circle().stroke(ink.opacity(0.12), lineWidth: 1)
            }
    }

    private func matteCircleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ink.opacity(0.56))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.44))
                        .overlay {
                            Circle().stroke(ink.opacity(0.15), lineWidth: 1.5)
                        }
                        .shadow(color: ink.opacity(0.06), radius: 8, y: 2)
                }
        }
        .buttonStyle(.plain)
    }

    private func localImage(from urlString: String) -> UIImage? {
        if urlString.hasPrefix("data:"),
           let comma = urlString.firstIndex(of: ","),
           let data = Data(base64Encoded: String(urlString[urlString.index(after: comma)...])) {
            return UIImage(data: data)
        }
        if urlString.hasPrefix("file:"), let url = URL(string: urlString),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}

/// Add-wish glass modal — Figma Make UsScreen add wish overlay.
struct WishlistAddModal: View {
    let onClose: () -> Void
    let onAdd: (String, Data?) -> Void

    @State private var caption = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private var canAdd: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: 0x1A1A2E).opacity(0.32)
                .background(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

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

                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 0) {
                        Text("Add a wish")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.9))
                        Text("Upload a photo and leave a short caption")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(ink.opacity(0.45))
                            .padding(.top, 4)
                            .padding(.bottom, 16)

                        photoPicker
                            .padding(.bottom, 12)

                        TextField("What do you wish for?", text: $caption)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(ink.opacity(0.88))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.72))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(ink.opacity(0.12), lineWidth: 1)
                                    }
                            }
                            .onChange(of: caption) { _, value in
                                if value.count > UsWishlist.captionMaxLength {
                                    caption = String(value.prefix(UsWishlist.captionMaxLength))
                                }
                            }
                            .accessibilityIdentifier("us.wishlist.add.caption")

                        Text("\(caption.count)/\(UsWishlist.captionMaxLength)")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(ink.opacity(0.38))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 6)

                        Button {
                            guard canAdd else { return }
                            onAdd(caption, photoData)
                            onClose()
                        } label: {
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(canAdd ? BeSideColor.navyLabel : ink.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(canAdd ? BeSideColor.navyStart : ink.opacity(0.1))
                                        .overlay {
                                            if canAdd {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(BeSideColor.navyFill)
                                            }
                                        }
                                        .shadow(
                                            color: canAdd ? BeSideColor.navyStart.opacity(0.22) : .clear,
                                            radius: 10,
                                            y: 4
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAdd)
                        .padding(.top, 14)
                        .accessibilityIdentifier("us.wishlist.add.commit")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.45))
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color.white.opacity(0.55))
                                    .overlay {
                                        Circle().stroke(ink.opacity(0.12), lineWidth: 1)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("us.wishlist.add.close")
                }
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
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.12), radius: 24, y: 10)
            }
            .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("us.wishlist.add.modal")
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: photoData == nil ? [6, 4] : [])
                            )
                            .foregroundStyle(ink.opacity(photoData == nil ? 0.2 : 0.12))
                    }
                    .frame(height: 160)

                if let photoData, let ui = UIImage(data: photoData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(ink.opacity(0.35))
                        Text("Upload photo")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ink.opacity(0.48))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: pickerItem) { _, item in
            Task {
                guard let item else { return }
                photoData = try? await item.loadTransferable(type: Data.self)
            }
        }
        .overlay(alignment: .topTrailing) {
            if photoData != nil {
                Button {
                    photoData = nil
                    pickerItem = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .overlay {
                                    Circle().stroke(ink.opacity(0.12), lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
    }
}
