import PhotosUI
import SwiftUI
import UIKit

/// Us home shell — Figma Make `UsScreen` first viewport (feature flows stubbed).
struct UsView: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore? = nil
    /// Switch root tabs (e.g. mood-reaction notification → Me).
    var onSelectTab: ((AppTab) -> Void)? = nil
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
    @State private var showManagePair = false
    @State private var showCoupleSharePage = false
    @State private var showSharedMomentSourceSheet = false
    @State private var showSharedMomentCamera = false
    @State private var showSharedMomentLibrary = false
    @State private var sharedMomentPickerItem: PhotosPickerItem?
    @State private var cameraCaptureJPEG: Data?
    @State private var showCoupleStorySourceSheet = false
    @State private var showCoupleStoryCamera = false
    @State private var showCoupleStoryLibrary = false
    @State private var coupleStoryPickerItem: PhotosPickerItem?
    @State private var coupleStoryCaptureJPEG: Data?
    @State private var viewingCoupleStoryID: String?
    /// Viewer from strip uses live (24h) list; from archive uses full history.
    @State private var viewingCoupleStoryFromArchive = false
    @State private var showCoupleStoriesArchive = false
    @State private var layout = BeSideMetrics.UsLayout.standard

    private var ink: Color { Color(hex: 0x26282B) }

    /// Home chrome (bell) — hidden under full-screen Us overlays.
    private var showsUsHomeChrome: Bool {
        !showNotifications && !showScreenPhotoPage && !showDatesDetail
            && !showImportantDatesList && !showImportantDatesAdd && !showCoupleSharePage
            && !showCoupleStoriesArchive && viewingCoupleStoryID == nil
            && !showWishlist && !showLoveNotesPage && !showSharedMemoriesPage
    }

    /// Thin daily strip above the tab bar — only while something is still open for today.
    private var showsDailyTogetherNudge: Bool {
        showsUsHomeChrome
            && store.coupleSurfaceState != .unpaired
            && dailyTogetherNudgeModel.destination != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            BeSideBackground.widgetCanvas
                .ignoresSafeArea()

            BeSideBackground.widgetAmbientBlobs()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)

                    heroSection
                        .padding(.bottom, layout.heroBottomGap)

                    homeEntrySections
                        .padding(.bottom, layout.sectionBottomGap)

                    usDailyWarmthFooter
                        .padding(.bottom, layout.sectionBottomGap)

                    // Clear floating tab + daily strip (overlay, not safeAreaInset).
                    Color.clear.frame(
                        height: layout.tabBarClearance
                            + (showsDailyTogetherNudge ? layout.nudgeHeight + 10 : 0)
                    )
                }
                .padding(.horizontal, layout.pageInset)
            }
            .scrollClipDisabled()

            if showsDailyTogetherNudge {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                    dailyTogetherNudge
                        .padding(.horizontal, layout.pageInset)
                        // Sit snug above the floating tab chrome.
                        .padding(.bottom, layout.tabBarClearance - 14)
                }
                .zIndex(40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.22), value: showsDailyTogetherNudge)
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

            if showCoupleSharePage {
                CoupleSharePage(
                    store: store,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.28)) {
                            showCoupleSharePage = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(92)
            }

            if showCoupleStoriesArchive {
                CoupleStoriesArchivePage(
                    stories: store.coupleStoriesNewestFirst,
                    meLabel: "You",
                    partnerLabel: store.partnerDisplayName,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.28)) {
                            showCoupleStoriesArchive = false
                        }
                    },
                    onOpenStory: { id in
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewingCoupleStoryFromArchive = true
                            viewingCoupleStoryID = id
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(93)
            }

            if let storyID = viewingCoupleStoryID {
                CoupleStoryViewer(
                    stories: viewingCoupleStoryFromArchive
                        ? store.coupleStoriesNewestFirst
                        : store.coupleStoriesLiveNewestFirst,
                    startID: storyID,
                    meLabel: "You",
                    partnerLabel: store.partnerDisplayName,
                    onSeen: { id in store.markCoupleStorySeen(id: id) },
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewingCoupleStoryID = nil
                            viewingCoupleStoryFromArchive = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(97)
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
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showCoupleSharePage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showScreenPhotoPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showSharedMemoriesPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showCoupleStoriesArchive)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showNotifications)
        .animation(.easeOut(duration: 0.2), value: loveNoteReading != nil)
        .animation(.easeOut(duration: 0.2), value: viewingMemoryID != nil)
        .animation(.easeOut(duration: 0.2), value: showSharedMemoryAdd)
        .onAppear {
            store.refreshNotificationSources()
        }
        .onGeometryChange(for: BeSideMetrics.UsLayout.self) { proxy in
            BeSideMetrics.UsLayout.resolve(
                width: proxy.size.width,
                height: max(proxy.size.height, UIScreen.main.bounds.height),
                safeBottom: proxy.safeAreaInsets.bottom
            )
        } action: { newLayout in
            layout = newLayout
        }
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.us.screenIdentifier)
        .pairingRequiredGate(store: store, session: session)
        .sheet(isPresented: $showManagePair) {
            MyPartnerSheet(store: store, session: session, isPresented: $showManagePair)
        }
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
        .confirmationDialog(
            "Add a story",
            isPresented: $showCoupleStorySourceSheet,
            titleVisibility: .visible
        ) {
            if CameraImagePicker.isCameraAvailable {
                Button("Record / Take Photo") {
                    coupleStoryCaptureJPEG = nil
                    showCoupleStoryCamera = true
                }
            }
            Button("Choose from Library") {
                showCoupleStoryLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showCoupleStoryLibrary,
            selection: $coupleStoryPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: coupleStoryPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let photo = try? await item.loadTransferable(type: SharedMemoryPickedPhoto.self) {
                    store.addCoupleStory(imageJPEG: photo.data)
                } else if let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let jpeg = image.jpegData(compressionQuality: 0.82) {
                    store.addCoupleStory(imageJPEG: jpeg)
                }
                coupleStoryPickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCoupleStoryCamera) {
            CameraImagePicker(imageData: $coupleStoryCaptureJPEG)
                .ignoresSafeArea()
        }
        .onChange(of: coupleStoryCaptureJPEG) { _, data in
            guard let data else { return }
            store.addCoupleStory(imageJPEG: data)
            coupleStoryCaptureJPEG = nil
            showCoupleStoryCamera = false
        }
        .animation(.easeOut(duration: 0.2), value: viewingCoupleStoryID != nil)
    }

    private func openNotification(_ notification: UsNotification) {
        showNotifications = false

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
        wishlistInitialTab = tab
        showImportantDatesAdd = false
        showImportantDatesList = false
        showDatesDetail = false
        showWishlist = true
    }

    private func openDatesDetail() {
        showImportantDatesAdd = false
        showImportantDatesList = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showDatesDetail = true
        }
    }

    private func openDatesList() {
        showImportantDatesAdd = false
        showDatesDetail = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showImportantDatesList = true
        }
    }

    private func openDatesAdd() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showImportantDatesAdd = true
        }
    }

    private func openLittleThingsAdd(day: Date = Date()) {
        littleThingsAddDay = Calendar.current.startOfDay(for: day)
        withAnimation(.easeOut(duration: 0.2)) {
            showLittleThingsAdd = true
        }
    }

    private var notificationsBell: some View {
        Button {
            store.refreshNotificationSources()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                showNotifications = true
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                    }

                if store.unreadNotificationsCount > 0 {
                    Circle()
                        .fill(BeSideColor.raspberry)
                        .frame(width: 7, height: 7)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1)
                        }
                        .offset(x: 1, y: 1)
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
        let surface = store.coupleSurfaceState
        let rose = Color(hex: 0xC48A9A)
        let roseSoft = Color(hex: 0xE8BEC9)

        return VStack(spacing: 0) {
            ZStack {
                // Soft modern wash inside the glass.
                RoundedRectangle(cornerRadius: BeSideMetrics.glassCornerLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0xFCE7F3).opacity(0.35),
                                Color.clear,
                                Color(hex: 0xEDE4F5).opacity(0.28),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)

                VStack(spacing: 4) {
                    // One top row: bell | names | share — same vertical level.
                    HStack(alignment: .center, spacing: 4) {
                        Group {
                            if showsUsHomeChrome {
                                notificationsBell
                            } else {
                                Color.clear.frame(width: 28, height: 28)
                            }
                        }
                        .frame(width: 28, height: 28)

                        Button {
                            guard surface != .unpaired else { return }
                            showManagePair = true
                        } label: {
                            Group {
                                if surface == .unpaired {
                                    Text(store.coupleHeroTitle)
                                        .font(.system(size: layout.heroTitleSize, weight: .thin))
                                        .tracking(0.4)
                                        .foregroundStyle(ink.opacity(0.82))
                                } else {
                                    HStack(spacing: 6) {
                                        Text(store.displayName)
                                        Text("&")
                                            .font(.system(size: layout.heroTitleSize - 5, weight: .ultraLight))
                                            .foregroundStyle(ink.opacity(0.82))
                                        Text(store.partnerDisplayName)
                                    }
                                    .font(.system(size: layout.heroTitleSize, weight: .thin))
                                    .tracking(0.3)
                                    .foregroundStyle(ink.opacity(0.82))
                                }
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .contentShape(Rectangle())
                            .accessibilityLabel(store.coupleHeroTitle)
                            .accessibilityIdentifier("us.couple.names")
                        }
                        .buttonStyle(.plain)
                        .disabled(surface == .unpaired)
                        .accessibilityHint(surface == .unpaired ? "" : "Opens pair settings")

                        Group {
                            if surface != .unpaired {
                                Button {
                                    withAnimation(.easeOut(duration: 0.28)) {
                                        showCoupleSharePage = true
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(rose.opacity(0.75))
                                        .frame(width: 28, height: 28)
                                        .background {
                                            Circle()
                                                .fill(Color.white.opacity(0.45))
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Share couple card")
                                .accessibilityIdentifier("us.hero.share.instagram")
                            } else {
                                Color.clear.frame(width: 28, height: 28)
                            }
                        }
                        .frame(width: 28, height: 28)
                    }

                    Button {
                        guard surface != .unpaired else { return }
                        showManagePair = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            roseSoft.opacity(0.28),
                                            Color.clear,
                                        ],
                                        center: .center,
                                        startRadius: 6,
                                        endRadius: layout.avatarSize * 0.78
                                    )
                                )
                                .frame(
                                    width: layout.avatarSize * 1.45,
                                    height: layout.avatarSize * 1.45
                                )

                            HStack(spacing: -layout.avatarSize * 0.28) {
                                avatarBubble(name: store.displayName, jpeg: store.meAvatarJPEG)
                                if surface != .unpaired {
                                    avatarBubble(
                                        name: store.partnerDisplayName,
                                        jpeg: store.partnerAvatarJPEG,
                                        isPlaceholder: surface == .pairedWaiting
                                            && store.partnerAvatarJPEG == nil
                                    )
                                }
                            }
                        }
                        .offset(y: -2)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("us.avatars")
                    }
                    .buttonStyle(.plain)
                    .disabled(surface == .unpaired)
                    .accessibilityHint(surface == .unpaired ? "" : "Opens pair settings")

                    Group {
                        if surface == .pairedActive {
                            Button {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    store.cycleTimeTogetherStyle()
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(store.coupleHeroSubtitle)
                                        .font(.system(size: layout.heroSubtitleSize, weight: .light))
                                        .tracking(0.2)
                                        .multilineTextAlignment(.center)
                                        .contentTransition(.opacity)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9, weight: .medium))
                                        .opacity(0.55)
                                }
                                .foregroundStyle(rose.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Changes how time together is shown")
                        } else {
                            Text(store.coupleHeroSubtitle)
                                .font(.system(size: layout.heroSubtitleSize, weight: .light))
                                .tracking(0.2)
                                .foregroundStyle(ink.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .accessibilityIdentifier("us.time.together")
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCornerLarge, style: .widgetFrosted)

            if surface != .unpaired {
                // Re-evaluate 24h expiry while Us is visible.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let live = store.coupleStoriesLive(at: context.date)
                    let hasHistory = !store.coupleStoriesNewestFirst.isEmpty
                    VStack(alignment: .trailing, spacing: 4) {
                        if hasHistory {
                            Button {
                                withAnimation(.easeOut(duration: 0.28)) {
                                    showCoupleStoriesArchive = true
                                }
                            } label: {
                                Text("See all")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(ink.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("See all stories")
                            .accessibilityIdentifier("us.stories.seeAll")
                        }

                        coupleStoriesStrip(liveStories: live)
                    }
                    .padding(.top, layout.storiesTopGap)
                    .padding(.bottom, 4)
                }
            } else {
                Text("Pair to unlock daily progress, dates, and little things together.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .accessibilityIdentifier("us.hero")
    }

    /// Shared Instagram-style story rings — Add first, then each live (24h) story.
    private func coupleStoriesStrip(liveStories: [UsCoupleStory]) -> some View {
        // Break out of page inset so rings aren't hard-clipped mid-circle;
        // matching content padding keeps the first/last rings aligned with the hero card.
        let edge = layout.pageInset
        let ring = layout.storyRingSize
        let thumb = ring - 8

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 7) {
                Button {
                    showCoupleStorySourceSheet = true
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                )
                                .foregroundStyle(ink.opacity(0.22))
                                .frame(width: ring, height: ring)
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .frame(width: thumb, height: thumb)
                            Image(systemName: "plus")
                                .font(.system(size: max(14, ring * 0.28), weight: .semibold))
                                .foregroundStyle(ink.opacity(0.55))
                        }
                        Text("Add")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ink.opacity(0.45))
                            .lineLimit(1)
                    }
                    .frame(width: ring)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a story")
                .accessibilityIdentifier("us.stories.add")

                ForEach(liveStories) { story in
                    Button {
                        viewingCoupleStoryFromArchive = false
                        viewingCoupleStoryID = story.id
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: story.seenByMe
                                                ? [ink.opacity(0.18), ink.opacity(0.18)]
                                                : [
                                                    Color(hex: 0xF9A8D4),
                                                    Color(hex: 0xC4B5FD),
                                                    Color(hex: 0xF9A8D4),
                                                ],
                                            center: .center
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: ring, height: ring)

                                storyThumb(story)
                                    .frame(width: thumb, height: thumb)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                                    }
                            }
                            Text(story.author == .me ? "You" : store.partnerDisplayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ink.opacity(0.5))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(width: ring)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "Story from \(story.author == .me ? "you" : store.partnerDisplayName)"
                    )
                    .accessibilityIdentifier("us.stories.item.\(story.id)")
                }
            }
            .padding(.horizontal, edge)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, -edge)
        .scrollClipDisabled()
        .accessibilityIdentifier("us.stories.strip")
    }

    private func storyThumb(_ story: UsCoupleStory) -> some View {
        Group {
            if let image = UIImage(data: story.imageJPEG) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF3D6DE), Color(hex: 0xE8BEC9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    private func avatarBubble(name: String, jpeg: Data?, isPlaceholder: Bool = false) -> some View {
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
            } else if isPlaceholder {
                Image(systemName: "person.fill")
                    .font(.system(size: layout.avatarSize * 0.34, weight: .light))
                    .foregroundStyle(ink.opacity(0.35))
            } else {
                Text(initial)
                    .font(.system(size: layout.avatarSize * 0.34, weight: .light))
                    .foregroundStyle(ink.opacity(0.72))
            }
        }
        .frame(width: layout.avatarSize, height: layout.avatarSize)
        .opacity(isPlaceholder ? 0.72 : 1)
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
            Circle().stroke(Color.white.opacity(0.92), lineWidth: 2)
        }
        .shadow(color: ink.opacity(0.08), radius: 8, y: 3)
        .accessibilityLabel(name)
    }

    private struct DailyTogetherNudgeModel {
        let destination: AppTab?
        let title: String
        let doneCount: Int
        let total: Int
    }

    private var dailyTogetherNudgeModel: DailyTogetherNudgeModel {
        let partner = store.partnerDisplayName
        let bothDone: [Bool] = [
            store.meMoodSharedToday && store.partnerMoodSharedToday,
            store.meCheckedPartnerMoodToday && store.partnerCheckedMyMoodToday,
            store.meActivityDoneToday && store.partnerActivityDoneToday,
        ]
        let doneCount = bothDone.filter { $0 }.count
        let total = bothDone.count

        if !store.meMoodSharedToday {
            return DailyTogetherNudgeModel(
                destination: .me,
                title: "Share how you feel today",
                doneCount: doneCount,
                total: total
            )
        }
        if !store.meCheckedPartnerMoodToday {
            return DailyTogetherNudgeModel(
                destination: .partner,
                title: "See how \(partner) feels",
                doneCount: doneCount,
                total: total
            )
        }
        if !store.meActivityDoneToday {
            return DailyTogetherNudgeModel(
                destination: .connection,
                title: "Do today’s couple task",
                doneCount: doneCount,
                total: total
            )
        }
        if doneCount < total {
            return DailyTogetherNudgeModel(
                destination: .partner,
                title: "Waiting for \(partner) to finish",
                doneCount: doneCount,
                total: total
            )
        }
        return DailyTogetherNudgeModel(
            destination: nil,
            title: "You’re both done for today",
            doneCount: doneCount,
            total: total
        )
    }

    /// Thin bright strip above the floating tab bar — next daily action + progress.
    private var dailyTogetherNudge: some View {
        let model = dailyTogetherNudgeModel
        let wash = BeSideColor.navyStart

        return Button {
            guard let destination = model.destination else { return }
            onSelectTab?(destination)
        } label: {
            HStack(spacing: 8) {
                Text(model.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.94))
                    .lineLimit(1)
                Text("·")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                Text("\(model.doneCount)/\(model.total)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .monospacedDigit()
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background {
                Capsule()
                    .fill(wash)
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                    }
                    .shadow(color: wash.opacity(0.28), radius: 8, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(model.title). \(model.doneCount) of \(model.total) complete")
        .accessibilityIdentifier("us.daily.nudge")
    }

    private var screenPhotoCard: some View {
        Button {
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

        let scale = layout.momentsThumbScale

        return ZStack(alignment: .bottomLeading) {
            // Back shared photo — slightly tilted
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(photoWash.opacity(0.85))
                .frame(width: 46 * scale, height: 54 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
                .rotationEffect(.degrees(-8))
                .offset(x: 2 * scale, y: -6 * scale)
                .shadow(color: BeSideColor.navyStart.opacity(0.08), radius: 3, y: 1)

            // Front: home-screen widget frame with photo
            VStack(spacing: 0) {
                HStack(spacing: 3) {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 10 * scale, height: 2.5)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4 * scale, height: 4 * scale)
                }
                .padding(.horizontal, 7 * scale)
                .padding(.top, 6 * scale)

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
                                    .font(.system(size: 12 * scale, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 6 * scale)
                .padding(.top, 5 * scale)
                .padding(.bottom, 7 * scale)
            }
            .frame(width: 58 * scale, height: 68 * scale)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    }
                    .shadow(color: BeSideColor.navyStart.opacity(0.12), radius: 6, y: 3)
            }
            .offset(x: 14 * scale, y: 0)
        }
        .frame(width: 72 * scale, height: 74 * scale, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }

    /// Soft daily line under the tile grid — affirmation / wish for the couple.
    private var usDailyWarmthFooter: some View {
        let line = Self.dailyWarmthLine(for: Date(), surface: store.coupleSurfaceState)

        return Text("“\(line)”")
            .font(.system(size: layout.warmthSize, weight: .light))
            .foregroundStyle(ink.opacity(0.55))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .accessibilityLabel(line)
            .accessibilityIdentifier("us.daily.warmth")
    }

    /// Stable per calendar day so the footer does not flicker on re-open.
    private static func dailyWarmthLine(
        for day: Date,
        surface: MeSessionStore.CoupleSurfaceState,
        calendar: Calendar = .current
    ) -> String {
        let lines: [String]
        switch surface {
        case .unpaired:
            lines = [
                "Love grows when two people choose to show up.",
                "The right person makes ordinary days feel softer.",
                "Connection begins with a simple hello.",
            ]
        case .pairedWaiting:
            lines = [
                "Patience is also a way of caring.",
                "Your together story is just getting started.",
                "Small welcomes make a new partnership feel like home.",
            ]
        case .pairedActive:
            lines = [
                "The little things are the big things.",
                "Love is made of ordinary moments, noticed.",
                "Be beside each other — even in the quiet.",
                "A small kindness today is a memory tomorrow.",
                "Hold the ordinary days as gently as the special ones.",
                "You don’t need a big reason to show up softly.",
                "Closer is often just one thoughtful ask away.",
                "Choose each other in the small hours too.",
                "Gentle attention is how love stays close.",
                "Your togetherness grows in tiny, steady ways.",
            ]
        }
        let dayIndex = calendar.ordinality(of: .day, in: .era, for: day) ?? 0
        return lines[abs(dayIndex) % lines.count]
    }

    /// 2×2 square tiles: Dates | Little Things / Love Notes | Screen.
    private var homeEntrySections: some View {
        let columns = [
            GridItem(.flexible(), spacing: layout.gridSpacing),
            GridItem(.flexible(), spacing: layout.gridSpacing),
        ]

        return LazyVGrid(columns: columns, spacing: layout.gridSpacing) {
            usDatesTile
            usAsksTile
            usLoveNotesTile
            usScreenTile
        }
        .accessibilityIdentifier("us.entry.tiles")
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

                if let featured, let urgency, let days {
                    datesTileEventContent(date: featured, days: days, urgency: urgency)
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
                                    .frame(width: 4, height: 4)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, layout.tilePad)
                        .padding(.bottom, layout.tilePad)
                    }
                    .accessibilityHidden(true)
                }

                VStack {
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Spacer(minLength: 0)
                        // Layout spacers for gift / + overlays.
                        Color.clear.frame(width: layout.tileActionSize, height: layout.tileActionSize)
                        Color.clear.frame(width: layout.tileActionSize, height: layout.tileActionSize)
                    }
                }
                .padding(layout.tilePad)
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
            HStack(spacing: 7) {
                Button {
                    openWishlist(tab: .mine)
                } label: {
                    Image(systemName: "gift")
                        .font(.system(size: layout.tileActionSize * 0.4, weight: .semibold))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.5))
                        .frame(width: layout.tileActionSize, height: layout.tileActionSize)
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
                        .font(.system(size: layout.tileActionSize * 0.42, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .frame(width: layout.tileActionSize, height: layout.tileActionSize)
                        .background { Circle().fill(BeSideColor.navyFill) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a date")
                .accessibilityIdentifier("us.tile.dates.add")
            }
            .padding(layout.tilePad)
        }
        .aspectRatio(layout.tileAspect, contentMode: .fit)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
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

    private func datesTileEventContent(date: UsImportantDate, days: Int, urgency: DateUrgency) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                Text("Important\nDates")
                    .font(.system(size: layout.tileLabelSize, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                dateUrgencyBadge(days: days, urgency: urgency)
                    .accessibilityHidden(true)
            }

            Text(Self.dateDayMonth.string(from: date.date))
                .font(.system(size: layout.tileHeroSize, weight: .light))
                .foregroundStyle(dateHeroColor(urgency))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, layout.tilePad)
            Text(date.title)
                .font(.system(size: layout.tileBodySize, weight: .medium))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.84))
                .lineLimit(2)
                .padding(.top, 3)

            Spacer(minLength: layout.tileBottomReserve)
        }
        .padding(layout.tilePad)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var datesTileEmptyContent: some View {
        let (title, subtitle): (String, String) = {
            switch store.coupleSurfaceState {
            case .unpaired:
                return ("Pair to unlock", "Shared dates appear after you connect")
            case .pairedWaiting:
                return ("No dates yet", "Add a day — invite \(store.partnerDisplayName) to celebrate it")
            case .pairedActive:
                return ("No dates yet", "Add a shared day")
            }
        }()

        return VStack(alignment: .leading, spacing: 0) {
            Text("Important\nDates")
                .font(.system(size: layout.tileLabelSize, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(title)
                .font(.system(size: layout.tileBodySize + 2, weight: .medium))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.75))
                .padding(.top, 6)
            Text(subtitle)
                .font(.system(size: layout.tileCaptionSize, weight: .light))
                .foregroundStyle(BeSideColor.navyStart.opacity(0.38))
                .padding(.top, 3)

            Spacer(minLength: layout.tileBottomReserve)
        }
        .padding(layout.tilePad)
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
                        .font(.system(size: layout.tileLabelSize, weight: .semibold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(count)")
                            .font(.system(size: layout.tileHeroSize + 6, weight: .light, design: .rounded))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.88))
                            .monospacedDigit()

                        Text("open today")
                            .font(.system(size: layout.tileCaptionSize + 1, weight: .light))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.42))
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 6)

                    if let latest = latestOpen {
                        let forName = latest.isAssignedToMe
                            ? store.displayName
                            : store.partnerDisplayName
                        VStack(alignment: .leading, spacing: 2) {
                            Text("For \(forName)")
                                .font(.system(size: layout.tileLabelSize, weight: .semibold))
                                .foregroundStyle(BeSideColor.navyStart.opacity(0.5))
                            HStack(alignment: .top, spacing: 6) {
                                // Task marker — reads as a to-do, not body copy.
                                Circle()
                                    .strokeBorder(
                                        BeSideColor.navyStart.opacity(0.35),
                                        lineWidth: 1.2
                                    )
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)
                                Text(latest.body)
                                    .font(.system(size: layout.tileBodySize, weight: .medium))
                                    .foregroundStyle(BeSideColor.navyStart.opacity(0.78))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top, 6)
                    } else {
                        Text(littleThingsEmptyCopy(todayAsksEmpty: todayAsks.isEmpty))
                            .font(.system(size: layout.tileCaptionSize + 1, weight: .light))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.4))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 5)
                    }

                    // Same bottom reserve as Dates — clears the + without indenting copy.
                    Spacer(minLength: layout.tileBottomReserve)
                }
                .padding(layout.tilePad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            Button {
                openLittleThingsAdd(day: today)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: layout.tileActionSize * 0.42, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: layout.tileActionSize, height: layout.tileActionSize)
                    .background {
                        Circle()
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.2), radius: 6, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(layout.tilePad)
            .accessibilityLabel("Add a little thing")
            .accessibilityIdentifier("us.tile.asks.add")
        }
        .aspectRatio(layout.tileAspect, contentMode: .fit)
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
                showLoveNotesPage = true
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Love Notes")
                            .font(.system(size: layout.tileLabelSize, weight: .semibold))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white.opacity(0.55))
                        Spacer(minLength: 0)
                        if tileKind == .incomingActive {
                            Text("\(store.incomingUnreadLoveNotes.count)")
                                .font(.system(size: layout.tileCaptionSize, weight: .semibold).monospacedDigit())
                                .foregroundStyle(BeSideColor.navyStart)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background { Capsule().fill(Color.white.opacity(0.9)) }
                        }
                        if tileKind == .outgoingOnly {
                            Text("\(store.outgoingLoveNotes.count) sent")
                                .font(.system(size: layout.tileLabelSize, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.white.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
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
                        .font(.system(size: layout.tileBodySize + 3, weight: .semibold))
                        .foregroundStyle(BeSideColor.loveNotePinkBright)
                        .padding(.top, 1)

                    Text(tileBodyText)
                        .font(.system(size: layout.tileBodySize, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(BeSideColor.navyLabel)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !tileSubtitleText.isEmpty {
                        Text(tileSubtitleText)
                            .font(.system(size: layout.tileCaptionSize, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    Spacer(minLength: 0)
                }
                .padding(layout.tilePad)
                .padding(.bottom, layout.tileBottomReserve)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showLoveNoteCompose = true
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: layout.tileActionSize * 0.4, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: layout.tileActionSize, height: layout.tileActionSize)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .overlay { Circle().stroke(Color.white.opacity(0.28), lineWidth: 0.8) }
                    }
            }
            .buttonStyle(.plain)
            .padding(layout.tilePad)
            .accessibilityLabel("Leave a love note")
            .accessibilityIdentifier("us.tile.lovenotes.compose")
        }
        .aspectRatio(layout.tileAspect, contentMode: .fit)
        .background { usGlassChrome(.notes) }
        .clipShape(RoundedRectangle(cornerRadius: BeSideMetrics.glassCorner, style: .continuous))
        .accessibilityLabel("Open love notes")
        .accessibilityIdentifier("us.tile.lovenotes")
    }

    private var usScreenTile: some View {
        ZStack(alignment: .bottomTrailing) {
            Button {
                showScreenPhotoPage = true
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Shared Moments")
                        .font(.system(size: layout.tileLabelSize, weight: .semibold))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.4))

                    Text(sharedMomentsTileCopy)
                        .font(.system(size: layout.tileCaptionSize + 1, weight: .medium))
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.78))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 6)

                    screenPhotoPreviewThumb
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)
                }
                .padding(layout.tilePad)
                .padding(.bottom, layout.tileBottomReserve)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                showSharedMomentSourceSheet = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: layout.tileActionSize * 0.4, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(width: layout.tileActionSize, height: layout.tileActionSize)
                    .background {
                        Circle()
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.2), radius: 6, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(layout.tilePad)
            .accessibilityLabel("Add a photo — camera or library")
            .accessibilityIdentifier("us.tile.screen.camera")
        }
        .aspectRatio(layout.tileAspect, contentMode: .fit)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
        .accessibilityLabel("Shared Moments. \(sharedMomentsTileCopy).")
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
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.15)
            .foregroundStyle(dateBadgeInk(urgency))
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
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
        switch store.coupleSurfaceState {
        case .unpaired:
            return "Pair to exchange\nlove notes"
        case .pairedWaiting:
            if store.loveNotesTileKind == .outgoingOnly {
                return "Your words are on their way"
            }
            return "Say something sweet —\nwaiting on \(store.partnerDisplayName)"
        case .pairedActive:
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
    }

    private var tileSubtitleText: String {
        switch store.coupleSurfaceState {
        case .unpaired:
            return ""
        case .pairedWaiting:
            switch store.loveNotesTileKind {
            case .empty: return "No note from them yet"
            case .outgoingOnly: return "Waiting for them to open"
            case .incomingActive: return "Tap to open"
            }
        case .pairedActive:
            switch store.loveNotesTileKind {
            case .empty: return ""
            case .outgoingOnly: return "Waiting for them to open"
            case .incomingActive: return "Tap to open"
            }
        }
    }

    private func littleThingsEmptyCopy(todayAsksEmpty: Bool) -> String {
        switch store.coupleSurfaceState {
        case .unpaired:
            return "Pair to ask each other for small favors."
        case .pairedWaiting:
            return todayAsksEmpty
                ? "Ask \(store.partnerDisplayName) for something small — they’re still settling in."
                : "All done for today."
        case .pairedActive:
            return todayAsksEmpty
                ? "Ask each other for something small today."
                : "All done for today."
        }
    }

    private var sharedMomentsTileCopy: String {
        switch store.coupleSurfaceState {
        case .unpaired:
            return "Pair to share photos on a home-screen widget"
        case .pairedWaiting:
            return store.sharedMomentPhotoJPEG == nil
                ? "Add the first photo for your widget"
                : "Your photo is ready for the widget"
        case .pairedActive:
            return "Share photos and pin one to your widget"
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

#Preview("Us · paired active") {
    UsView(store: .previewPairedActive())
}

#Preview("Us · paired waiting") {
    UsView(store: .previewPairedWaiting())
}

#Preview("Us · unpaired") {
    UsView(store: .previewUnpaired())
}
