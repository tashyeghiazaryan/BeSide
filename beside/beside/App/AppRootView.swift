import SwiftUI

/// App shell: **session layer** first, then tabs with **couple layer**.
///
/// 1. `AppSessionPhase` — loading → needsAuth (`AuthGateView`) → authenticated / demo
/// 2. Inside tabs — `MeSessionStore.coupleSurfaceState` —
///    unpaired (`PairingRequiredGate`) → pairedWaiting → pairedActive
///
/// Auth and pairing are separate; do not put `CoupleSurfaceState` on the auth screen.
struct AppRootView: View {
    @State private var session = AppSessionStore.makeDefault()
    @State private var meStore = MeSessionStore()

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ZStack {
                    Color(hex: 0xF7F1F4).ignoresSafeArea()
                    ProgressView()
                }
                .accessibilityIdentifier("app.loading")
            case .needsAuth:
                AuthGateView(session: session)
            case .authenticated, .demo:
                RootTabView(meStore: meStore, session: session)
            }
        }
        .task {
            await session.bootstrap()
            await syncStoreWithSession()
        }
        .onChange(of: session.coupleContext) { _, _ in
            Task { await syncStoreWithSession() }
        }
        .onChange(of: session.phase) { _, _ in
            Task { await syncStoreWithSession() }
        }
    }

    @MainActor
    private func syncStoreWithSession() async {
        switch session.phase {
        case .loading:
            return
        case .needsAuth:
            // Back on Auth — drop in-memory couple/shared state from the previous session.
            meStore.resetAfterSignOut()
            return
        case .demo:
            if let context = session.coupleContext {
                meStore.applyCoupleContext(context)
            }
            meStore.detachLiveBackend()
            return
        case .authenticated:
            break
        }

        guard let context = session.coupleContext else {
            // Authenticated but context not loaded yet — keep store, wait for refresh.
            meStore.detachLiveBackend()
            return
        }

        meStore.applyCoupleContext(context)

        guard AppBackend.shared.isLiveConfigured,
              let client = SupabaseClientProvider.client(config: AppBackend.shared.supabaseConfig),
              context.hasCouple
        else {
            meStore.detachLiveBackend()
            return
        }

        if let existing = meStore.liveGateway {
            existing.updateContext(context)
            if context.isPaired {
                await meStore.refreshFromLiveBackend()
            }
        } else {
            let gateway = CoupleBackendGateway(client: client, context: context)
            await meStore.attachLiveBackend(gateway)
        }
    }
}

#Preview("App · Auth") {
    AuthGateView(session: AppSessionStore(usesLiveBackend: true))
}

#Preview("App · tabs demo") {
    RootTabView(meStore: .previewPairedActive(), session: AppSessionStore())
}
