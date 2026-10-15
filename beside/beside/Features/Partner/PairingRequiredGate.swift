import SwiftUI

/// Blocks Partner / Us / Connection until the user is paired. Me and More stay ungated.
struct PairingRequiredGate<Content: View>: View {
    @Bindable var store: MeSessionStore
    var session: AppSessionStore?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
                .blur(radius: store.isPaired ? 0 : 5)
                .opacity(store.isPaired ? 1 : 0.72)
                .scaleEffect(store.isPaired ? 1 : 1.02, anchor: .top)
                .allowsHitTesting(store.isPaired)

            if !store.isPaired {
                PartnerPairingModal(
                    inviteCode: store.inviteCode,
                    usesLiveBackend: session?.phase == .authenticated,
                    onCreateInvite: createInvite,
                    onJoin: join,
                    onRefresh: refresh,
                    onPaired: {
                        store.completePairing()
                    }
                )
                .accessibilityIdentifier("pairing.required.gate")
            }
        }
    }

    private var createInvite: (() async throws -> String)? {
        session.map { session in
            {
                let code = try await session.createCouple(displayName: store.displayName)
                if let context = session.coupleContext {
                    store.applyCoupleContext(context)
                } else {
                    store.inviteCode = code
                }
                return code
            }
        }
    }

    private var join: ((String) async throws -> Void)? {
        session.map { session in
            { code in
                try await session.joinCouple(code: code)
                if let context = session.coupleContext {
                    store.applyCoupleContext(context)
                }
            }
        }
    }

    private var refresh: (() async -> Void)? {
        session.map { session in
            {
                await session.refreshCoupleContext()
                if let context = session.coupleContext {
                    store.applyCoupleContext(context)
                }
            }
        }
    }
}

extension View {
    func pairingRequiredGate(store: MeSessionStore, session: AppSessionStore?) -> some View {
        PairingRequiredGate(store: store, session: session) { self }
    }
}
