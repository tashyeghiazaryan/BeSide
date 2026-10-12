import PhotosUI
import SwiftUI
import UIKit

struct MoreView: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore?

    @State private var showPairing = false
    @State private var pairingStartStep: PartnerPairingStartStep = .choose
    @State private var showManagePair = false
    @State private var showEditProfile = false
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var stubDestination: MoreStubDestination?
    @State private var showPremiumActiveNote = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let build, !build.isEmpty { return "\(short) (\(build))" }
        return short
    }

    private var avatarInitial: String {
        String(store.displayName.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            MoreChrome.pageBackground

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    profileCard
                        .padding(.top, 14)

                    MoreChrome.sectionLabel("My partner")
                    MoreGlassCard {
                        if store.isPaired {
                            MoreRow(
                                systemImage: "person.2",
                                label: "My partner",
                                hint: "\(store.partnerDisplayName) · You’re paired",
                                action: { showManagePair = true }
                            )
                            .accessibilityIdentifier("more.partner.open")
                        } else {
                            unpairedPartnerActions
                        }
                    }

                    MoreChrome.sectionLabel("Subscription")
                    MoreGlassCard {
                        MoreRow(
                            systemImage: "sparkles",
                            label: store.isPremium ? "Premium active" : "Try Premium",
                            hint: store.isPremium
                                ? "Manage billing and plan"
                                : "More prompts, activities, and moments for two",
                            premiumStyle: true,
                            trailing: store.isPremium
                                ? AnyView(
                                    Text("Active")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color(hex: 0x92400E))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background {
                                            Capsule().fill(Color(hex: 0xFEF3C7).opacity(0.95))
                                        }
                                )
                                : nil,
                            action: {
                                if store.isPremium {
                                    showPremiumActiveNote = true
                                } else {
                                    store.unlockDemoPremium()
                                }
                            }
                        )
                        .accessibilityIdentifier("more.subscription")
                    }

                    MoreChrome.sectionLabel("Preferences")
                    MoreGlassCard {
                        MoreRow(
                            systemImage: "bell",
                            label: "Notifications",
                            hint: "Reminders, partner activity, daily prompts",
                            action: { stubDestination = .notifications }
                        )
                        MoreRow(
                            systemImage: "lock.shield",
                            label: "Privacy & data",
                            hint: "Visibility, export, delete account",
                            action: { stubDestination = .privacy }
                        )
                    }

                    MoreChrome.sectionLabel("Support")
                    MoreGlassCard {
                        MoreRow(
                            systemImage: "questionmark.circle",
                            label: "Help & FAQ",
                            action: { stubDestination = .help }
                        )
                        MoreRow(
                            systemImage: "doc.text",
                            label: "Terms & privacy policy",
                            action: { stubDestination = .terms }
                        )
                    }

                    MoreChrome.sectionLabel("Account")
                    MoreGlassCard {
                        MoreRow(
                            systemImage: "rectangle.portrait.and.arrow.right",
                            label: "Log out",
                            hint: session?.phase == .authenticated
                                ? "Sign out on this device"
                                : "Demo mode — stay in the shell",
                            danger: true,
                            action: { Task { await handleLogOut() } }
                        )
                    }

                    Text("BeSide · v\(appVersion)")
                        .font(.system(size: 10, weight: .light))
                        .tracking(0.8)
                        .foregroundStyle(Color.black.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                        .padding(.bottom, BeSideMetrics.tabBarClearance + 16)
                }
                .padding(.horizontal, 20)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("More")
        .accessibilityIdentifier("screen.more")
        .fullScreenCover(isPresented: $showPairing) {
            pairingCover
        }
        .sheet(isPresented: $showManagePair) {
            MyPartnerSheet(store: store, session: session, isPresented: $showManagePair)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(store: store, session: session, isPresented: $showEditProfile)
        }
        .sheet(item: $stubDestination) { dest in
            MoreStubSheet(destination: dest)
        }
        .sheet(isPresented: $showPremiumActiveNote) {
            MoreStubSheet(destination: .premiumActive)
        }
        .onChange(of: avatarPickerItem) { _, item in
            Task { await loadAvatarPhoto(item) }
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("More")
                .font(.system(size: 32, weight: .ultraLight))
                .tracking(1.2)
                .foregroundStyle(Color.black.opacity(0.78))
            Text("Profile, pair, and app settings")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color.black.opacity(0.38))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private var profileCard: some View {
        MoreGlassCard(padding: 16) {
            HStack(alignment: .center, spacing: 16) {
                PhotosPicker(selection: $avatarPickerItem, matching: .images, photoLibrary: .shared()) {
                    ZStack(alignment: .bottomTrailing) {
                        avatarBubble

                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(BeSideColor.navyLabel)
                            .frame(width: 26, height: 26)
                            .background {
                                Circle()
                                    .fill(BeSideColor.navyFill)
                                    .overlay { Circle().stroke(Color.white, lineWidth: 2) }
                            }
                            .offset(x: 2, y: 2)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change avatar")
                .accessibilityIdentifier("more.avatar")

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.displayName)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .lineLimit(1)
                        .accessibilityIdentifier("more.profile.name")

                    Text(store.isPremium ? "Premium" : "Free plan")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.38))
                        .accessibilityIdentifier("more.profile.plan")

                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit profile")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BeSideColor.raspberry.opacity(0.95))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .accessibilityIdentifier("more.profile.edit")
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityIdentifier("more.profile")
    }

    @ViewBuilder
    private var avatarBubble: some View {
        Group {
            if let data = store.meAvatarJPEG, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(avatarInitial)
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(BeSideColor.loveNotePinkDeep.opacity(0.95))
            }
        }
        .frame(width: 72, height: 72)
        .background {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            BeSideColor.loveNotePink.opacity(0.55),
                            Color(hex: 0xFEF3C7).opacity(0.7),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(Circle())
        .overlay { Circle().stroke(Color.white.opacity(0.9), lineWidth: 2) }
        .shadow(color: BeSideColor.navyStart.opacity(0.1), radius: 8, y: 3)
    }

    private var unpairedPartnerActions: some View {
        VStack(spacing: 10) {
            Button {
                pairingStartStep = .invite
                showPairing = true
            } label: {
                Text("Invite your partner")
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
            .accessibilityIdentifier("more.partner.invite")

            Button {
                pairingStartStep = .join
                showPairing = true
            } label: {
                Text("Join your partner")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("more.partner.join")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var pairingCover: some View {
        ZStack(alignment: .topLeading) {
            PartnerPairingModal(
                inviteCode: store.inviteCode,
                usesLiveBackend: session?.phase == .authenticated,
                initialStep: pairingStartStep,
                onCreateInvite: session.map { session in
                    {
                        let code = try await session.createCouple(displayName: store.displayName)
                        if let context = session.coupleContext {
                            store.applyCoupleContext(context)
                        } else {
                            store.inviteCode = code
                        }
                        return code
                    }
                },
                onJoin: session.map { session in
                    { code in
                        try await session.joinCouple(code: code)
                        if let context = session.coupleContext {
                            store.applyCoupleContext(context)
                        }
                    }
                },
                onRefresh: session.map { session in
                    {
                        await session.refreshCoupleContext()
                        if let context = session.coupleContext {
                            store.applyCoupleContext(context)
                        }
                    }
                },
                onPaired: {
                    store.completePairing()
                    showPairing = false
                }
            )

            Button {
                showPairing = false
            } label: {
                Text("Close")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(Color.black.opacity(0.35))
                    }
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.top, 16)
            .accessibilityIdentifier("more.pair.close")
        }
    }

    private func handleLogOut() async {
        guard let session, session.phase == .authenticated else { return }
        await session.signOut()
    }

    @MainActor
    private func loadAvatarPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let picked = try? await item.loadTransferable(type: SharedMemoryPickedPhoto.self) {
            store.setMeAvatarJPEG(picked.data)
            return
        }
        if let raw = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: raw),
           let jpeg = image.jpegData(compressionQuality: 0.82) {
            store.setMeAvatarJPEG(jpeg)
        }
    }
}

// MARK: - Row helpers

private struct MoreRow: View {
    let systemImage: String
    let label: String
    var hint: String? = nil
    var premiumStyle: Bool = false
    var trailing: AnyView? = nil
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if premiumStyle {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BeSideColor.navyStart.opacity(0.88))
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(danger ? Color(hex: 0xDC2626).opacity(0.9) : Color.black.opacity(0.45))
                    }
                }
                .frame(width: 36, height: 36)
                .background {
                    if premiumStyle {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BeSideColor.loveNotePinkBright.opacity(0.95),
                                        BeSideColor.loveNotePink.opacity(0.45),
                                        Color.white.opacity(0.55),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
                            }
                            .shadow(color: BeSideColor.loveNotePinkDeep.opacity(0.28), radius: 8, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(danger ? Color(hex: 0xEF4444).opacity(0.08) : Color.black.opacity(0.04))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(danger ? Color(hex: 0xDC2626) : Color.black.opacity(0.78))
                    if let hint {
                        Text(hint)
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.35))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                if let trailing {
                    trailing
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.22))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stub destinations

private enum MoreStubDestination: String, Identifiable {
    case notifications
    case privacy
    case help
    case terms
    case premiumActive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notifications: return "Notifications"
        case .privacy: return "Privacy & data"
        case .help: return "Help & FAQ"
        case .terms: return "Terms & privacy"
        case .premiumActive: return "Premium"
        }
    }

    var body: String {
        switch self {
        case .notifications:
            return "Reminders and partner alerts will be configurable here soon."
        case .privacy:
            return "Visibility, export, and delete-account tools are coming in a later update."
        case .help:
            return "FAQs and support contacts will live here."
        case .terms:
            return "Full terms and privacy policy will open from this row."
        case .premiumActive:
            return "Billing management isn’t available in this demo. Enjoy Premium features in-session."
        }
    }
}

private struct MoreStubSheet: View {
    let destination: MoreStubDestination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MoreChrome.pageBackground

                VStack(alignment: .leading, spacing: 16) {
                    MoreGlassCard(padding: 20) {
                        Text(destination.body)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        dismiss()
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
                }
                .padding(20)
            }
            .navigationTitle(destination.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.black.opacity(0.45))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.clear)
        .accessibilityIdentifier("more.stub.\(destination.rawValue)")
    }
}

#Preview {
    MoreView(store: MeSessionStore(), session: nil)
}
