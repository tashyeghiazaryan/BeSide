import SwiftUI
import UIKit

/// Non-dismissible invite / join overlay from Figma Make Partner.
struct PartnerPairingModal: View {
    let inviteCode: String
    let onPaired: () -> Void

    private enum Step {
        case choose
        case invite
        case join
    }

    @State private var step: Step = .choose
    @State private var joinCode = ""
    @State private var codeCopied = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    BeSideColor.navyStart.opacity(0.28),
                    BeSideColor.navyStart.opacity(0.38),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(true)

            card
                .padding(.horizontal, 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("partner.pairing.modal")
    }

    private var card: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color(hex: 0xE8BED3),
                    Color(hex: 0xD7C8E2),
                    Color(hex: 0xC9D6EE),
                    Color.clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(spacing: 0) {
                Text("Partner")
                    .font(.system(size: 10, weight: .light))
                    .tracking(2.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.black.opacity(0.25))
                    .padding(.bottom, 8)

                Text(title)
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)

                Text(subtitle)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                switch step {
                case .choose:
                    chooseContent
                case .invite:
                    inviteContent
                case .join:
                    joinContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 312)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.96), Color.white.opacity(0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                }
                .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 28, y: 10)
        }
    }

    private var title: String {
        switch step {
        case .choose: return "You're in.\nInvite them next."
        case .invite: return "Share your code"
        case .join: return "Enter their code"
        }
    }

    private var subtitle: String {
        switch step {
        case .choose: return "One tap closer to knowing how they really feel."
        case .invite: return "Send this code to your partner so they can join you."
        case .join: return "Type the invite code they shared with you."
        }
    }

    private var chooseContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                youAvatar
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 20, height: 1)
                emptyAvatar
            }
            .padding(.bottom, 20)

            Button {
                step = .invite
            } label: {
                Text("Invite the partner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BeSideColor.navyLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BeSideColor.navyFill)
                            .shadow(color: BeSideColor.navyStart.opacity(0.22), radius: 12, y: 4)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("partner.pair.invite")

            Button {
                step = .join
            } label: {
                Text("Join the partner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BeSideColor.navyStart.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BeSideColor.navyStart.opacity(0.05))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(BeSideColor.navyStart.opacity(0.1), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .accessibilityIdentifier("partner.pair.join")

            Text("Connect a partner to unlock this screen.")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Color.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
    }

    private var inviteContent: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your invite code")
                        .font(.system(size: 9, weight: .light))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.gray.opacity(0.7))
                    Text(inviteCode)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(BeSideColor.textPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Button(codeCopied ? "Copied" : "Copy") {
                    UIPasteboard.general.string = inviteCode
                    codeCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.8))
                        codeCopied = false
                    }
                }
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.gray.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(BeSideColor.navyStart.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("partner.pair.copy")
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BeSideColor.navyStart.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BeSideColor.navyStart.opacity(0.06), lineWidth: 1)
                    }
            }

            // Demo unlock: copy path still lets you continue without a real partner.
            Button("Continue with this code") {
                onPaired()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(BeSideColor.navyLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BeSideColor.navyFill)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("partner.pair.continue")

            Button("Back") { step = .choose }
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color.gray.opacity(0.55))
                .buttonStyle(.plain)
                .padding(.top, 4)
        }
    }

    private var joinContent: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Invite code")
                    .font(.system(size: 9, weight: .light))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.gray.opacity(0.7))
                TextField("BESIDE-····", text: $joinCode)
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.2)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BeSideColor.navyStart.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(BeSideColor.navyStart.opacity(0.1), lineWidth: 1)
                            }
                    }
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = String(newValue.uppercased().prefix(24))
                    }
                    .accessibilityIdentifier("partner.pair.join.field")
            }

            Button {
                onPaired()
            } label: {
                Text("Join")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BeSideColor.navyLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BeSideColor.navyFill)
                    }
            }
            .buttonStyle(.plain)
            .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
            .opacity(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 ? 0.5 : 1)
            .accessibilityIdentifier("partner.pair.join.confirm")

            Button("Back") { step = .choose }
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color.gray.opacity(0.55))
                .buttonStyle(.plain)
        }
    }

    private var youAvatar: some View {
        Text("You")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(Color.white.opacity(0.9))
            .frame(width: 44, height: 44)
            .background {
                Circle()
                    .fill(BeSideColor.navyFill)
                    .overlay { Circle().stroke(Color.white.opacity(0.55), lineWidth: 2) }
                    .shadow(color: BeSideColor.navyStart.opacity(0.18), radius: 8, y: 3)
            }
    }

    private var emptyAvatar: some View {
        Text("?")
            .font(.system(size: 10, weight: .light))
            .foregroundStyle(Color.gray.opacity(0.55))
            .frame(width: 44, height: 44)
            .background {
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .overlay {
                        Circle().stroke(
                            style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                        )
                        .foregroundStyle(BeSideColor.navyStart.opacity(0.18))
                    }
            }
    }
}
