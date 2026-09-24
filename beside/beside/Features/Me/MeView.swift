import SwiftUI

struct MeView: View {
    @Bindable var store: MeSessionStore
    @State private var showPartnerResponseHistory = false
    @State private var scrollTarget: String?
    @State private var layout = BeSideMetrics.MeLayout.standard
    @FocusState private var isCustomWishFocused: Bool

    private enum ScrollID {
        static let moodActions = "me.moodActions"
        static let share = "me.share"
        static let customWish = "wish.custom.block"
        static let week = "me.week"
        static let weekBottom = "me.weekBottom"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ambientBackground

                ScrollView(.vertical, showsIndicators: false) {
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
                                Task { await store.share() }
                            }
                            .padding(.bottom, 22)
                        }
                        .id(ScrollID.moodActions)
                    }

                    if store.selectedMood != nil {
                        Color.clear
                            .frame(height: layout.tabBarClearance)
                            .id(ScrollID.share)
                    }

                    WeekMoodStrip(
                        buckets: store.weekBuckets(),
                        expandedDayKey: store.expandedDayKey,
                        onTapDay: { bucket in
                            dismissKeyboard()
                            store.toggleDay(bucket.id, hasEntries: !bucket.entries.isEmpty)
                        }
                    )
                    .id(ScrollID.week)
                    .padding(.bottom, 28)

                    Color.clear
                        .frame(height: store.expandedDayKey == nil ? 8 : 24)
                        .id(ScrollID.weekBottom)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, layout.pageInset)
                .padding(.bottom, layout.tabBarClearance)
                .frame(maxWidth: layout.contentMaxWidth ?? .infinity)
                .frame(maxWidth: .infinity)
                .scrollTargetLayout()
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollPosition(id: $scrollTarget, anchor: .bottom)
            .onChange(of: store.selectedMoodID) { _, moodID in
                dismissKeyboard()
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
                guard focused else { return }
                scrollCustomWishIntoView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: BeSideMetrics.MeLayout.self) { proxy in
            BeSideMetrics.MeLayout.resolve(
                width: proxy.size.width,
                height: proxy.size.height,
                safeBottom: proxy.safeAreaInsets.bottom
            )
        } action: { newLayout in
            layout = newLayout
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
        } // NavigationStack
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

    private func scrollCustomWishIntoView() {
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(120))
            scrollTarget = nil
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.35)) {
                scrollTarget = ScrollID.customWish
            }
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollTarget = ScrollID.customWish
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
            // Second nudge so the day modal sits clearly above the tab bar.
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollTarget = ScrollID.weekBottom
            }
        }
    }

    private func dismissKeyboard() {
        isCustomWishFocused = false
    }
}

private extension BeSideMetrics.MeLayout {
    var compactSectionPadding: CGFloat { gapAfterSpheres + 2 }
}
