import SwiftUI

struct EditProfileSheet: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore?
    @Binding var isPresented: Bool

    private enum Field: Hashable {
        case name
        case email
    }

    @State private var nameDraft = ""
    @State private var emailDraft = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var detent: PresentationDetent = .medium
    @FocusState private var focusedField: Field?

    private var canSave: Bool {
        let name = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, email.contains("@"), email.contains(".") else { return false }
        let nameChanged = name != store.displayName
        let emailChanged = email != (session?.accountEmail ?? "")
        return (nameChanged || emailChanged) && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Text("How your partner sees you")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.38))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        AuthFrostedCard(cornerRadius: 24, padding: 20) {
                            VStack(alignment: .leading, spacing: 14) {
                                fieldBlock(title: "Name", id: Field.name) {
                                    TextField("Your name", text: $nameDraft)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .name)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .email }
                                        .accessibilityIdentifier("more.profile.edit.name")
                                }

                                fieldBlock(title: "Email", id: Field.email) {
                                    TextField("you@email.com", text: $emailDraft)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                        .accessibilityIdentifier("more.profile.edit.email")
                                }

                                Text("Name shows across Us and Connection. Email is for signing in.")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundStyle(Color.black.opacity(0.35))
                                    .fixedSize(horizontal: false, vertical: true)

                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Color(hex: 0xFB7185))
                                }

                                Button {
                                    focusedField = nil
                                    Task { await save() }
                                } label: {
                                    HStack {
                                        if isSaving { ProgressView().tint(.white) }
                                        Text("Save")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundStyle(Color.white.opacity(0.95))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(canSave ? MoreChrome.ctaFill : MoreChrome.ctaFill.opacity(0.35))
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(!canSave)
                                .padding(.top, 4)
                                .accessibilityIdentifier("more.profile.edit.save")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    withAnimation(.easeOut(duration: 0.28)) {
                        detent = .large
                    }
                    // Scroll after detent expands so the field stays below the nav bar.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
            .background {
                MoreChrome.pageBackground
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        focusedField = nil
                        isPresented = false
                    }
                    .foregroundStyle(Color.black.opacity(0.45))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
        // Sheet owns keyboard avoidance — do not also pad with smoothKeyboardLift.
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground {
            MoreChrome.pageBackground
        }
        .accessibilityIdentifier("more.profile.edit.sheet")
        .onAppear {
            nameDraft = store.displayName
            emailDraft = session?.accountEmail ?? ""
        }
        .onChange(of: focusedField) { _, field in
            if field == nil {
                withAnimation(.easeOut(duration: 0.28)) {
                    detent = .medium
                }
            }
        }
    }

    private func fieldBlock(
        title: String,
        id: Field,
        @ViewBuilder field: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MoreChrome.fieldLabel(title)
            field()
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.78))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            focusedField == id
                                ? MoreChrome.ctaFill.opacity(0.28)
                                : Color.black.opacity(0.08),
                            lineWidth: 1
                        )
                }
        }
        .animation(.easeOut(duration: 0.2), value: focusedField)
        .id(id)
    }

    @MainActor
    private func save() async {
        let name = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if let session {
                try await session.updateDisplayName(name)
                store.displayName = name
                if email != session.accountEmail {
                    try await session.updateAccountEmail(email)
                }
            } else {
                store.setDisplayName(name)
            }
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
