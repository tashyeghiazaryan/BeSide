import SwiftUI

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
        guard let context = session.coupleContext else { return }
        meStore.applyCoupleContext(context)

        guard session.phase == .authenticated,
              AppBackend.shared.isLiveConfigured,
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
