import SwiftUI

/// Add Important Date calendar — Figma Make UsScreen add modal.
struct ImportantDatesAddModal: View {
    let onClose: () -> Void
    let onAdd: (String, Date, UsDateIconPreset) -> Bool
    /// Called after a successful save (after the brief success flash).
    var onAdded: (() -> Void)? = nil

    @State private var viewMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var titleText = ""
    @State private var selectedIcon: UsDateIconPreset = .defaultCustom
    @State private var fieldsExpanded = true
    @State private var showSuccess = false
    @FocusState private var titleFocused: Bool

    private var ink: Color { Color(hex: 0x1A1A2E) }
    private let calendar = Calendar.current
    private var canCommit: Bool {
        guard selectedDay != nil else { return false }
        return !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var year: Int { calendar.component(.year, from: viewMonth) }
    private var month: Int { calendar.component(.month, from: viewMonth) }
    private var cells: [Int?] { UsImportantDates.dayCells(year: year, month: month, calendar: calendar) }

    var body: some View {
        ZStack {
            scrim
                .onTapGesture(perform: close)

            ScrollView(.vertical, showsIndicators: false) {
                card
                    .padding(.horizontal, 16)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // Prevent UIKit keyboard avoidance from shoving the card into the status bar
        // (broke Close + month nav on iPhone 16).
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.add.modal")
    }

    private var scrim: some View {
        ZStack {
            Color(hex: 0x1A1A2E).opacity(0.28)
            RadialGradient(
                colors: [Color(hex: 0xFBCFE8).opacity(0.22), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    private var card: some View {
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

            VStack(spacing: 0) {
                Text("Add a date")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink)
                Text("Pick a day on the calendar")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(ink.opacity(0.45))
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                monthHeader
                weekdayHeader
                dayGrid
                    .padding(.top, 6)
                    .id("us.dates.add.month.\(year)-\(month)")

                if fieldsExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ink.opacity(0.45))

                        TextField("e.g. Trip to the coast", text: $titleText)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(ink.opacity(0.85))
                            .focused($titleFocused)
                            .submitLabel(.done)
                            .onSubmit { titleFocused = false }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.72))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(ink.opacity(0.12), lineWidth: 1)
                                    }
                            }
                            .accessibilityIdentifier("us.dates.add.title")

                        if let selectedDay {
                            Text(UsImportantDates.shortDate(selectedDay))
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(ink.opacity(0.45))
                        } else {
                            Text("Select a day on the calendar")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(ink.opacity(0.35))
                        }

                        iconPicker
                            .padding(.top, 4)
                    }
                    .padding(.top, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                addButton
                    .padding(.top, 14)
                    .opacity(showSuccess || canCommit ? 1 : 0.45)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
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
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.18), radius: 28, y: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.72))
                            .overlay { Circle().stroke(ink.opacity(0.12), lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)
            .padding(12)
            .zIndex(20)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("us.dates.add.close")
        }
        .environment(\.colorScheme, .light)
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ink.opacity(0.45))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(UsDateIconPreset.allCases) { preset in
                        Button {
                            titleFocused = false
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedIcon = preset
                            }
                        } label: {
                            UsDateIconSphere(
                                preset: preset,
                                size: 40,
                                isSelected: selectedIcon == preset
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.label)
                        .accessibilityAddTraits(selectedIcon == preset ? .isSelected : [])
                        .accessibilityIdentifier("us.dates.add.icon.\(preset.rawValue)")
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }

            Text(selectedIcon.label)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(ink.opacity(0.42))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.add.icons")
    }

    private var monthHeader: some View {
        HStack {
            chromeIconButton(systemName: "chevron.left", label: "Previous month") {
                shiftMonth(by: -1)
            }
            Text(UsImportantDates.monthYearLabel(viewMonth))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ink.opacity(0.88))
                .frame(maxWidth: .infinity)
                .textCase(.none)
            chromeIconButton(systemName: "chevron.right", label: "Next month") {
                shiftMonth(by: 1)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 8, weight: .medium))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.32))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
    }

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let today = calendar.startOfDay(for: Date())
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    let dayStart = calendar.startOfDay(for: date)
                    let selected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let isToday = calendar.isDate(dayStart, inSameDayAs: today)
                    Button {
                        titleFocused = false
                        selectedDay = dayStart
                        withAnimation(.easeOut(duration: 0.2)) {
                            if !fieldsExpanded { fieldsExpanded = true }
                        }
                        showSuccess = false
                    } label: {
                        Text("\(day)")
                            .font(.system(size: 12, weight: selected || isToday ? .semibold : .light))
                            .foregroundStyle(
                                selected
                                    ? Color.white.opacity(0.95)
                                    : isToday
                                        ? BeSideColor.navyStart.opacity(0.88)
                                        : ink.opacity(0.78)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        selected
                                            ? AnyShapeStyle(BeSideColor.navyFill)
                                            : AnyShapeStyle(Color.white.opacity(isToday ? 0.55 : 0.35))
                                    )
                                    .overlay {
                                        if isToday && !selected {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(BeSideColor.navyStart.opacity(0.55), lineWidth: 1.5)
                                        }
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("us.dates.add.day.\(day)")
                    .accessibilityLabel(isToday ? "Today, \(day)" : "\(day)")
                } else {
                    Color.clear.frame(height: 34)
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: handleAddTap) {
            HStack(spacing: 8) {
                if showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(BeSideColor.navyLabel)
                        .accessibilityHidden(true)
                }
                Text(showSuccess ? "Added" : "Add")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(BeSideColor.navyLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BeSideColor.navyFill)
                    .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 10, y: 4)
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!showSuccess && canCommit)
        .accessibilityLabel(showSuccess ? "Added" : "Add")
        .accessibilityIdentifier("us.dates.add.commit")
    }

    private func chromeIconButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ink.opacity(0.55))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .overlay { Circle().stroke(ink.opacity(0.12), lineWidth: 1) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func shiftMonth(by value: Int) {
        titleFocused = false
        viewMonth = calendar.date(byAdding: .month, value: value, to: viewMonth) ?? viewMonth
    }

    private func handleAddTap() {
        if showSuccess { return }
        if !fieldsExpanded {
            withAnimation(.easeOut(duration: 0.2)) { fieldsExpanded = true }
            return
        }
        guard let selectedDay else { return }
        let clean = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            titleFocused = true
            return
        }
        guard onAdd(clean, selectedDay, selectedIcon) else { return }
        titleFocused = false
        titleText = ""
        self.selectedDay = nil
        selectedIcon = .defaultCustom
        withAnimation(.easeOut(duration: 0.2)) {
            fieldsExpanded = false
            showSuccess = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            if let onAdded {
                onAdded()
            } else {
                showSuccess = false
                withAnimation(.easeOut(duration: 0.2)) { fieldsExpanded = true }
            }
        }
    }

    private func close() {
        titleFocused = false
        onClose()
    }
}
