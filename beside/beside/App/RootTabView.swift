import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .me
    @State private var meStore = MeSessionStore()
    @State private var isKeyboardVisible = false
    @State private var hideFloatingTabBar = false
    @State private var darkFloatingTabBar = false

    private var showFloatingTabBar: Bool {
        !isKeyboardVisible && !hideFloatingTabBar
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            screen(for: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showFloatingTabBar {
                FloatingTabBar(selection: $selection, useDarkChrome: darkFloatingTabBar)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(50)
            }
        }
        // Keep tab layouts fixed — keyboard overlays on top (Me custom wish, Partner note, etc.).
        .ignoresSafeArea(.keyboard)
        .animation(.easeOut(duration: 0.25), value: isKeyboardVisible)
        .animation(.easeOut(duration: 0.25), value: hideFloatingTabBar)
        .animation(.easeOut(duration: 0.25), value: darkFloatingTabBar)
        .onPreferenceChange(HideFloatingTabBarKey.self) { hideFloatingTabBar = $0 }
        .onPreferenceChange(DarkFloatingTabBarKey.self) { darkFloatingTabBar = $0 }
        .onReceive(KeyboardVisibility.publisher) { visible in
            isKeyboardVisible = visible
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .me:
            MeView(store: meStore)
        case .partner:
            PartnerView(store: meStore)
        case .us:
            UsView(store: meStore, onSelectTab: { selection = $0 })
        case .connection:
            ConnectionView(store: meStore)
        case .more:
            MoreView()
        }
    }
}

struct TabPlaceholder: View {
    let tab: AppTab

    var body: some View {
        Text(tab.title)
            .font(.title2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, BeSideMetrics.tabBarClearance)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tab.title)
            .accessibilityIdentifier(tab.screenIdentifier)
    }
}

#Preview {
    RootTabView()
}
