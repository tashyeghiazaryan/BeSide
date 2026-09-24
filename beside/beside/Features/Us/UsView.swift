import SwiftUI

/// Us home shell — Figma Make `UsScreen` first viewport (feature flows stubbed).
struct UsView: View {
    @Bindable var store: MeSessionStore
    @State private var dailyTipID: DailyTaskID?

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

    private func dismissDailyTip() {
        guard dailyTipID != nil else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            dailyTipID = nil
        }
    }

    private var dailyTipDismissOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: dismissDailyTip)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            BeSideBackground.softCanvas
                .ignoresSafeArea()
                .onTapGesture(perform: dismissDailyTip)

            usAmbient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)

                    heroSection
                        .padding(.bottom, 16)
                        .zIndex(dailyTipID == nil ? 0 : 50)

                    entryTiles
                        .padding(.bottom, 24)
                        .zIndex(0)
                        .overlay { if dailyTipID != nil { dailyTipDismissOverlay } }

                    sharedMemoriesStub
                        .padding(.bottom, 28)
                        .zIndex(0)
                        .overlay { if dailyTipID != nil { dailyTipDismissOverlay } }

                    Color.clear.frame(height: BeSideMetrics.tabBarClearance)
                        .overlay { if dailyTipID != nil { dailyTipDismissOverlay } }
                }
                .padding(.horizontal, BeSideMetrics.pageInset)
            }
            .scrollClipDisabled()

            notificationsBell
                .padding(.leading, 14)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AppTab.us.screenIdentifier)
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
            dismissDailyTip()
        } label: {
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications")
        .accessibilityIdentifier("us.notifications")
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("\(store.displayName) & \(store.partnerDisplayName)")
                    .font(.system(size: 22, weight: .ultraLight))
                    .tracking(0.6)
                    .foregroundStyle(ink.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                    .accessibilityIdentifier("us.couple.names")

                Text(store.timeTogetherPhrase)
                    .font(.system(size: 13, weight: .light))
                    .tracking(0.2)
                    .foregroundStyle(ink.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)
                    .accessibilityIdentifier("us.time.together")

                HStack(spacing: -20) {
                    avatarBubble(name: store.displayName)
                    avatarBubble(name: store.partnerDisplayName)
                }
                .padding(.bottom, 14)
                .accessibilityIdentifier("us.avatars")
            }
            .frame(maxWidth: .infinity)
            .overlay { if dailyTipID != nil { dailyTipDismissOverlay } }

            // Chips stay above dismiss overlays so toggle / re-tap works.
            dailyProgress
                .padding(.bottom, 14)
                .zIndex(dailyTipID == nil ? 0 : 40)

            longTermBar
                .zIndex(0)
                .overlay { if dailyTipID != nil { dailyTipDismissOverlay } }
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
            .font(.system(size: 22, weight: .light))
            .foregroundStyle(ink.opacity(0.72))
            .frame(width: 68, height: 68)
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
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(ink.opacity(0.22))
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dailyTipID = dailyTipID == id ? nil : id
                    }
                } label: {
                    HStack(spacing: 4) {
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
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x34D399).opacity(0.85))
                            }
                        }
                        .frame(width: 16, height: 16)

                        Text(id.short)
                            .font(.system(size: 10, weight: dailyTipID == id ? .medium : .light))
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
            if dailyTipID != nil { dailyTipDismissOverlay }
        }
        .overlay(alignment: .top) {
            if let tipID = dailyTipID, let tip = tasks.first(where: { $0.0 == tipID }) {
                let bothDone = tip.1 && tip.2
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily · \(bothDone ? "Done" : "To do")")
                        .font(.system(size: 10, weight: .regular))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(ink.opacity(0.4))
                    Text(tip.0.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ink.opacity(0.82))
                    Text(tip.0.why)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(ink.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: 264, alignment: .leading)
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

        return VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.usLevelName)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(ink.opacity(0.68))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("Streak · \(streak) \(streak == 1 ? "day" : "days")")
                    .font(.system(size: 11, weight: .semibold))
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
            .frame(height: 8)
            .accessibilityLabel(
                "Level progress \(store.usLongTermPoints) of \(goal > 0 ? "\(goal)" : "max") points"
            )
            .accessibilityIdentifier("us.level.bar")

            HStack {
                Text("\(store.usLongTermPoints)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.52))
                    .monospacedDigit()
                Spacer()
                Text(goal > 0 ? "\(goal)" : "—")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.38))
                    .monospacedDigit()
            }
        }
        .accessibilityIdentifier("us.level")
    }

    private var entryTiles: some View {
        HStack(alignment: .top, spacing: 10) {
            importantDatesTile
            loveNotesTile
        }
        .accessibilityIdentifier("us.entry.tiles")
    }

    private var importantDatesTile: some View {
        Button(action: {}) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Important Dates")
                        .font(.system(size: 9, weight: .light))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(hex: 0x8B7355).opacity(0.55))

                    Text(store.usNearestImportantDateTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0x3A3326).opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(shortDate(store.usNearestImportantDate))
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color(hex: 0x3A3326).opacity(0.55))

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
                .padding(12)
                .padding(.bottom, 36)
                .padding(.trailing, 48)

                Text(countdownLabel(store.usNearestImportantDaysUntil))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x8B7355))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.45))
                            .overlay {
                                Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.8)
                            }
                    }
                    .padding(12)

                HStack(spacing: 6) {
                    matteIconButton(systemName: "gift", label: "Wishlist")
                    matteIconButton(systemName: "plus", label: "Open calendar to add a date")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(8)
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Color(hex: 0xFFF8E8).opacity(0.42),
                                        Color(hex: 0xFFEDA8).opacity(0.18),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open important dates list")
        .accessibilityIdentifier("us.tile.dates")
    }

    private var loveNotesTile: some View {
        Button(action: {}) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Love Notes")
                        .font(.system(size: 9, weight: .light))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text("Say something sweet —\nit only takes a moment")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
                .padding(12)
                .padding(.bottom, 40)

                matteIconButton(systemName: "pencil", label: "Leave a love note", light: true)
                    .padding(8)
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0xF9A8D4).opacity(0.85),
                                Color(hex: 0xEC4899).opacity(0.75),
                                Color(hex: 0xDB2777).opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: 0xEC4899).opacity(0.2), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open love notes")
        .accessibilityIdentifier("us.tile.lovenotes")
    }

    private var sharedMemoriesStub: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.56))
                    VStack(alignment: .leading, spacing: 2) {
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
                    Spacer(minLength: 8)
                }
                .padding(.trailing, 28)

                Text("Evening on the rooftop")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ink.opacity(0.72))
                    .padding(.top, 8)
                Text("You two enjoyed the sunset together")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .padding(.top, 4)
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
            .overlay(alignment: .topTrailing) {
                matteIconButton(systemName: "plus", label: "Add a memory")
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Shared Memories gallery")
        .accessibilityIdentifier("us.memories")
    }

    private func matteIconButton(systemName: String, label: String, light: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(light ? Color.white.opacity(0.9) : ink.opacity(0.56))
            .frame(width: 36, height: 36)
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
            .allowsHitTesting(false)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    private func countdownLabel(_ days: Int) -> String {
        if days <= 0 { return "Today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }
}

#Preview {
    UsView(store: MeSessionStore())
}
