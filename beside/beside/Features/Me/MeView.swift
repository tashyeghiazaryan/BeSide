import SwiftUI
import UIKit

struct MeView: View {
    @Bindable var store: MeSessionStore
    @State private var showPartnerResponseHistory = false
    @State private var scrollTarget: String?
    @State private var layout = BeSideMetrics.MeLayout.standard
    /// Keyboard overlays the page; this only adds scroll room so the field can lift above it.
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isCustomWishFocused: Bool

    private enum ScrollID {
        static let moodActions = "me.moodActions"
        static let share = "me.share"
        static let week = "me.week"
        static let weekBottom = "me.weekBottom"
    }

    private var isWeekDetailOpen: Bool { store.expandedDayKey != nil }

    private func dismissWeekDetail() {
        guard isWeekDetailOpen else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            store.expandedDayKey = nil
        }
    }

    private var weekDetailDismissOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: dismissWeekDetail)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ambientBackground
                    .onTapGesture(perform: dismissWeekDetail)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: layout.topSpacer)

                            Text(greeting)
                                .font(.system(size: layout.greetingSize, weight: .light))
                                .foregroundStyle(BeSideColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 6)

                            Text("How are you feeling?")
                                .font(.system(size: layout.heroTitleSize, weight: .ultraLight))
                                .foregroundStyle(BeSideColor.textPrimary)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.85)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, layout.compactSectionPadding)

                            Text("Your current mood")
                                .font(.system(size: layout.sectionLabelSize, weight: .light))
                                .tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundStyle(BeSideColor.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 8)

                            CurrentMoodPanel(
                                shared: store.currentSharedMood,
                                partnerName: store.partnerDisplayName,
                                onTap: {
                                    dismissKeyboard()
                                    dismissWeekDetail()
                                    showPartnerResponseHistory = true
                                }
                            )
                            .padding(.bottom, layout.gapAfterCurrentMood)

                            hintText
                                .padding(.bottom, 10)

                            moodSpheresPanel
                                .padding(.bottom, layout.gapAfterSpheres)

                            if let mood = store.selectedMood {
                                VStack(spacing: 0) {
                                    if store.sharePhase != .sent {
                                        WishListView(
                                            mood: mood,
                                            wishes: store.wishesForSelection,
                                            selectedWish: store.selectedWish,
                                            customWish: Binding(
                                                get: { store.customWishText },
                                                set: { store.updateCustomWish($0) }
                                            ),
                                            fieldError: store.activeAlert,
                                            isCustomFieldFocused: $isCustomWishFocused,
                                            onSelect: { wish in
                                                store.selectWish(wish)
                                            }
                                        )
                                        .padding(.bottom, 12)
                                    }

                                    ShareMoodButton(
                                        mood: mood,
                                        phase: store.sharePhase,
                                        enabled: store.canAttemptShare || store.sharePhase != .idle,
                                        looksReady: store.canShare || store.sharePhase != .idle
                                    ) {
                                        dismissKeyboard()
                                        dismissWeekDetail()
                                        Task { await store.share() }
                                    }
                                    .id(ScrollID.share)
                                    .padding(.bottom, 22)
                                }
                                .id(ScrollID.moodActions)
                            }
                        }
                        .overlay {
                            // Tap anywhere above the week strip closes the day detail.
                            if isWeekDetailOpen { weekDetailDismissOverlay }
                        }

                        // Immediately under Share with partner (no spacer).
                        WeekMoodStrip(
                            buckets: store.weekBuckets(),
                            expandedDayKey: store.expandedDayKey,
                            onTapDay: { bucket in
                                dismissKeyboard()
                                store.toggleDay(bucket.id, hasEntries: !bucket.entries.isEmpty)
                            },
                            onTapOutsideDetail: dismissWeekDetail
                        )
                        .id(ScrollID.week)
                        .padding(.bottom, 28)
                        .zIndex(isWeekDetailOpen ? 20 : 0)

                        Color.clear
                            .frame(height: store.expandedDayKey == nil ? 8 : 24)
                            .id(ScrollID.weekBottom)
                            .allowsHitTesting(false)
                    }
                    .padding(.horizontal, layout.pageInset)
                    .padding(.bottom, layout.tabBarClearance + keyboardHeight)
                    .frame(maxWidth: layout.contentMaxWidth ?? .infinity)
                    .frame(maxWidth: .infinity)
                    .scrollTargetLayout()
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard)
                // Share with partner sits just above the overlay keyboard.
                .scrollPosition(id: $scrollTarget, anchor: shareAboveKeyboardAnchor)
                .onChange(of: store.selectedMoodID) { _, moodID in
                    dismissKeyboard()
                    dismissWeekDetail()
                    guard moodID != nil else { return }
                    scrollMoodActionsIntoView()
                }
                .onChange(of: store.activeAlert?.id) { _, alertID in
                    guard alertID != nil else { return }
                    scrollMoodActionsIntoView()
                }
                .onChange(of: store.expandedDayKey) { _, key in
                    guard key != nil else { return }
                    scrollWeekDropdownIntoView()
                }
                .onChange(of: isCustomWishFocused) { _, focused in
                    if focused { dismissWeekDetail() }
                    guard focused else { return }
                    scrollShareAboveKeyboard()
                }
                .onChange(of: keyboardHeight) { _, height in
                    guard height > 0, isCustomWishFocused else { return }
                    scrollShareAboveKeyboard()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            .onGeometryChange(for: BeSideMetrics.MeLayout.self) { proxy in
                BeSideMetrics.MeLayout.resolve(
                    width: proxy.size.width,
                    height: max(proxy.size.height, UIScreen.main.bounds.height),
                    safeBottom: proxy.safeAreaInsets.bottom
                )
            } action: { newLayout in
                guard keyboardHeight == 0 else { return }
                layout = newLayout
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            ) { note in
                updateKeyboardHeight(from: note)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    keyboardHeight = 0
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                        .fontWeight(.semibold)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AppTab.me.screenIdentifier)
            .sheet(isPresented: $showPartnerResponseHistory) {
                PartnerResponseHistorySheet(
                    entries: store.partnerResponseHistory,
                    youName: store.displayName,
                    partnerName: store.partnerDisplayName
                )
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private var moodSpheresPanel: some View {
        GlassPanel(cornerRadius: BeSideMetrics.glassCornerLarge) {
            VStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            let mood = MoodCatalog.all[row * 3 + col]
                            Button {
                                dismissKeyboard()
                                dismissWeekDetail()
                                store.selectMood(mood)
                            } label: {
                                MoodSphereView(
                                    moodID: mood.id,
                                    name: mood.name,
                                    color: mood.color,
                                    gradientColors: mood.gradientColors,
                                    icon: mood.icon,
                                    isSelected: store.selectedMoodID == mood.id,
                                    hasSelection: store.selectedMoodID != nil,
                                    size: layout.sphereSize
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .animation(.easeInOut(duration: 0.3), value: store.selectedMoodID)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = store.displayName
        switch hour {
        case 0..<12: return "Good morning, \(name) ✨"
        case 12..<17: return "Good afternoon, \(name) ✨"
        case 17..<21: return "Good evening, \(name) ✨"
        default: return "Good night, \(name) ✨"
        }
    }

    @ViewBuilder
    private var hintText: some View {
        let text: String = {
            if store.selectedMood != nil {
                return "Tell your partner how you feel today."
            }
            if store.currentSharedMood == nil {
                return "Tap to show how you're feeling."
            }
            return "Your partner would love to know how you're feeling"
        }()

        Text(text)
            .font(.system(size: layout.captionSize, weight: .light))
            .foregroundStyle(BeSideColor.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var ambientBackground: some View {
        ZStack {
            BeSideBackground.softCanvas
                .ignoresSafeArea()

            if let mood = store.selectedMood {
                BeSideBackground.moodAmbient(
                    color: mood.color,
                    gradientColors: mood.gradientColors
                )
                .id(mood.id)
                .transition(.opacity)
                .ignoresSafeArea()
            } else {
                BeSideBackground.defaultAmbientBlobs()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.85), value: store.selectedMoodID)
    }

    /// Viewport Y for Share so it sits just above the overlay keyboard.
    private var shareAboveKeyboardAnchor: UnitPoint {
        let screen = UIScreen.main.bounds.height
        guard keyboardHeight > 80, screen > 0 else {
            return UnitPoint(x: 0.5, y: 0.88)
        }
        let y = max(0.4, min(0.82, (screen - keyboardHeight - 20) / screen))
        return UnitPoint(x: 0.5, y: y)
    }

    private func scrollMoodActionsIntoView() {
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(120))

            scrollTarget = nil
            await Task.yield()

            withAnimation(.easeInOut(duration: 0.5)) {
                scrollTarget = ScrollID.share
            }

            try? await Task.sleep(for: .milliseconds(350))
            if scrollTarget == ScrollID.share {
                scrollTarget = nil
                await Task.yield()
                withAnimation(.easeInOut(duration: 0.4)) {
                    scrollTarget = ScrollID.share
                }
            }
        }
    }

    private func scrollShareAboveKeyboard() {
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(80))
            scrollTarget = nil
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.35)) {
                scrollTarget = ScrollID.share
            }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeInOut(duration: 0.28)) {
                scrollTarget = ScrollID.share
            }
        }
    }

    private func scrollWeekDropdownIntoView() {
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(80))
            scrollTarget = nil
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.4)) {
                scrollTarget = ScrollID.weekBottom
            }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollTarget = ScrollID.weekBottom
            }
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            keyboardHeight = 0
            return
        }
        let screenHeight = UIScreen.main.bounds.height
        let overlap = max(0, screenHeight - frame.origin.y)
        // Ignore accessory-only frames.
        let next = overlap > 80 ? overlap : 0
        guard next != keyboardHeight else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardHeight = next
        }
    }

    private func dismissKeyboard() {
        isCustomWishFocused = false
    }
}

private extension BeSideMetrics.MeLayout {
    var compactSectionPadding: CGFloat { gapAfterSpheres + 2 }
}
