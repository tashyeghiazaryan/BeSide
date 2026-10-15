import PhotosUI
import SwiftUI
import UIKit

/// Us home shell — Figma Make `UsScreen` first viewport (feature flows stubbed).
struct UsView: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore? = nil
    /// Switch root tabs (e.g. mood-reaction notification → Me).
    var onSelectTab: ((AppTab) -> Void)? = nil
    @State private var dailyTipID: DailyTaskID?
    @State private var showImportantDatesList = false
    @State private var showDatesDetail = false
    @State private var showLittleThingsAdd = false
    @State private var littleThingsAddDay = Calendar.current.startOfDay(for: Date())
    @State private var showImportantDatesAdd = false
    @State private var showWishlist = false
    @State private var wishlistInitialTab: WishlistPage.Tab = .mine
    /// Cycles same-day Important Dates on the Us tile.
    @State private var datesTileIndex = 0
    /// After a manual swipe, pause auto-advance briefly.
    @State private var datesTilePauseUntil = Date.distantPast
    @State private var showLoveNotesPage = false
    @State private var showScreenPhotoPage = false
    @State private var showLoveNoteCompose = false
    @State private var loveNoteReading: LoveNote?
    @State private var showSharedMemoriesPage = false
    @State private var showSharedMemoryAdd = false
    @State private var editingMemory: UsSharedMemory?
    @State private var viewingMemoryID: String?
    @State private var showNotifications = false
    @State private var showSharedMomentSourceSheet = false
    @State private var showSharedMomentCamera = false
    @State private var showSharedMomentLibrary = false
    @State private var sharedMomentPickerItem: PhotosPickerItem?
    @State private var cameraCaptureJPEG: Data?

    private enum DailyTaskID: String, CaseIterable, Identifiable {
        case mood
        case reaction
        case activity

        var id: String { rawValue }

        var short: String {
            switch self {
            case .mood: return "mood"
            case .reaction: return "partner"
            case .activity: return "prompt"
            }
        }

        var label: String {
            switch self {
            case .mood: return "Share your mood & wish"
            case .reaction: return "Check partner's mood"
            case .activity: return "Complete a couples prompt"
            }
        }

        var why: String {
            switch self {
            case .mood:
                return "Lets your partner see how you feel today and what would help — so they can show up for you."
            case .reaction:
                return "A quick look at their day builds care: react, acknowledge, and stay close even when you're apart."
            case .activity:
                return "A shared question or task turns the day into a moment together — small rituals that deepen connection."
            }
        }
    }

    private var ink: Color { Color(hex: 0x26282B) }

    private var anyTipOpen: Bool { dailyTipID != nil }

    private func dismissTips() {
        guard anyTipOpen else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            dailyTipID = nil
        }
    }

    private var tipDismissOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: dismissTips)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            BeSideBackground.widgetCanvas
                .ignoresSafeArea()
                .onTapGesture(perform: dismissTips)

            BeSideBackground.widgetAmbientBlobs()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)

                    heroSection
                        .padding(.bottom, 16)
                        .zIndex(anyTipOpen ? 50 : 0)

                    homeEntrySections
                        .padding(.horizontal, -10)
                        .padding(.bottom, 28)
                        .zIndex(0)
                        .overlay { if anyTipOpen { tipDismissOverlay } }

                    Color.clear.frame(height: BeSideMetrics.tabBarClearance)
                        .overlay { if anyTipOpen { tipDismissOverlay } }
                }
                .padding(.horizontal, BeSideMetrics.pageInset)
            }
            .scrollClipDisabled()

            if !showNotifications && !showScreenPhotoPage && !showDatesDetail
                && !showImportantDatesList && !showImportantDatesAdd {
                notificationsBell
                    .padding(.leading, 14)
                    .padding(.top, 4)
            }

            if showNotifications {
                NotificationsPage(
                    store: store,
                    onClose: { showNotifications = false },
                    onOpen: { notification in
                        openNotification(notification)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(100)
            }

            if showDatesDetail {
                DatesDetailPage(
                    store: store,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showDatesDetail = false
                        }
                    },
                    onAddLittleThing: { day in
                        openLittleThingsAdd(day: day)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(88)
            }

            if showLittleThingsAdd {
                LittleThingsAddModal(
                    day: littleThingsAddDay,
                    onClose: { showLittleThingsAdd = false },
                    onAdd: { body, day in
                        store.addPartnerAsk(body: body, day: day)
                    },
                    fromMeCount: { day in
                        UsPartnerAsk.countFromMe(on: day, from: store.partnerAsks)
                    }
                )
                .transition(.opacity)
                .zIndex(94)
            }

            if showImportantDatesList {
                ImportantDatesListPage(
                    dates: store.importantDatesSorted,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showImportantDatesList = false
                        }
                    },
                    onAddDate: {
                        openDatesAdd()
                    },
                    onWishlistIdeas: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showImportantDatesList = false
                        }
                        openWishlist(tab: .partner)
                    },
                    onDeleteDate: { date in
                        store.deleteImportantDate(id: date.id)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(88)
            }

            if showImportantDatesAdd {
                ImportantDatesAddPage(
                    onClose: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showImportantDatesAdd = false
                        }
                    },
                    onAdd: { title, note, date, icon in
                        store.addImportantDate(title: title, date: date, icon: icon, note: note)
                    },
                    onAdded: {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showImportantDatesAdd = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(92)
            }

            if showWishlist {
                WishlistPage(
                    store: store,
                    initialTab: wishlistInitialTab,
                    onClose: { showWishlist = false }
                )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(90)
            }

            if showScreenPhotoPage {
                ScreenPhotoPage(
                    store: store,
                    onClose: { showScreenPhotoPage = false },
                    onPickPhoto: { showSharedMomentSourceSheet = true }
                )
                .zIndex(93)
            }

            if showLoveNotesPage {
                LoveNotesPage(
                    store: store,
                    onClose: { showLoveNotesPage = false },
                    onCompose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showLoveNoteCompose = true
                        }
                    },
                    onOpenNote: { note in loveNoteReading = note },
                    onDeleteNote: { note in
                        if loveNoteReading?.id == note.id {
                            loveNoteReading = nil
                        }
                        store.deleteLoveNote(id: note.id)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(91)
            }

            if showLoveNoteCompose {
                LoveNoteComposeModal(
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showLoveNoteCompose = false
                        }
                    },
                    onSend: { body in
                        store.sendLoveNote(body: body)
                    }
                )
                .transition(.opacity)
                .zIndex(95)
            }

            if let note = loveNoteReading {
                LoveNoteReaderOverlay(
                    note: note,
                    partnerName: store.partnerDisplayName,
                    onDismiss: {
                        if note.direction == .incoming && note.status == .sent {
                            store.markNoteRead(id: note.id)
                        }
                        loveNoteReading = nil
                    }
                )
                .transition(.opacity)
                .zIndex(96)
            }

            if showSharedMemoriesPage {
                SharedMemoriesPage(
                    store: store,
                    onClose: { showSharedMemoriesPage = false },
                    onAdd: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            editingMemory = nil
                            showSharedMemoryAdd = true
                        }
                    },
                    onOpenMemory: { memory in
                        viewingMemoryID = memory.id
                    },
                    onEdit: { memory in
                        withAnimation(.easeOut(duration: 0.2)) {
                            editingMemory = memory
                            showSharedMemoryAdd = true
                        }
                    },
                    onDelete: { memory in
                        deleteSharedMemory(memory)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(92)
            }

            if showSharedMemoryAdd {
                SharedMemoryAddModal(
                    editing: editingMemory,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSharedMemoryAdd = false
                            editingMemory = nil
                        }
                    },
                    onAdd: { title, dateTime, description, mood, photoData in
                        let ok = store.addSharedMemory(
                            title: title,
                            dateTime: dateTime,
                            description: description,
                            mood: mood,
                            photoData: photoData
                        )
                        if ok {
                            showSharedMemoriesPage = true
                        }
                        return ok
                    },
                    onUpdate: { id, title, dateTime, description, mood, photoData, removePhoto in
                        store.updateSharedMemory(
                            id: id,
                            title: title,
                            dateTime: dateTime,
                            description: description,
                            mood: mood,
                            photoData: photoData,
                            removePhoto: removePhoto
                        )
                    }
                )
                .id(editingMemory?.id ?? "create")
                .transition(.opacity)
                .zIndex(99)
            }

            if viewingMemoryID != nil {
                SharedMemoryDetailOverlay(
                    memories: store.sharedMemories,
                    selectedID: $viewingMemoryID,
                    onClose: { viewingMemoryID = nil },
                    onEdit: { memory in
                        withAnimation(.easeOut(duration: 0.2)) {
                            editingMemory = memory
                            showSharedMemoryAdd = true
                        }
                    },
                    onDelete: { memory in
                        deleteSharedMemory(memory)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(98)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showImportantDatesList)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showImportantDatesAdd)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showDatesDetail)
        .animation(.easeOut(duration: 0.2), value: showLittleThingsAdd)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showWishlist)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showLoveNotesPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showScreenPhotoPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showSharedMemoriesPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showNotifications)
        .animation(.easeOut(duration: 0.2), value: loveNoteReading != nil)
        .animation(.easeOut(duration: 0.2), value: viewingMemoryID != nil)
        .animation(.easeOut(duration: 0.2), value: showSharedMemoryAdd)
        .onAppear {
            store.refreshNotificationSources()
        }
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.us.screenIdentifier)
        .pairingRequiredGate(store: store, session: session)
        .confirmationDialog(
            "Add a Shared Moment",
            isPresented: $showSharedMomentSourceSheet,
            titleVisibility: .visible
        ) {
            if CameraImagePicker.isCameraAvailable {
                Button("Take Photo") {
                    cameraCaptureJPEG = nil
                    showSharedMomentCamera = true
                }
            }
            Button("Choose from Library") {
                showSharedMomentLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showSharedMomentLibrary,
            selection: $sharedMomentPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: sharedMomentPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let photo = try? await item.loadTransferable(type: SharedMemoryPickedPhoto.self) {
                    store.setSharedMomentPhotoJPEG(photo.data)
                } else if let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let jpeg = image.jpegData(compressionQuality: 0.82) {
                    store.setSharedMomentPhotoJPEG(jpeg)
                }
                sharedMomentPickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showSharedMomentCamera) {
            CameraImagePicker(imageData: $cameraCaptureJPEG)
                .ignoresSafeArea()
        }
        .onChange(of: cameraCaptureJPEG) { _, data in
            guard let data else { return }
            store.setSharedMomentPhotoJPEG(data)
            cameraCaptureJPEG = nil
            showSharedMomentCamera = false
        }
    }

    private func openNotification(_ notification: UsNotification) {
        showNotifications = false
        dismissTips()

        switch notification.kind {
        case .moodReaction:
            onSelectTab?(.me)
        case .loveNote:
            showLoveNotesPage = true
            if let id = notification.relatedID,
               let note = store.loveNotes.first(where: { $0.id == id }) {
                loveNoteReading = note
            } else if let unread = store.incomingUnreadLoveNotes.first {
                loveNoteReading = unread
            }
        case .importantDate:
            store.refreshDateReminders()
            openDatesDetail()
        case .sharedMemory:
            if let id = notification.relatedID {
                openMemoryFeed(startingAt: id)
            } else {
                showSharedMemoriesPage = true
            }
        }
    }

    private func openWishlist(tab: WishlistPage.Tab) {
        dismissTips()
        wishlistInitialTab = tab
        showImportantDatesAdd = false
        showImportantDatesList = false
        showDatesDetail = false
        showWishlist = true
    }

    private func openDatesDetail() {
        dismissTips()
        showImportantDatesAdd = false
        showImportantDatesList = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showDatesDetail = true
        }
    }

    private func openDatesList() {
        dismissTips()
        showImportantDatesAdd = false
        showDatesDetail = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showImportantDatesList = true
        }
    }

    private func openDatesAdd() {
        dismissTips()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showImportantDatesAdd = true
        }
    }

    private func openLittleThingsAdd(day: Date = Date()) {
        dismissTips()
        littleThingsAddDay = Calendar.current.startOfDay(for: day)
        withAnimation(.easeOut(duration: 0.2)) {
            showLittleThingsAdd = true
        }
    }

    private var notificationsBell: some View {
        Button {
            dismissTips()
            store.refreshNotificationSources()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                showNotifications = true
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
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

                if store.unreadNotificationsCount > 0 {
                    Circle()
                        .fill(BeSideColor.raspberry)
                        .frame(width: 8, height: 8)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1)
                        }
                        .offset(x: -2, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            store.unreadNotificationsCount > 0
                ? "Notifications, \(store.unreadNotificationsCount) unread"
                : "Notifications"
        )
        .accessibilityIdentifier("us.notifications")
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("\(store.displayName) & \(store.partnerDisplayName)")
                    .font(.system(size: 30, weight: .ultraLight))
                    .tracking(0.4)
                    .foregroundStyle(ink.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                    .accessibilityIdentifier("us.couple.names")

                Text(store.timeTogetherPhrase)
                    .font(.system(size: 16, weight: .light))
                    .tracking(0.2)
                    .foregroundStyle(ink.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)
                    .accessibilityIdentifier("us.time.together")

                HStack(spacing: -28) {
                    avatarBubble(name: store.displayName, jpeg: store.meAvatarJPEG)
                    avatarBubble(name: store.partnerDisplayName, jpeg: store.partnerAvatarJPEG)
                }
                .padding(.bottom, 16)
                .accessibilityIdentifier("us.avatars")
            }
            .frame(maxWidth: .infinity)
            .overlay { if anyTipOpen { tipDismissOverlay } }

            // Chips stay above dismiss overlays so toggle / re-tap works.
            dailyProgress
                .padding(.bottom, 14)
                .zIndex(dailyTipID == nil ? 0 : 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .accessibilityIdentifier("us.hero")
    }

    private func avatarBubble(name: String, jpeg: Data?) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        // Figma `US_AVATAR_*` — soft dusty rose wash, navy rim, ink initial.
        let rose = Color(hex: 0xE8BEC9)
        let roseLight = Color(hex: 0xF3D6DE)
        let roseDeep = Color(hex: 0xD9A8B6)
        let photo = jpeg.flatMap { UIImage(data: $0) }
        return Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initial)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(ink.opacity(0.72))
            }
        }
        .frame(width: 100, height: 100)
        .background {
            Circle()
                .fill(rose.opacity(0.18))
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    roseLight.opacity(0.38),
                                    rose.opacity(0.32),
                                    roseDeep.opacity(0.28),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .clipShape(Circle())
        .overlay {
            Circle().stroke(ink.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: ink.opacity(0.1), radius: 10, y: 5)
        .accessibilityLabel(name)
    }

    private var dailyProgress: some View {
        let tasks: [(DailyTaskID, Bool, Bool)] = [
            (.mood, store.meMoodSharedToday, store.partnerMoodSharedToday),
            (.reaction, store.meCheckedPartnerMoodToday, store.partnerCheckedMyMoodToday),
            (.activity, store.meActivityDoneToday, store.partnerActivityDoneToday),
        ]
        let doneCount = tasks.filter { $0.1 && $0.2 }.count

        // Layout height = chips only; tip overlays level bar / tiles (does not push page down).
        return HStack(spacing: 6) {
            ForEach(Array(tasks.enumerated()), id: \.element.0.id) { index, item in
                let (id, meDone, partnerDone) = item
                let bothDone = meDone && partnerDone
                if index > 0 {
                    Text("·")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(ink.opacity(0.22))
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dailyTipID = dailyTipID == id ? nil : id
                    }
                } label: {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(
                                    bothDone
                                        ? LinearGradient(
                                            colors: [
                                                Color(hex: 0x6EE7B7).opacity(0.28),
                                                Color(hex: 0x34D399).opacity(0.18),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.55)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                )
                                .overlay {
                                    Circle().stroke(
                                        bothDone
                                            ? Color(hex: 0x34D399).opacity(0.28)
                                            : ink.opacity(0.12),
                                        lineWidth: 1
                                    )
                                }
                            if bothDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x34D399).opacity(0.85))
                            }
                        }
                        .frame(width: 18, height: 18)

                        Text(id.short)
                            .font(.system(size: 12, weight: dailyTipID == id ? .medium : .light))
                            .tracking(0.4)
                            .foregroundStyle(ink.opacity(0.48))
                            .textCase(.lowercase)
                    }
                    .padding(.vertical, 2)
                    .padding(.leading, 2)
                    .padding(.trailing, 6)
                    .background {
                        Capsule()
                            .fill(dailyTipID == id ? Color.white.opacity(0.55) : Color.clear)
                            .overlay {
                                Capsule().stroke(
                                    dailyTipID == id ? ink.opacity(0.14) : Color.clear,
                                    lineWidth: 1
                                )
                            }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(id.label)\(bothDone ? ", done" : ", not done"). Show explanation.")
                .accessibilityIdentifier("us.daily.\(id.rawValue)")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Daily progress \(doneCount) of \(tasks.count) complete")
        .accessibilityIdentifier("us.daily.progress")
        .background {
            // Empty space around chips dismisses; chip buttons still receive taps on top.
            if anyTipOpen { tipDismissOverlay }
        }
        .overlay(alignment: .top) {
            if let tipID = dailyTipID, let tip = tasks.first(where: { $0.0 == tipID }) {
                tipCard(
                    eyebrow: "Daily · \(tip.1 && tip.2 ? "Done" : "To do")",
                    title: tip.0.label,
                    body: tip.0.why
                )
                .padding(.top, 28)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                    )
                )
                .accessibilityIdentifier("us.daily.tip")
            }
        }
    }

    private var screenPhotoCard: some View {
        Button {
            dismissTips()
            showScreenPhotoPage = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0xE8BEC9).opacity(0.32))
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.72))
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Shared Moments")
                            .font(.system(size: 10, weight: .light))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(ink.opacity(0.42))

                        HStack(spacing: 3) {
                            Text("Send each other photos — keep one on a home-screen widget")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ink.opacity(0.82))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.28))
                        }
                    }
                }

                Spacer(minLength: 6)

                screenPhotoPreviewThumb
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background { usGlassChrome(.screen) }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(
            "Shared Moments. Send each other photos — keep one on a home-screen widget. Empty."
        )
        .accessibilityIdentifier("us.screen.card")
    }

    /// Mini home-screen widget + two shared photo cards (shows real JPEG when set).
    private var screenPhotoPreviewThumb: some View {
        let rose = Color(hex: 0xE8BEC9)
        let mist = Color(hex: 0xC7D2FE)
        let photoWash = LinearGradient(
            colors: [
                Color(hex: 0xFCE7F3),
                rose.opacity(0.9),
                mist.opacity(0.75),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let captured = store.sharedMomentPhotoJPEG.flatMap { UIImage(data: $0) }

        return ZStack(alignment: .bottomLeading) {
            // Back shared photo — slightly tilted
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(photoWash.opacity(0.85))
                .frame(width: 46, height: 54)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
                .rotationEffect(.degrees(-8))
                .offset(x: 2, y: -6)
                .shadow(color: BeSideColor.navyStart.opacity(0.08), radius: 3, y: 1)

            // Front: home-screen widget frame with photo
            VStack(spacing: 0) {
                HStack(spacing: 3) {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 10, height: 2.5)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
                .padding(.horizontal, 7)
                .padding(.top, 6)

                Group {
                    if let captured {
                        Image(uiImage: captured)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(photoWash)
                            .overlay {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 6)
                .padding(.top, 5)
                .padding(.bottom, 7)
            }
            .frame(width: 58, height: 68)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    }
                    .shadow(color: BeSideColor.navyStart.opacity(0.12), radius: 6, y: 3)
            }
            .offset(x: 14, y: 0)
        }
        .frame(width: 72, height: 74, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }

    private func tipCard(eyebrow: String? = nil, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.4))
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ink.opacity(0.82))
            Text(body)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(ink.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 280, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 0.8)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
        }
    }

    /// 2×2 square tiles: Dates | Little Things / Love Notes | Screen.
    private var homeEntrySections: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            usDatesTile
            usAsksTile
            usLoveNotesTile
            usScreenTile
        }
        .accessibilityIdentifier("us.entry.tiles")
        .onAppear {
            if store.partnerAsks.isEmpty {
                store.partnerAsks = UsPartnerAsk.demoSeed()
            }
        }
    }

    private var usDatesTile: some View {
        let rotating = store.usTileRotatingDates
        let safeIndex = rotating.isEmpty ? 0 : datesTileIndex % rotating.count
        let featured: UsImportantDate? = rotating.isEmpty ? nil : rotating[safeIndex]
        let days = featured.map { UsImportantDates.daysUntil($0.date) }
        let urgency = days.map { dateUrgency(days: $0) }
        let canCarousel = rotating.count > 1

        return Button {
            openDatesList()
        } label: {
            ZStack {
                if let urgency {
                    dateUrgencyWash(urgency)
                }

                if let featured, let urgency {
                    datesTileEventContent(date: featured, urgency: urgency)
                        .contentTransition(.opacity)
                        .id("us.dates.tile.featured.\(featured.id)")
                } else {
                    datesTileEmptyContent
                }

                if canCarousel {
                    VStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 5) {
                            ForEach(0..<rotating.count, id: \.self) { index in
                                Circle()
                                    .fill(
                                        BeSideColor.navyStart.opacity(
                                            index == safeIndex ? 0.55 : 0.18
                                        )
                                    )
                                    .frame(width: 5, height: 5)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 12)
                        .padding(.bottom, 12)
                    }
                    .accessibilityHidden(true)
                }

                VStack {
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Spacer(minLength: 0)
                        // Layout spacers for gift / + overlays.
                        Color.clear.frame(width: 34, height: 34)
                        Color.clear.frame(width: 34, height: 34)
                    }
                }
                .padding(10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard canCarousel else { return }
                    let dx = value.translation.width
                    datesTilePauseUntil = Date().addingTimeInterval(5)
                    withAnimation(.easeInOut(duration: 0.28)) {
                        if dx < -24 {
                            datesTileIndex = (safeIndex + 1) % rotating.count
                        } else if dx > 24 {
                            datesTileIndex = (safeIndex - 1 + rotating.count) % rotating.count
                        }
                    }
                }
        )
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 8) {
                Button {
                    openWishlist(tab: .mine)
                } label: {
                    Image(systemName: "gift")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.5))
                        .frame(width: 34, height: 34)
                        .background {
                            Circle().fill(Color.white.opacity(0.62))
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("us.tile.wishlist")

                Button {
                    openDatesAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .frame(width: 34, height: 34)
                        .background { Circle().fill(BeSideColor.navyFill) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a date")
                .accessibilityIdentifier("us.tile.dates.add")
            }
            .padding(10)
        }
        .aspectRatio(0.88, contentMode: .fit)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
        .overlay(alignment: .topTrailing) {
            if let days, let urgency {
                dateUrgencyBadge(days: days, urgency: urgency)
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            featured.map { "\($0.title), \(UsImportantDates.shortDate($0.date))" }
                ?? "Important dates"
        )
        .accessibilityHint(canCarousel ? "Swipe to see more dates on this day" : "Opens important dates list")
        .accessibilityIdentifier("us.tile.dates")
        .onAppear {
            datesTileIndex = 0
        }
        .onChange(of: store.usTileRotatingDates.map(\.id)) { _, ids in
            if ids.isEmpty {
                datesTileIndex = 0
            } else if datesTileIndex >= ids.count {
                datesTileIndex = 0
            }
        }
        .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
            let count = store.usTileRotatingDates.count
            guard count > 1 else { return }
            guard Date() >= datesTilePauseUntil else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                datesTileIndex = (datesTileIndex + 1) % count
            }
        }
    }

    private func datesTileEventContent(date: UsImportantDate, urgency: DateUrgency) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Important Dates")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.trailing, 72)

            Text(Self.dateDayMonth.string(from: date.date))
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(dateHeroColor(urgency))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 22)
            Text(date.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.84))
                .lineLimit(2)
                .padding(.top, 6)

            Spacer(minLength: 44)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var datesTileEmptyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Important Dates")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.trailing, 72)

            Text("No dates yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.75))
                .padding(.top, 8)
            Text("Add a shared day")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.38))
                .padding(.top, 4)

            Spacer(minLength: 44)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }

    private var usAsksTile: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let todayAsks = UsPartnerAsk.asks(on: today, from: store.partnerAsks)
        let openAsks = todayAsks.filter { !$0.isDone }
        let count = openAsks.count
        /// Newest open ask only — tile never lists more than one preview.
        let latestOpen = openAsks.max(by: { $0.createdAt < $1.createdAt })
        let rose = Color(hex: 0xE8BEC9)

        return Button {
            openDatesDetail()
        } label: {
            ZStack {
                // Soft rose wash — warm, distinct from Dates / Love Notes.
                LinearGradient(
                    colors: [
                        rose.opacity(0.28),
                        Color(hex: 0xFCE7F3).opacity(0.14),
                        Color.clear,
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                VStack(alignment: .leading, spacing: 0) {
                    Text("Little Things")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(count)")
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.88))
                            .monospacedDigit()

                        Text("open today")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.42))
                    }
                    .padding(.top, 10)

                    if let latest = latestOpen {
                        let forName = latest.isAssignedToMe
                            ? store.displayName
                            : store.partnerDisplayName
                        VStack(alignment: .leading, spacing: 3) {
                            Text("For \(forName)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BeSideColor.navyStart.opacity(0.5))
                            Text(latest.body)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BeSideColor.navyStart.opacity(0.78))
                                .lineLimit(2)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 40)
                    } else {
                        Text(
                            todayAsks.isEmpty
                                ? "Ask each other for something small today."
                                : "All done for today."
                        )
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                            .lineLimit(3)
                            .padding(.top, 8)
                            .padding(.trailing, 40)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            Button {
                openLittleThingsAdd(day: today)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.2), radius: 6, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel("Add a little thing")
            .accessibilityIdentifier("us.tile.asks.add")
        }
        .aspectRatio(0.88, contentMode: .fit)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
        .accessibilityLabel(
            latestOpen.map { ask in
                "\(count) little things open today. Latest: \(ask.body)."
            } ?? "\(count) little things open today."
        )
        .accessibilityIdentifier("us.tile.asks")
    }

    private var usLoveNotesTile: some View {
        let tileKind = store.loveNotesTileKind
        let isActive = tileKind == .incomingActive

        return ZStack(alignment: .bottomTrailing) {
            Button {
                dismissTips()
                showLoveNotesPage = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Love Notes")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white.opacity(0.55))
                        Spacer(minLength: 0)
                        if tileKind == .incomingActive {
                            Text("\(store.incomingUnreadLoveNotes.count)")
                                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                .foregroundStyle(BeSideColor.navyStart)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background { Capsule().fill(Color.white.opacity(0.9)) }
                        }
                        if tileKind == .outgoingOnly {
                            Text("\(store.outgoingLoveNotes.count) sent")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.white.opacity(0.9))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .overlay {
                                            Capsule().stroke(Color.white.opacity(0.28), lineWidth: 0.5)
                                        }
                                }
                        }
                    }

                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BeSideColor.loveNotePinkBright)
                        .padding(.top, 2)

                    Text(tileBodyText)
                        .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(BeSideColor.navyLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if tileKind != .empty {
                        Text(tileSubtitleText)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                dismissTips()
                withAnimation(.easeOut(duration: 0.2)) {
                    showLoveNoteCompose = true
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .overlay { Circle().stroke(Color.white.opacity(0.28), lineWidth: 0.8) }
                    }
            }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel("Leave a love note")
            .accessibilityIdentifier("us.tile.lovenotes.compose")
        }
        .aspectRatio(0.88, contentMode: .fit)
        .background { usGlassChrome(.notes) }
        .clipShape(RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous))
        .accessibilityLabel("Open love notes")
        .accessibilityIdentifier("us.tile.lovenotes")
    }

    private var usScreenTile: some View {
        ZStack(alignment: .bottomTrailing) {
            Button {
                dismissTips()
                showScreenPhotoPage = true
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Shared Moments")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.4))

                    Spacer(minLength: 8)

                    screenPhotoPreviewThumb

                    Text("Send each other photos — keep one on a home-screen widget")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.78))
                        .lineLimit(3)
                        .padding(.top, 8)
                        .padding(.trailing, 44)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                dismissTips()
                showSharedMomentSourceSheet = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.2), radius: 6, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel("Add a photo — camera or library")
            .accessibilityIdentifier("us.tile.screen.camera")
        }
        .aspectRatio(0.88, contentMode: .fit)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
        .accessibilityLabel(
            "Shared Moments. Send each other photos — keep one on a home-screen widget."
        )
        .accessibilityIdentifier("us.screen.card")
    }

    private enum DateUrgency {
        case upcoming, soon, tomorrow, today
    }

    private func dateUrgency(days: Int) -> DateUrgency {
        if days <= 0 { return .today }
        if days == 1 { return .tomorrow }
        if days <= 3 { return .soon }
        return .upcoming
    }

    private func dateHeroColor(_ urgency: DateUrgency) -> Color {
        switch urgency {
        case .upcoming: return BeSideColor.navyStart.opacity(0.55)
        case .soon, .tomorrow: return BeSideColor.dateNear.opacity(0.82)
        case .today: return BeSideColor.raspberry
        }
    }

    @ViewBuilder
    private func dateUrgencyBadge(days: Int, urgency: DateUrgency) -> some View {
        let label: String = {
            switch urgency {
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            default: return UsImportantDates.countdownLabel(days)
            }
        }()

        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(dateBadgeInk(urgency))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background { dateBadgeChrome(urgency) }
    }

    /// Figma Make Dates widget badge — quiet outlined pill (see Tomorrow screenshot) / today navy.
    private func dateBadgeInk(_ urgency: DateUrgency) -> Color {
        switch urgency {
        case .today: return Color.white.opacity(0.96)
        case .upcoming, .soon, .tomorrow: return BeSideColor.navyStart.opacity(0.46)
        }
    }

    @ViewBuilder
    private func dateBadgeChrome(_ urgency: DateUrgency) -> some View {
        switch urgency {
        case .today:
            Capsule()
                .fill(BeSideColor.navyFill)
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.28), radius: 5, y: 2)
        case .upcoming, .soon, .tomorrow:
            Capsule()
                .fill(Color.white.opacity(0.55))
                .overlay {
                    Capsule()
                        .stroke(BeSideColor.navyStart.opacity(0.22), lineWidth: 1)
                }
        }
    }

    /// Soft pink wash only — no lilac (that made the badge read purple).
    private func dateUrgencyWash(_ urgency: DateUrgency) -> some View {
        let colors: [Color] = {
            switch urgency {
            case .upcoming:
                return [Color(hex: 0xFCE7F3).opacity(0.14), Color.clear]
            case .soon:
                return [Color(hex: 0xFBCFE8).opacity(0.16), Color.clear]
            case .tomorrow:
                return [Color(hex: 0xFBCFE8).opacity(0.20), Color.clear]
            case .today:
                return [Color(hex: 0xFCE7F3).opacity(0.26), Color.clear]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private static let dateDayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM"
        return f
    }()

    private func loveNoteCard(note: LoveNote?, isPrimary: Bool) -> some View {
        return Button {
            dismissTips()
            showLoveNotesPage = true
            if let note, note.direction == .incoming {
                loveNoteReading = note
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                if let note {
                    let author = note.direction == .incoming
                        ? store.partnerDisplayName
                        : store.displayName

                    Image(systemName: note.direction == .incoming ? "heart.fill" : "paperplane.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            note.direction == .incoming
                                ? BeSideColor.raspberry.opacity(0.95)
                                : BeSideColor.navyLabel
                        )
                        .frame(width: 24, height: 24)
                        .background {
                            Circle()
                                .fill(
                                    note.direction == .incoming
                                        ? BeSideColor.loveNotePink.opacity(0.35)
                                        : Color.white.opacity(0.16)
                                )
                        }

                    Text("“\(LoveNoteBody.preview(note.body, max: 36))”")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BeSideColor.navyLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text("— \(author)")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.62))
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BeSideColor.raspberry.opacity(0.95))
                        .frame(width: 24, height: 24)
                        .background {
                            Circle().fill(BeSideColor.loveNotePink.opacity(0.35))
                        }

                    Text(isPrimary ? tileBodyText : "Leave a note when you’re ready")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BeSideColor.navyLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background { usGlassChrome(.notes) }
        .accessibilityLabel("Open love notes")
        .accessibilityIdentifier(isPrimary ? "us.tile.lovenotes.card" : "us.tile.lovenotes.card.secondary")
    }

    private enum UsCardTint {
        case notes, screen
    }

    /// Navy Love Notes + white Screen cards.
    @ViewBuilder
    private func usGlassChrome(_ tint: UsCardTint) -> some View {
        let corner = BeSideMetrics.glassCorner
        switch tint {
        case .notes:
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(BeSideColor.navyFill)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.28), radius: 16, y: 8)
        case .screen:
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: ink.opacity(0.08), radius: 18, y: 8)
                .environment(\.colorScheme, .light)
        }
    }

    private func sectionChromeIcon(systemName: String, label: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(ink.opacity(0.48))
            .frame(width: 30, height: 30)
            .background {
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .overlay {
                        Circle().stroke(ink.opacity(0.1), lineWidth: 1)
                    }
            }
            .accessibilityLabel(label)
    }

    private var tileBodyText: String {
        switch store.loveNotesTileKind {
        case .empty:
            return "Say something sweet —\nit only takes a moment"
        case .outgoingOnly:
            return "Your words are on their way"
        case .incomingActive:
            let count = store.incomingUnreadLoveNotes.count
            return count > 1 ? "\(count) new notes for you" : "New note for you"
        }
    }

    private var tileSubtitleText: String {
        switch store.loveNotesTileKind {
        case .empty: return ""
        case .outgoingOnly: return "Waiting for them to open"
        case .incomingActive: return "Tap to open"
        }
    }

    private func openMemoryFeed(startingAt id: String) {
        viewingMemoryID = id
    }

    private func deleteSharedMemory(_ memory: UsSharedMemory) {
        let deletedID = memory.id
        let nextID: String? = {
            guard let idx = store.sharedMemories.firstIndex(where: { $0.id == deletedID }) else {
                return viewingMemoryID
            }
            if idx + 1 < store.sharedMemories.count {
                return store.sharedMemories[idx + 1].id
            }
            if idx > 0 {
                return store.sharedMemories[idx - 1].id
            }
            return nil
        }()

        _ = store.deleteSharedMemory(id: deletedID)

        if viewingMemoryID == deletedID {
            viewingMemoryID = nextID
        }
        if editingMemory?.id == deletedID {
            editingMemory = nil
            showSharedMemoryAdd = false
        }
    }

}

#Preview {
    UsView(store: MeSessionStore())
}
