import SwiftUI

/// Us home shell — Figma Make `UsScreen` first viewport (feature flows stubbed).
struct UsView: View {
    @Bindable var store: MeSessionStore
    /// Switch root tabs (e.g. mood-reaction notification → Me).
    var onSelectTab: ((AppTab) -> Void)? = nil
    @State private var dailyTipID: DailyTaskID?
    @State private var showLevelTip = false
    @State private var showImportantDatesList = false
    @State private var showImportantDatesAdd = false
    @State private var showWishlist = false
    @State private var wishlistInitialTab: WishlistPage.Tab = .mine
    @State private var datesTileIndex = 0
    @State private var showLoveNotesPage = false
    @State private var showLoveNoteCompose = false
    @State private var loveNoteReading: LoveNote?
    @State private var showSharedMemoriesPage = false
    @State private var showSharedMemoryAdd = false
    @State private var editingMemory: UsSharedMemory?
    @State private var viewingMemoryID: String?
    @State private var memoryCarouselIndex = 0
    @State private var memoryCarouselDragged = false
    @State private var showNotifications = false

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

    private var anyTipOpen: Bool { dailyTipID != nil || showLevelTip }

    private func dismissTips() {
        guard anyTipOpen else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            dailyTipID = nil
            showLevelTip = false
        }
    }

    private var tipDismissOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: dismissTips)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            BeSideBackground.softCanvas
                .ignoresSafeArea()
                .onTapGesture(perform: dismissTips)

            usAmbient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)

                    heroSection
                        .padding(.bottom, 16)
                        .zIndex(anyTipOpen ? 50 : 0)

                    entryTiles
                        .padding(.bottom, 24)
                        .zIndex(0)
                        .overlay { if anyTipOpen { tipDismissOverlay } }

                    sharedMemoriesSection
                        .padding(.bottom, 28)
                        .zIndex(0)
                        .overlay { if anyTipOpen { tipDismissOverlay } }

                    Color.clear.frame(height: BeSideMetrics.tabBarClearance)
                        .overlay { if anyTipOpen { tipDismissOverlay } }
                }
                .padding(.horizontal, BeSideMetrics.pageInset)
            }
            .scrollClipDisabled()

            if !showNotifications {
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

            if showImportantDatesList {
                ImportantDatesListModal(
                    dates: store.importantDatesSorted,
                    onClose: { showImportantDatesList = false },
                    onWishlistIdeas: {
                        showImportantDatesList = false
                        openWishlist(tab: .partner)
                    },
                    onAddDate: {
                        showImportantDatesList = false
                        showImportantDatesAdd = true
                    },
                    onDeleteDate: { date in
                        store.deleteImportantDate(id: date.id)
                    }
                )
                .transition(.opacity)
                .zIndex(80)
            }

            if showImportantDatesAdd {
                ImportantDatesAddModal(
                    onClose: { showImportantDatesAdd = false },
                    onAdd: { title, date, icon in
                        store.addImportantDate(title: title, date: date, icon: icon)
                    },
                    onAdded: {
                        showImportantDatesAdd = false
                        showImportantDatesList = true
                    }
                )
                .transition(.opacity)
                .zIndex(81)
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
                            memoryCarouselIndex = 0
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
        .animation(.easeOut(duration: 0.2), value: showImportantDatesList)
        .animation(.easeOut(duration: 0.2), value: showImportantDatesAdd)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showWishlist)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showLoveNotesPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showSharedMemoriesPage)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showNotifications)
        .animation(.easeOut(duration: 0.2), value: loveNoteReading != nil)
        .animation(.easeOut(duration: 0.2), value: viewingMemoryID != nil)
        .animation(.easeOut(duration: 0.2), value: showSharedMemoryAdd)
        .onChange(of: store.sharedMemories.count) { _, newCount in
            if memoryCarouselIndex >= newCount {
                memoryCarouselIndex = max(0, newCount - 1)
            }
        }
        .onAppear {
            store.refreshNotificationSources()
        }
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.us.screenIdentifier)
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
            showImportantDatesList = true
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
        showWishlist = true
    }

    private var usAmbient: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFBCFE8).opacity(0.55), Color(hex: 0xC4B5FD).opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -120, y: -160)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xA7F3D0).opacity(0.35), Color(hex: 0x93C5FD).opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 130, y: 320)
        }
        .allowsHitTesting(false)
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

                HStack(spacing: -22) {
                    avatarBubble(name: store.displayName)
                    avatarBubble(name: store.partnerDisplayName)
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

            longTermBar
                .zIndex(showLevelTip ? 40 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .accessibilityIdentifier("us.hero")
    }

    private func avatarBubble(name: String) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        // Figma `US_AVATAR_*` — soft dusty rose wash, navy rim, ink initial.
        let rose = Color(hex: 0xE8BEC9)
        let roseLight = Color(hex: 0xF3D6DE)
        let roseDeep = Color(hex: 0xD9A8B6)
        return Text(initial)
            .font(.system(size: 26, weight: .light))
            .foregroundStyle(ink.opacity(0.72))
            .frame(width: 76, height: 76)
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
                    .overlay {
                        Circle().stroke(ink.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: ink.opacity(0.1), radius: 7, y: 4)
            }
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
                        showLevelTip = false
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

    private var longTermBar: some View {
        let streak = store.usStreakDays
        let goal = store.usPointsToNext
        let frac = store.usLevelProgressFraction
        let points = store.usLongTermPoints
        let goalText = goal > 0 ? "\(goal)" : "max"

        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                dailyTipID = nil
                showLevelTip.toggle()
            }
        } label: {
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(store.usLevelName)
                        .font(.system(size: 16, weight: .medium))
                        .tracking(0.2)
                        .foregroundStyle(ink.opacity(0.68))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("Streak · \(streak) \(streak == 1 ? "day" : "days")")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.2)
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.85))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ink.opacity(0.06))
                            .overlay {
                                Capsule().stroke(Color(hex: 0x1A1A2E).opacity(0.12), lineWidth: 1)
                            }
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BeSideColor.navyStart,
                                        BeSideColor.navyEnd,
                                        Color(hex: 0x3D3D58),
                                        BeSideColor.navyEnd,
                                        BeSideColor.navyStart,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * frac))
                            .shadow(color: BeSideColor.navyStart.opacity(0.28), radius: 6, y: 0)
                    }
                }
                .frame(height: 9)

                HStack {
                    Text("\(points)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.52))
                        .monospacedDigit()
                    Spacer()
                    Text(goal > 0 ? "\(goal)" : "—")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(ink.opacity(0.38))
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Level progress \(points) of \(goalText) points. Show level explanation."
        )
        .accessibilityIdentifier("us.level")
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .top) {
            if showLevelTip {
                tipCard(
                    title: "\(store.usLevelEmoji)  \(store.usLevelName)",
                    body: "This bar tracks your long-term connection. Sharing moods, reacting to each other, and completing prompts together adds points toward the next level — a quiet map of how your bond grows over time."
                )
                .padding(.top, 52)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                    )
                )
                .accessibilityIdentifier("us.level.tip")
            }
        }
        .accessibilityElement(children: showLevelTip ? .contain : .combine)
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

    private var entryTiles: some View {
        HStack(alignment: .top, spacing: 10) {
            importantDatesTile
            loveNotesTile
        }
        // Figma: grid items-stretch; Love Notes drives the row
        .frame(height: 210)
        .accessibilityIdentifier("us.entry.tiles")
    }

    private var importantDatesTile: some View {
        let datesInk = Color(hex: 0x26282B)
        let butter = Color(hex: 0xFFEDA8)
        let previews = store.usTileRotatingDates
        let preview: UsImportantDate? = {
            guard !previews.isEmpty else { return nil }
            return previews[datesTileIndex % previews.count]
        }()
        let extraCount = store.usTileExtraCount
        let shouldRotate = previews.count > 1

        return ZStack(alignment: .topTrailing) {
            Button {
                dismissTips()
                showImportantDatesAdd = false
                showImportantDatesList = true
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    // Header + countdown share one row so the badge never covers “Important Dates”
                    // on narrow tiles (iPhone 16 / SE / Plus).
                    HStack(alignment: .top, spacing: 6) {
                        Text("Important\nDates")
                            .font(.system(size: 11, weight: .light))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(datesInk.opacity(0.38))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(1)
                            .fixedSize(horizontal: true, vertical: true)
                            .layoutPriority(1)

                        if let preview {
                            Spacer(minLength: 4)

                            Text(UsImportantDates.countdownLabel(UsImportantDates.daysUntil(preview.date)))
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(0.2)
                                .foregroundStyle(datesInk.opacity(0.46))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    butter.opacity(0.16),
                                                    Color.white.opacity(0.42),
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .overlay {
                                            Capsule().stroke(butter.opacity(0.22), lineWidth: 1)
                                        }
                                        .shadow(color: datesInk.opacity(0.04), radius: 2, y: 1)
                                }
                                .fixedSize()
                                .layoutPriority(0)
                                .id("dates-tile-badge-\(preview.id)")
                                .transition(.opacity)
                        }
                    }

                    if let preview {
                        Text(preview.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(datesInk)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 8)
                            .id("dates-tile-title-\(preview.id)")
                            .transition(.opacity)

                        Text(UsImportantDates.shortDate(preview.date))
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(datesInk.opacity(0.55))
                            .padding(.top, 4)
                            .id("dates-tile-date-\(preview.id)")
                            .transition(.opacity)

                        if extraCount > 0 {
                            Text("+\(extraCount) more")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(datesInk.opacity(0.42))
                                .padding(.top, 2)
                                .accessibilityIdentifier("us.tile.dates.more")
                        }
                    } else {
                        Text("Tap to see all important dates")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(datesInk.opacity(0.55))
                            .padding(.top, 12)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .padding(.bottom, 44)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.35), value: preview?.id)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                preview.map { item in
                    extraCount > 0
                        ? "Open important dates list, \(item.title), +\(extraCount) more"
                        : "Open important dates list, \(item.title)"
                } ?? "Open important dates list"
            )
            .accessibilityIdentifier("us.tile.dates")

            HStack(spacing: 6) {
                Button {
                    openWishlist(tab: .mine)
                } label: {
                    matteIconLabel(systemName: "gift", label: "Wishlist")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("us.tile.wishlist")

                Button {
                    dismissTips()
                    showImportantDatesList = false
                    showImportantDatesAdd = true
                } label: {
                    matteIconLabel(systemName: "plus", label: "Open calendar to add a date")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("us.tile.dates.add")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    // Figma `IMPORTANT_DATES_MODAL_GLASS.surface`
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.50),
                                    Color(hex: 0xFFFCF2).opacity(0.44),
                                    Color(hex: 0xFFF4DA).opacity(0.38),
                                    Color.white.opacity(0.34),
                                ],
                                startPoint: UnitPoint(x: 0.15, y: 0),
                                endPoint: UnitPoint(x: 0.85, y: 1)
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.52), lineWidth: 1)
                }
                .shadow(color: Color(hex: 0x0F172A).opacity(0.09), radius: 28, y: 10)
                .shadow(color: butter.opacity(0.14), radius: 14, y: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.colorScheme, .light)
        .task(id: previews.map(\.id)) {
            datesTileIndex = 0
            guard shouldRotate else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.6))
                guard !Task.isCancelled else { break }
                if showImportantDatesList || showImportantDatesAdd || showWishlist { continue }
                withAnimation(.easeInOut(duration: 0.35)) {
                    datesTileIndex = (datesTileIndex + 1) % previews.count
                }
            }
        }
    }

    private var loveNotesTile: some View {
        let tileKind = store.loveNotesTileKind
        let isActive = tileKind == .incomingActive

        return ZStack(alignment: .bottomTrailing) {
            Button(action: { showLoveNotesPage = true }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Love Notes")
                            .font(.system(size: 11, weight: .light))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white.opacity(0.72))
                        Spacer()
                        if tileKind == .incomingActive {
                            Text("\(store.incomingUnreadLoveNotes.count)")
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.28))
                                )
                        }
                        if tileKind == .outgoingOnly {
                            Text("\(store.outgoingLoveNotes.count) sent")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.white.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.36))
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.42), lineWidth: 0.5)
                                        )
                                )
                        }
                    }

                    Text(tileBodyText)
                        .font(.system(size: 16, weight: tileKind == .incomingActive ? .bold : .medium))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if tileKind != .empty {
                        Text(tileSubtitleText)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.82))
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    showLoveNoteCompose = true
                }
            }) {
                matteIconLabel(systemName: "pencil", label: "Leave a love note", light: true)
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isActive
                            ? [
                                Color(hex: 0xF490B8).opacity(0.98),
                                Color(hex: 0xF078A8).opacity(0.94),
                                Color(hex: 0xE86898).opacity(0.96),
                              ]
                            : [
                                BeSideColor.loveNotePink.opacity(0.9),
                                Color(hex: 0xF0A8C0).opacity(0.85),
                                BeSideColor.loveNotePinkDeep.opacity(0.88),
                              ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.22), .clear],
                                center: UnitPoint(x: 0.2, y: 0),
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(isActive ? 0.5 : 0.4), lineWidth: 0.8)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color(hex: 0xC8648C).opacity(isActive ? 0.28 : 0.2),
            radius: isActive ? 14 : 13,
            y: 5
        )
        .accessibilityLabel("Open love notes")
        .accessibilityIdentifier("us.tile.lovenotes")
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

    private var sharedMemoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Button {
                    dismissTips()
                    showSharedMemoriesPage = true
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Shared Memories")
                            .font(.system(size: 12, weight: .light))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundStyle(ink.opacity(0.56))
                        Text("Cherish the moments that matter to both of you.")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(ink.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Shared Memories gallery")
                .accessibilityIdentifier("us.memories")
            }

            if store.sharedMemories.isEmpty {
                Text("Add your first shared moment")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            } else {
                memoryCarousel
                    .padding(.top, 12)

                if store.sharedMemories.count > 1 {
                    memoryDots
                        .padding(.top, 12)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.42))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                }
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.white.opacity(0.6))
                .frame(height: 1)
                .padding(.horizontal, 1)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismissTips()
                withAnimation(.easeOut(duration: 0.2)) {
                    editingMemory = nil
                    showSharedMemoryAdd = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink.opacity(0.56))
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.44))
                            .overlay {
                                Circle().stroke(ink.opacity(0.15), lineWidth: 1.5)
                            }
                            .shadow(color: ink.opacity(0.06), radius: 6, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel("Add a memory")
            .accessibilityIdentifier("us.memories.add")
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var memoryCarousel: some View {
        let cardWidth: CGFloat = 168
        let gap: CGFloat = 12
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: gap) {
                ForEach(Array(store.sharedMemories.enumerated()), id: \.element.id) { index, memory in
                    memoryCarouselCard(memory, isActive: index == memoryCarouselIndex)
                        .frame(width: cardWidth)
                        .id(memory.id)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.85)
                                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: Binding(
            get: {
                store.sharedMemories.indices.contains(memoryCarouselIndex)
                    ? store.sharedMemories[memoryCarouselIndex].id
                    : nil
            },
            set: { newID in
                if let newID, let idx = store.sharedMemories.firstIndex(where: { $0.id == newID }) {
                    memoryCarouselIndex = idx
                }
            }
        ))
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in memoryCarouselDragged = true }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        memoryCarouselDragged = false
                    }
                }
        )
        .accessibilityIdentifier("us.memories.carousel")
    }

    private func memoryCarouselCard(_ memory: UsSharedMemory, isActive: Bool) -> some View {
        let hasPhoto = UsSharedMemories.hasPhoto(memory)
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                SharedMemoryPhotoView(memory: memory)
                .frame(height: 118)
                .frame(maxWidth: .infinity)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !memoryCarouselDragged else { return }
                    dismissTips()
                    openMemoryFeed(startingAt: memory.id)
                }

                ShareLink(item: UsSharedMemories.shareText(for: memory)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.56))
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.72))
                                .overlay {
                                    Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
                                }
                                .shadow(color: ink.opacity(0.1), radius: 6, y: 2)
                        }
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel("Share \(memory.title)")
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    if hasPhoto {
                        Text(memory.mood)
                            .font(.system(size: 13))
                            .padding(.top, 1)
                    }
                    Text(memory.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(ink.opacity(0.88))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(UsSharedMemories.shortDateLabel(memory.dateTime))
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(ink.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 68, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !memoryCarouselDragged else { return }
                dismissTips()
                openMemoryFeed(startingAt: memory.id)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isActive ? Color.white.opacity(0.9) : Color.white.opacity(0.55),
                    lineWidth: isActive ? 1.2 : 0.8
                )
        }
        .shadow(
            color: Color.black.opacity(isActive ? 0.1 : 0.05),
            radius: isActive ? 14 : 8,
            y: isActive ? 6 : 3
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Open memory \(memory.title)")
        .accessibilityIdentifier("us.memories.card.\(memory.id)")
        .accessibilityAction {
            openMemoryFeed(startingAt: memory.id)
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
        if memoryCarouselIndex >= store.sharedMemories.count {
            memoryCarouselIndex = max(0, store.sharedMemories.count - 1)
        }
    }

    private var memoryDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(store.sharedMemories.enumerated()), id: \.element.id) { index, _ in
                let active = index == memoryCarouselIndex
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        memoryCarouselIndex = index
                    }
                } label: {
                    Capsule()
                        .fill(active ? BeSideColor.navyStart : Color.clear)
                        .frame(width: active ? 16 : 6, height: 6)
                        .overlay {
                            Capsule()
                                .stroke(
                                    active ? BeSideColor.navyStart : BeSideColor.navyStart.opacity(0.45),
                                    lineWidth: 1.5
                                )
                        }
                        .opacity(active ? 1 : 0.55)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Memory \(index + 1)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func matteIconLabel(systemName: String, label: String, light: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(light ? Color.white.opacity(0.9) : ink.opacity(0.56))
            .frame(width: 38, height: 38)
            .background {
                Circle()
                    .fill(Color.white.opacity(light ? 0.28 : 0.44))
                    .overlay {
                        Circle().stroke(
                            light ? Color.white.opacity(0.35) : ink.opacity(0.15),
                            lineWidth: 1.5
                        )
                    }
            }
            .accessibilityLabel(label)
    }
}

#Preview {
    UsView(store: MeSessionStore())
}
