import SwiftUI
import UIKit

/// Full-screen Important Dates add — calendar on top, title / icon / Add below.
struct ImportantDatesAddPage: View {
    let onClose: () -> Void
    /// title, note (always nil from this page), date, icon
    let onAdd: (String, String?, Date, UsDateIconPreset) -> Bool
    /// Called after a successful save (after the brief success flash).
    var onAdded: (() -> Void)? = nil

    @State private var viewMonth: Date = Date()
    /// Defaults to today so Add enables as soon as the title is filled.
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var titleText = ""
    @State private var selectedIcon: UsDateIconPreset = .defaultCustom
    @State private var showSuccess = false
    @State private var keyboardHeight: CGFloat = 0
    /// UIKit-backed focus — SwiftUI TextField often fails to open keyboard on Us ZStack overlays.
    @State private var titleFocused = false

    private var ink: Color { BeSideColor.navyStart }
    private let calendar = Calendar.current
    private var keyboardOpen: Bool { keyboardHeight > 80 }

    private var canCommit: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var year: Int { calendar.component(.year, from: viewMonth) }
    private var month: Int { calendar.component(.month, from: viewMonth) }
    private var cells: [Int?] { UsImportantDates.dayCells(year: year, month: month, calendar: calendar) }

    var body: some View {
        // NavigationStack — reliable FocusState/keyboard on Us overlays (same as Love Note compose).
        NavigationStack {
            ZStack {
                background
                content
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { titleFocused = false }
                        .fontWeight(.semibold)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .hidesFloatingTabBar()
        .transition(.move(edge: .trailing))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("us.dates.add.page")
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

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Keep calendar in the tree — removing it on keyboard open
                        // rebuilds the TextField and kills first-responder / keyboard.
                        calendarCard
                        fieldsCard
                            .padding(.top, 14)
                            .id("us.dates.add.fields")
                        addButton
                            .padding(.top, 16)
                            .opacity(showSuccess || canCommit ? 1 : 0.45)
                            .id("us.dates.add.commit.anchor")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, keyboardOpen ? max(40, keyboardHeight - 12) : 40)
                    .padding(.top, 4)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: titleFocused) { _, focused in
                    guard focused else { return }
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("us.dates.add.fields", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: close) {
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
            .accessibilityIdentifier("us.dates.add.back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Add a date")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.88))
                Text("Pick a day on the calendar")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(ink.opacity(0.42))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            dayGrid
                .padding(.top, 6)
                .id("us.dates.add.month.\(year)-\(month)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
    }

    private var monthHeader: some View {
        HStack {
            chromeIconButton(systemName: "chevron.left", label: "Previous month") {
                shiftMonth(by: -1)
            }
            Text(UsImportantDates.monthYearLabel(viewMonth))
                .font(.system(size: 13, weight: .medium))
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
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.32))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(.top, 10)
    }

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let today = calendar.startOfDay(for: Date())
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    let dayStart = calendar.startOfDay(for: date)
                    let selected = calendar.isDate(selectedDay, inSameDayAs: date)
                    let isToday = calendar.isDate(dayStart, inSameDayAs: today)
                    Button {
                        titleFocused = false
                        selectedDay = dayStart
                        showSuccess = false
                    } label: {
                        Text("\(day)")
                            .font(.system(size: 14, weight: selected || isToday ? .semibold : .light))
                            .foregroundStyle(
                                selected
                                    ? Color.white.opacity(0.95)
                                    : isToday
                                        ? BeSideColor.navyStart.opacity(0.88)
                                        : ink.opacity(0.78)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
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
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    // MARK: - Fields

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Title")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ink.opacity(0.45))

            DatesAddTitleField(
                text: $titleText,
                isFocused: $titleFocused,
                placeholder: "e.g. Dinner in restaurant",
                onSubmit: { titleFocused = false }
            )
            .frame(height: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                titleFocused ? BeSideColor.navyStart.opacity(0.35) : ink.opacity(0.12),
                                lineWidth: titleFocused ? 1.5 : 1
                            )
                    }
            }

            Text(UsImportantDates.shortDate(selectedDay))
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(ink.opacity(0.45))

            iconPicker
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .beSideGlassChrome(cornerRadius: BeSideMetrics.glassCorner, style: .widgetFrosted)
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
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(BeSideColor.navyLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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

    // MARK: - Actions

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
        let clean = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            titleFocused = true
            return
        }
        guard onAdd(clean, nil, selectedDay, selectedIcon) else { return }
        titleFocused = false
        titleText = ""
        selectedDay = calendar.startOfDay(for: Date())
        selectedIcon = .defaultCustom
        withAnimation(.easeOut(duration: 0.2)) {
            showSuccess = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            if let onAdded {
                onAdded()
            } else {
                showSuccess = false
            }
        }
    }

    private func close() {
        titleFocused = false
        onClose()
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
}

/// UITextField bridge — opens the keyboard reliably inside Us overlay pages.
private struct DatesAddTitleField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 15, weight: .light)
        field.textColor = UIColor(BeSideColor.navyStart).withAlphaComponent(0.85)
        field.borderStyle = .none
        field.returnKeyType = .done
        field.autocapitalizationType = .sentences
        field.clearButtonMode = .whileEditing
        field.delegate = context.coordinator
        field.accessibilityIdentifier = "us.dates.add.title"
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        if isFocused {
            if !uiView.isFirstResponder {
                DispatchQueue.main.async {
                    _ = uiView.becomeFirstResponder()
                }
            }
        } else if uiView.isFirstResponder {
            DispatchQueue.main.async {
                _ = uiView.resignFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DatesAddTitleField

        init(_ parent: DatesAddTitleField) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            textField.resignFirstResponder()
            return true
        }
    }
}
