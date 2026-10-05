import PhotosUI
import SwiftUI
import UIKit

/// Add / edit memory glass modal — Figma Make UsScreen “Share a new memory”.
struct SharedMemoryAddModal: View {
    let editing: UsSharedMemory?
    let onClose: () -> Void
    let onAdd: (_ title: String, _ dateTime: Date, _ description: String, _ mood: String, _ photoData: Data?) -> Bool
    let onUpdate: (_ id: String, _ title: String, _ dateTime: Date, _ description: String, _ mood: String, _ photoData: Data?, _ removePhoto: Bool) -> Bool

    @State private var title = ""
    @State private var dateTime = Date()
    @State private var descriptionText = ""
    @State private var mood = "💛"
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var keepExistingPhoto = false
    @State private var showPhotoPicker = false
    @State private var isLoadingPhoto = false
    @State private var titleError: SharedMemoryFieldRules.TitleError?
    @State private var descriptionError: SharedMemoryFieldRules.DescriptionError?
    @State private var keyboardHeight: CGFloat = 0
    @State private var didPrefill = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title, description
    }

    private var isEditing: Bool { editing != nil }
    private var ink: Color { Color(hex: 0x26282B) }
    private var keyboardOpen: Bool { keyboardHeight > 80 }
    private var hasPhotoPreview: Bool { photoData != nil || keepExistingPhoto }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: 0x26282B).opacity(0.25)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .ignoresSafeArea()
                    .onTapGesture {
                        if focusedField != nil {
                            focusedField = nil
                        } else {
                            onClose()
                        }
                    }

                VStack(spacing: 0) {
                    Spacer(minLength: keyboardOpen ? 8 : 16)

                    card
                        .padding(.horizontal, 24)

                    if keyboardOpen {
                        Color.clear
                            .frame(height: max(12, keyboardHeight - 12))
                            .allowsHitTesting(false)
                    } else {
                        Spacer(minLength: 16)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .background(Color.clear)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .onAppear { prefillIfNeeded() }
        .accessibilityIdentifier(isEditing ? "us.memories.edit.modal" : "us.memories.add.modal")
    }

    private func prefillIfNeeded() {
        guard !didPrefill, let editing else { return }
        didPrefill = true
        title = editing.title
        dateTime = editing.dateTime
        descriptionText = editing.description
        mood = editing.mood
        if let data = editing.photoData {
            photoData = data
            keepExistingPhoto = false
        } else {
            keepExistingPhoto = UsSharedMemories.hasPhoto(editing)
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.65))
                .frame(height: 1)

            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Text(isEditing ? "Edit memory" : "Share a new memory")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ink.opacity(0.9))
                        .padding(.top, 22)
                    Text(isEditing
                         ? "Update this moment — title, photo, mood, or note."
                         : "Capture your own moment, even if it is not a task.")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(ink.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)

                    ScrollView(.vertical, showsIndicators: false) {
                        fieldStack
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .frame(maxHeight: keyboardOpen ? 220 : 360)

                    shareButton
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .overlay {
                                    Circle().stroke(ink.opacity(0.12), lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .padding(14)
                .accessibilityLabel("Close")
                .accessibilityIdentifier("us.memories.add.close")
            }
        }
        .frame(maxWidth: 360)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.92), Color.white.opacity(0.78)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 24, y: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var shareButton: some View {
        let visuallyReady = !isLoadingPhoto
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            focusedField = nil
            attemptShare()
        } label: {
            Text(isEditing ? "Save changes" : "Share a memory")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(visuallyReady ? BeSideColor.navyLabel : ink.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(visuallyReady ? BeSideColor.navyStart : ink.opacity(0.08))
                        .overlay {
                            if visuallyReady {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(BeSideColor.navyFill)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        }
                        .shadow(
                            color: visuallyReady ? BeSideColor.navyStart.opacity(0.18) : .clear,
                            radius: 8,
                            y: 3
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(isLoadingPhoto)
        .accessibilityIdentifier(isEditing ? "us.memories.edit.commit" : "us.memories.add.commit")
    }

    private var fieldStack: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Title", text: $title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ink.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background { fieldChrome(error: titleError != nil) }
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .description }
                    .onChange(of: title) { _, value in
                        let sanitized = SharedMemoryFieldRules.sanitizeTitle(value)
                        if sanitized != value { title = sanitized }
                        titleError = nil
                    }
                    .accessibilityIdentifier("us.memories.add.title")

                HStack {
                    if let titleError {
                        Text(titleError.inlineMessage)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(hex: 0xE11D48))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("us.memories.add.title.error")
                    }
                    Spacer(minLength: 8)
                    Text("\(title.count)/\(SharedMemoryFieldRules.titleMaxLength)")
                        .font(.system(size: 10, weight: .light).monospacedDigit())
                        .foregroundStyle(
                            title.count >= SharedMemoryFieldRules.titleMaxLength
                                ? Color(hex: 0xE11D48).opacity(0.85)
                                : ink.opacity(0.38)
                        )
                }
            }

            DatePicker(
                "When",
                selection: $dateTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { fieldChrome(error: false) }
            .accessibilityIdentifier("us.memories.add.datetime")

            VStack(alignment: .leading, spacing: 4) {
                TextField("Description (optional)", text: $descriptionText, axis: .vertical)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ink.opacity(0.88))
                    .lineLimit(2...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background { fieldChrome(error: descriptionError != nil) }
                    .focused($focusedField, equals: .description)
                    .onTapGesture { focusedField = .description }
                    .onChange(of: descriptionText) { _, value in
                        let sanitized = SharedMemoryFieldRules.sanitizeDescription(value)
                        if sanitized != value { descriptionText = sanitized }
                        descriptionError = nil
                    }
                    .accessibilityIdentifier("us.memories.add.description")

                HStack(alignment: .top) {
                    if let descriptionError {
                        Text(descriptionError.inlineMessage)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(hex: 0xE11D48))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("us.memories.add.description.error")
                    }
                    Spacer(minLength: 8)
                    Text("\(descriptionText.count)/\(SharedMemoryFieldRules.descriptionMaxLength)")
                        .font(.system(size: 10, weight: .light).monospacedDigit())
                        .foregroundStyle(
                            descriptionText.count >= SharedMemoryFieldRules.descriptionMaxLength
                                ? Color(hex: 0xE11D48).opacity(0.85)
                                : ink.opacity(0.38)
                        )
                }
            }

            photoPickerButton

            VStack(alignment: .leading, spacing: 8) {
                Text("Mood")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(ink.opacity(0.55))
                HStack(spacing: 8) {
                    ForEach(UsSharedMemories.moodOptions, id: \.self) { option in
                        Button {
                            mood = option
                        } label: {
                            Text(option)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background {
                                    Circle()
                                        .fill(mood == option ? Color.white.opacity(0.58) : Color.white.opacity(0.44))
                                        .overlay {
                                            Circle().stroke(
                                                mood == option ? ink.opacity(0.2) : ink.opacity(0.12),
                                                lineWidth: 1
                                            )
                                        }
                                        .shadow(
                                            color: mood == option ? ink.opacity(0.06) : .clear,
                                            radius: 4,
                                            y: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mood \(option)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fieldChrome(error: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(error ? Color(hex: 0xE11D48).opacity(0.75) : ink.opacity(0.08), lineWidth: error ? 1.5 : 1)
            }
    }

    private func attemptShare() {
        guard !isLoadingPhoto else { return }
        let titleIssue = SharedMemoryFieldRules.validateTitle(title)
        let descriptionIssue = SharedMemoryFieldRules.validateDescription(descriptionText)
        titleError = titleIssue
        descriptionError = descriptionIssue
        guard titleIssue == nil, descriptionIssue == nil else { return }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        let ok: Bool
        if let editing {
            let removePhoto = !hasPhotoPreview
            ok = onUpdate(
                editing.id,
                cleanTitle,
                dateTime,
                cleanDescription,
                mood,
                photoData,
                removePhoto
            )
        } else {
            ok = onAdd(cleanTitle, dateTime, cleanDescription, mood, photoData)
        }
        if ok { onClose() }
    }

    private var photoPickerButton: some View {
        Button {
            focusedField = nil
            showPhotoPicker = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: hasPhotoPreview ? [] : [6, 4])
                            )
                            .foregroundStyle(ink.opacity(0.15))
                    }
                    .frame(height: 88)

                if let photoData, let ui = UIImage(data: photoData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if keepExistingPhoto, let editing {
                    SharedMemoryPhotoView(memory: editing)
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(ink.opacity(0.35))
                        Text("Upload photo from device")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ink.opacity(0.45))
                    }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            Task { await loadPickedPhoto(item) }
        }
        .overlay {
            if isLoadingPhoto {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                    .frame(height: 88)
                    .overlay { ProgressView() }
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            if hasPhotoPreview {
                Button {
                    photoData = nil
                    pickerItem = nil
                    keepExistingPhoto = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .overlay {
                                    Circle().stroke(ink.opacity(0.12), lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel("Remove photo")
            }
        }
        .accessibilityIdentifier("us.memories.add.photo")
    }

    @MainActor
    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }

        if let picked = try? await item.loadTransferable(type: SharedMemoryPickedPhoto.self) {
            photoData = picked.data
            keepExistingPhoto = false
            return
        }
        if let raw = try? await item.loadTransferable(type: Data.self),
           let jpeg = UsSharedMemories.normalizedJPEG(from: raw) {
            photoData = jpeg
            keepExistingPhoto = false
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
        let next = overlap > 80 ? overlap : 0
        guard next != keyboardHeight else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardHeight = next
        }
    }
}
