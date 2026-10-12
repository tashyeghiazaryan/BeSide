import SwiftUI

struct MyPartnerSheet: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore?
    @Binding var isPresented: Bool

    @State private var togetherSince: Date = Date()
    @State private var showDisconnectConfirm = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                MoreChrome.pageBackground

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Your pair")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.38))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)

                        AuthFrostedCard(cornerRadius: 24, padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                labeledRow(title: "Partner", value: store.partnerDisplayName)
                                Divider().overlay(Color.black.opacity(0.06))
                                labeledRow(title: "Status", value: "You’re paired")

                                VStack(alignment: .leading, spacing: 8) {
                                    MoreChrome.fieldLabel("Together since")
                                    DatePicker(
                                        "",
                                        selection: $togetherSince,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    }
                                    .accessibilityIdentifier("more.partner.togetherSince")
                                    .onChange(of: togetherSince) { _, newValue in
                                        persistTogetherSince(newValue)
                                    }
                                }

                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Color(hex: 0xFB7185))
                                }

                                Button {
                                    withAnimation(.easeOut(duration: 0.22)) {
                                        showDisconnectConfirm = true
                                    }
                                } label: {
                                    HStack {
                                        if isWorking { ProgressView() }
                                        Text("Disconnect")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundStyle(Color(hex: 0xE11D48))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(hex: 0xFFF1F2).opacity(0.95))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(Color(hex: 0xFECDD3), lineWidth: 1)
                                            }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isWorking || showDisconnectConfirm)
                                .padding(.top, 4)
                                .accessibilityIdentifier("more.partner.disconnect")

                                Button {
                                    isPresented = false
                                } label: {
                                    Text("Done")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(MoreChrome.ctaFill)
                                        }
                                }
                                .buttonStyle(.plain)
                                .disabled(showDisconnectConfirm)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                if showDisconnectConfirm {
                    disconnectConfirmOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .zIndex(20)
                }
            }
            .navigationTitle("My partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundStyle(Color.black.opacity(0.45))
                        .disabled(showDisconnectConfirm)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            MoreChrome.pageBackground
        }
        .accessibilityIdentifier("more.partner.sheet")
        .onAppear {
            togetherSince = store.relationshipStartDate
        }
    }

    private var disconnectConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !isWorking else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDisconnectConfirm = false
                    }
                }

            AuthFrostedCard(cornerRadius: 24, padding: 22) {
                VStack(spacing: 14) {
                    Text("Are you sure?")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .multilineTextAlignment(.center)

                    Text("Are you sure you want to disconnect from \(store.partnerDisplayName)? You’ll both become unpaired, and shared couple data for this pair will be removed.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        Button {
                            Task { await disconnect() }
                        } label: {
                            HStack {
                                if isWorking { ProgressView().tint(.white) }
                                Text(isWorking ? "Disconnecting…" : "Yes, disconnect")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(Color.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(MoreChrome.ctaFill)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isWorking)
                        .accessibilityIdentifier("more.partner.disconnect.confirm")

                        Button {
                            guard !isWorking else { return }
                            withAnimation(.easeOut(duration: 0.2)) {
                                showDisconnectConfirm = false
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.72))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                        }
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isWorking)
                        .accessibilityIdentifier("more.partner.disconnect.cancel")
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("more.partner.disconnect.modal")
        }
    }

    private func labeledRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MoreChrome.fieldLabel(title)
            Text(value)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.78))
        }
    }

    private func persistTogetherSince(_ date: Date) {
        store.setRelationshipStartDate(date)
    }

    @MainActor
    private func disconnect() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            if let session {
                try await session.leaveCouple()
                if let context = session.coupleContext {
                    store.applyCoupleContext(context)
                } else {
                    store.disconnectPartner()
                }
            } else {
                store.disconnectPartner()
            }
            showDisconnectConfirm = false
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            withAnimation(.easeOut(duration: 0.2)) {
                showDisconnectConfirm = false
            }
        }
    }
}
