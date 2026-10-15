import SwiftUI

/// Full-screen Important Dates detail — week strip, featured event, Little Things.
struct DatesDetailPage: View {
    @Bindable var store: MeSessionStore
    let onClose: () -> Void
    var onAddLittleThing: ((Date) -> Void)? = nil

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private var ink: Color { BeSideColor.navyStart }
    private let calendar = Calendar.current

    private var weekDays: [Date] {
        UsImportantDates.weekDays(containing: selectedDay, calendar: calendar)
    }

    private var eventsOnSelectedDay: [UsImportantDate] {
        UsImportantDates.dates(on: selectedDay, from: store.importantDates, calendar: calendar)
    }

    private var featuredEvent: UsImportantDate? {
        eventsOnSelectedDay.first
    }

    /// Little Things for the selected calendar day only — not linked to Important Dates events.
    private var asksForSelectedDay: [UsPartnerAsk] {
        UsPartnerAsk.asks(on: selectedDay, from: store.partnerAsks, calendar: calendar)
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .hidesFloatingTabBar()
        .transition(.move(edge: .trailing))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.detail.page")
        .onAppear {
            // Always open on today — do not jump to the nearest Important Date.
            selectedDay = calendar.startOfDay(for: Date())
            if store.partnerAsks.isEmpty {
                store.partnerAsks = UsPartnerAsk.demoSeed()
            }
        }
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
                VStack(alignment: .leading, spacing: 18) {
                    weekStrip
                    featuredCard
                    asksSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Header

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
            .accessibilityIdentifier("us.dates.detail.back")

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.headerDayFormatter.string(from: selectedDay))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.88))
                Text(Self.headerMonthFormatter.string(from: selectedDay))
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(UsImportantDates.monthYearLabel(selectedDay))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.55))
                Spacer(minLength: 0)
                Button {
                    shiftWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous week")

                Button {
                    shiftWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next week")
            }

            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let selected = calendar.isDate(day, inSameDayAs: selectedDay)
                    let isToday = calendar.isDateInToday(day)
                    let hasEvent = !UsImportantDates.dates(on: day, from: store.importantDates, calendar: calendar).isEmpty
                    let hasAsk = !UsPartnerAsk.asks(on: day, from: store.partnerAsks, calendar: calendar).isEmpty
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selectedDay = calendar.startOfDay(for: day)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(Self.weekdayFormatter.string(from: day).uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(0.4)
                                .foregroundStyle(selected ? Color.white.opacity(0.85) : ink.opacity(0.38))

                            Text("\(calendar.component(.day, from: day))")
                                .font(.system(size: 16, weight: selected || isToday ? .semibold : .medium, design: .rounded))
                                .foregroundStyle(
                                    selected
                                        ? Color.white.opacity(0.95)
                                        : isToday
                                            ? BeSideColor.navyStart.opacity(0.88)
                                            : ink.opacity(0.72)
                                )
                                .monospacedDigit()

                            HStack(spacing: 3) {
                                Circle()
                                    .fill(hasEvent ? (selected ? Color.white.opacity(0.9) : BeSideColor.navyStart.opacity(0.4)) : Color.clear)
                                    .frame(width: 4, height: 4)
                                Circle()
                                    .fill(hasAsk ? (selected ? Color.white.opacity(0.65) : Color(hex: 0xE8BEC9).opacity(0.85)) : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(BeSideColor.navyFill)
                                    .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 8, y: 3)
                            } else if isToday {
                                Capsule()
                                    .stroke(BeSideColor.navyStart.opacity(0.4), lineWidth: 1.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        isToday
                            ? "Today, \(Self.a11yDayFormatter.string(from: day))"
                            : Self.a11yDayFormatter.string(from: day)
                    )
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    }
            }
        }
        .accessibilityIdentifier("us.dates.detail.week")
    }

    private func shiftWeek(by weeks: Int) {
        guard let next = calendar.date(byAdding: .day, value: weeks * 7, to: selectedDay) else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            selectedDay = calendar.startOfDay(for: next)
        }
    }

    // MARK: - Featured tip

    private var featuredCard: some View {
        let corner = BeSideMetrics.glassCornerLarge
        return featuredTipContent
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .beSideGlassChrome(cornerRadius: corner, style: .widgetFrosted)
            .overlay {
                featuredWarmWash
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: 0xE8BEC9).opacity(0.75),
                                Color.white.opacity(0.55),
                                Color(hex: 0xC4B5FD).opacity(0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                    .allowsHitTesting(false)
            }
            .accessibilityIdentifier("us.dates.detail.hero")
    }

    private var featuredWarmWash: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFCE7F3).opacity(0.55),
                    Color(hex: 0xE8BEC9).opacity(0.28),
                    Color(hex: 0xDDD6FE).opacity(0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    Color(hex: 0xFBCFE8).opacity(0.45),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 180
            )
        }
    }

    /// How-to tip for Little Things; day’s Important Date (if any) sits underneath.
    private var featuredTipContent: some View {
        let tip =
            "Ask \(store.partnerDisplayName) for small favors for this day. Tap + to add (up to 5), then check them off when done."

        return VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(ink.opacity(0.4))

            Text(tip)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(ink.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            if let event = featuredEvent {
                featuredEventChip(event)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("How it works. \(tip)")
    }

    private func featuredEventChip(_ event: UsImportantDate) -> some View {
        let days = UsImportantDates.daysUntil(event.date)
        let dateLabel = UsImportantDates.shortDate(event.date)

        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.45))
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.82))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(UsImportantDates.countdownLabel(days))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(detailBadgeInk(days: days))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background { detailBadgeChrome(days: days) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                }
        }
        .padding(.top, 2)
        .accessibilityLabel("\(event.title), \(dateLabel), \(UsImportantDates.countdownLabel(days))")
    }

    // MARK: - Little Things

    private var asksForMe: [UsPartnerAsk] {
        asksForSelectedDay.filter { $0.author == .partner }
    }

    private var asksForPartner: [UsPartnerAsk] {
        asksForSelectedDay.filter { $0.author == .me }
    }

    private var asksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Little Things")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.82))

                Spacer(minLength: 0)

                if let onAddLittleThing {
                    Button {
                        onAddLittleThing(selectedDay)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .frame(width: 32, height: 32)
                            .background { Circle().fill(BeSideColor.navyFill) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add a little thing")
                    .accessibilityIdentifier("us.dates.detail.asks.add")
                }
            }

            askGroup(
                title: "For you",
                subtitle: "\(store.partnerDisplayName) asked",
                asks: asksForMe,
                empty: "Nothing from \(store.partnerDisplayName) today.",
                accent: Color(hex: 0xE8BEC9)
            )

            askGroup(
                title: "For \(store.partnerDisplayName)",
                subtitle: "You asked",
                asks: asksForPartner,
                empty: "Ask \(store.partnerDisplayName) for something small.",
                accent: BeSideColor.navyStart.opacity(0.35)
            )
        }
        .accessibilityIdentifier("us.dates.detail.asks")
    }

    private func askGroup(
        title: String,
        subtitle: String,
        asks: [UsPartnerAsk],
        empty: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(accent)
                    .frame(width: 3, height: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.78))
                    Text(subtitle)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(ink.opacity(0.4))
                }
                Spacer(minLength: 0)
                if !asks.isEmpty {
                    Text("\(asks.filter { !$0.isDone }.count)/\(asks.count)")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                        .foregroundStyle(ink.opacity(0.38))
                }
            }

            if asks.isEmpty {
                Text(empty)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(ink.opacity(0.38))
                    .padding(.vertical, 6)
                    .padding(.leading, 11)
            } else {
                VStack(spacing: 8) {
                    ForEach(asks) { ask in
                        askRow(ask, accent: accent)
                    }
                }
            }
        }
    }

    private func askRow(_ ask: UsPartnerAsk, accent: Color) -> some View {
        let fromMe = ask.author == .me
        let status: String = {
            if ask.isDone {
                return fromMe
                    ? "\(store.partnerDisplayName) marked done"
                    : "You marked done"
            }
            return fromMe ? "Waiting on them" : "Your turn"
        }()

        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                store.togglePartnerAskDone(id: ask.id)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            ask.isDone ? BeSideColor.navyStart.opacity(0.35) : ink.opacity(0.22),
                            lineWidth: 1.5
                        )
                        .background {
                            Circle().fill(
                                ask.isDone
                                    ? BeSideColor.navyStart.opacity(0.12)
                                    : Color.white.opacity(0.55)
                            )
                        }
                    if ask.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.75))
                    }
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(ask.body)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ink.opacity(ask.isDone ? 0.38 : 0.84))
                        .strikethrough(ask.isDone, color: ink.opacity(0.35))
                        .lineLimit(2)
                    Text(status)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(ink.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(ask.isDone ? 0.5 : 0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                ask.isDone ? ink.opacity(0.08) : accent.opacity(0.45),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: BeSideColor.navyStart.opacity(ask.isDone ? 0.02 : 0.06), radius: 10, y: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ask.body). \(status)")
        .accessibilityHint(ask.isDone ? "Double tap to mark as open again" : "Double tap to mark as done")
        .accessibilityIdentifier("us.dates.detail.ask.\(ask.id)")
        .accessibilityAddTraits(ask.isDone ? .isSelected : [])
    }

    // MARK: - Countdown badge (Figma Make Dates widget)

    private func detailBadgeInk(days: Int) -> Color {
        if days <= 0 { return Color.white.opacity(0.95) }
        return BeSideColor.navyStart.opacity(0.46)
    }

    @ViewBuilder
    private func detailBadgeChrome(days: Int) -> some View {
        if days <= 0 {
            Capsule().fill(BeSideColor.navyFill)
        } else {
            Capsule()
                .fill(Color.white.opacity(0.55))
                .overlay {
                    Capsule()
                        .stroke(BeSideColor.navyStart.opacity(0.22), lineWidth: 1)
                }
        }
    }

    // MARK: - Formatters

    private static let headerDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMMM"
        return f
    }()

    private static let headerMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE"
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f
    }()

    private static let a11yDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateStyle = .full
        return f
    }()
}
