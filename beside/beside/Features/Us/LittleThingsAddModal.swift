import SwiftUI
import UIKit

/// Compact compose sheet for a new Little Thing — week strip on top, today selected by default.
struct LittleThingsAddModal: View {
    let initialDay: Date
    let onClose: () -> Void
    /// body, selected day
    let onAdd: (String, Date) -> Bool
    /// How many asks from me exist on a given day (done included; for the 5/day cap).
    var fromMeCount: (Date) -> Int = { _ in 0 }

    @State private var selectedDay: Date
    @State private var bodyText = ""
    @State private var showSuccess = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var fieldFocused: Bool

    private var ink: Color { BeSideColor.navyStart }
    private let rose = Color(hex: 0xE8BEC9)
    private let calendar = Calendar.current
    private var maxPerDay: Int { UsPartnerAsk.maxFromMePerDay }

    private var usedSlots: Int { fromMeCount(selectedDay) }
    private var atLimit: Bool { usedSlots >= maxPerDay }

    private var canCommit: Bool {
        !atLimit && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var weekDays: [Date] {
        UsImportantDates.weekDays(containing: selectedDay, calendar: calendar)
    }

    init(
        day: Date = Date(),
        onClose: @escaping () -> Void,
        onAdd: @escaping (String, Date) -> Bool,
        fromMeCount: @escaping (Date) -> Int = { _ in 0 }
    ) {
        let start = Calendar.current.startOfDay(for: day)
        self.initialDay = start
        self.onClose = onClose
        self.onAdd = onAdd
        self.fromMeCount = fromMeCount
        _selectedDay = State(initialValue: start)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                scrim
                    .onTapGesture {
                        if fieldFocused {
                            fieldFocused = false
                        } else {
                            onClose()
                        }
                    }

                VStack(spacing: 0) {
                    Spacer(minLength: 16)
                    card
                        .padding(.horizontal, 20)
                    if keyboardHeight > 80 {
                        Color.clear
                            .frame(height: keyboardHeight + 10)
                            .allowsHitTesting(false)
                    } else {
                        Spacer(minLength: 16)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { fieldFocused = false }
                        .fontWeight(.semibold)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            selectedDay = Calendar.current.startOfDay(for: initialDay)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                fieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .accessibilityIdentifier("us.asks.add.modal")
    }

    private var scrim: some View {
        ZStack {
            Color(hex: 0x1A1A2E).opacity(0.28)
            RadialGradient(
                colors: [rose.opacity(0.22), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ask them")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.9))
                    Text(UsImportantDates.shortDate(selectedDay))
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(ink.opacity(0.42))
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.72))
                                .overlay { Circle().stroke(ink.opacity(0.12), lineWidth: 1) }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityIdentifier("us.asks.add.close")
            }

            weekStrip
                .padding(.top, 16)

            HStack {
                Text("What should they do?")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ink.opacity(0.45))
                Spacer(minLength: 0)
                Text("\(usedSlots)/\(maxPerDay)")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(atLimit ? BeSideColor.raspberry.opacity(0.85) : ink.opacity(0.4))
                    .accessibilityIdentifier("us.asks.add.limit")
            }
            .padding(.top, 16)

            if atLimit {
                Text("Max \(maxPerDay) asks for this day.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(BeSideColor.raspberry.opacity(0.8))
                    .padding(.top, 6)
            }

            TextField("e.g. Make me a coffee", text: $bodyText)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(ink.opacity(0.85))
                .focused($fieldFocused)
                .submitLabel(.done)
                .onSubmit { fieldFocused = false }
                .disabled(atLimit)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(atLimit ? 0.55 : 0.85))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ink.opacity(0.12), lineWidth: 1)
                        }
                }
                .padding(.top, 8)
                .accessibilityIdentifier("us.asks.add.body")

            Button(action: commit) {
                HStack(spacing: 8) {
                    if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(showSuccess ? "Added" : (atLimit ? "Limit reached" : "Add"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(BeSideColor.navyLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BeSideColor.navyFill)
                        .shadow(color: ink.opacity(0.2), radius: 10, y: 4)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .opacity(showSuccess || canCommit ? 1 : 0.45)
            .allowsHitTesting(!showSuccess && canCommit)
            .accessibilityIdentifier("us.asks.add.commit")
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.92), Color.white.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                }
                .shadow(color: ink.opacity(0.16), radius: 28, y: 10)
        }
        .environment(\.colorScheme, .light)
    }

    // MARK: - Linear week calendar

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(UsImportantDates.monthYearLabel(selectedDay))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ink.opacity(0.5))
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

            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { day in
                    let selected = calendar.isDate(day, inSameDayAs: selectedDay)
                    let isToday = calendar.isDateInToday(day)
                    Button {
                        fieldFocused = false
                        withAnimation(.easeOut(duration: 0.18)) {
                            selectedDay = calendar.startOfDay(for: day)
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Text(Self.weekdayFormatter.string(from: day).uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .tracking(0.3)
                                .foregroundStyle(selected ? Color.white.opacity(0.85) : ink.opacity(0.38))

                            Text("\(calendar.component(.day, from: day))")
                                .font(.system(size: 15, weight: selected ? .semibold : .medium, design: .rounded))
                                .foregroundStyle(
                                    selected
                                        ? Color.white.opacity(0.95)
                                        : isToday
                                            ? BeSideColor.navyStart.opacity(0.88)
                                            : ink.opacity(0.72)
                                )
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(BeSideColor.navyFill)
                                    .shadow(color: BeSideColor.navyStart.opacity(0.2), radius: 6, y: 2)
                            } else if isToday {
                                Capsule()
                                    .stroke(BeSideColor.navyStart.opacity(0.35), lineWidth: 1.2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Self.a11yDayFormatter.string(from: day))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("us.asks.add.day.\(calendar.component(.day, from: day))")
                }
            }
            .padding(5)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    }
            }
        }
        .accessibilityIdentifier("us.asks.add.week")
    }

    private func shiftWeek(by weeks: Int) {
        fieldFocused = false
        guard let next = calendar.date(byAdding: .day, value: weeks * 7, to: selectedDay) else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            selectedDay = calendar.startOfDay(for: next)
        }
    }

    private func commit() {
        guard !showSuccess else { return }
        guard !atLimit else { return }
        let clean = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            fieldFocused = true
            return
        }
        guard onAdd(clean, selectedDay) else { return }
        fieldFocused = false
        bodyText = ""
        withAnimation(.easeOut(duration: 0.2)) { showSuccess = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            onClose()
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else {
            keyboardHeight = 0
            return
        }
        let overlap = max(0, window.bounds.maxY - frame.minY)
        let next = overlap > 40 ? overlap : 0
        guard next != keyboardHeight else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardHeight = next
        }
    }

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
