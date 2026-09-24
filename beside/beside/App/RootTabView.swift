import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .me
    @State private var meStore = MeSessionStore()
    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack(alignment: .bottom) {
            screen(for: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !isKeyboardVisible {
                FloatingTabBar(selection: $selection)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Do NOT ignore the keyboard — Me must shrink/scroll so the custom wish field stays visible.
        .animation(.easeOut(duration: 0.25), value: isKeyboardVisible)
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
            UsView(store: meStore)
        case .connection:
            ConnectionView()
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
