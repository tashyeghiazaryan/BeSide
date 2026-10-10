import SwiftUI

/// Floating liquid-glass tab bar matching Figma Make (`App.tsx` bottom nav).
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    /// Dark chrome only on the Connection carousel (not inner hubs). Driven by preference.
    var useDarkChrome: Bool = false
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background { barChrome }
        .clipShape(RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous))
        .shadow(
            color: Color.black.opacity(useDarkChrome ? 0.35 : 0.08),
            radius: useDarkChrome ? 24 : 20,
            y: 8
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1.5)
        .padding(.horizontal, BeSideMetrics.tabBarHorizontalInset)
        .padding(.bottom, 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tab.bar")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = selection == tab
        let activeColor = useDarkChrome ? BeSideColor.tabActiveOnDark : BeSideColor.tabActive
        let inactiveColor = useDarkChrome ? BeSideColor.tabInactiveOnDark : BeSideColor.tabInactive

        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                TabBarIcon(
                    kind: tab.iconKind,
                    size: 21,
                    lineWidth: isActive ? 2 : 1.5
                )
                Text(tab.title)
                    .font(.system(size: 9.5, weight: isActive ? .semibold : .regular))
                    .tracking(0.1)
            }
            .foregroundStyle(isActive ? activeColor : inactiveColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                if isActive {
                    activePill
                        .matchedGeometryEffect(id: "liquidGlassTab", in: tabNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityIdentifier(tab.tabIdentifier)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    @ViewBuilder
    private var activePill: some View {
        let shape = RoundedRectangle(cornerRadius: BeSideMetrics.tabBarItemCorner, style: .continuous)
        if useDarkChrome {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape.stroke(Color.white.opacity(0.22), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 6, y: 2)
        } else {
            // Original light active pill (unchanged for Me / Partner / Us / More).
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape.stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        }
    }

    @ViewBuilder
    private var barChrome: some View {
        if useDarkChrome {
            BeSideGlassChrome.background(
                cornerRadius: BeSideMetrics.tabBarCorner,
                style: .dark
            )
        } else {
            // Original frosted chrome for non-Connection tabs.
            ZStack {
                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.9),
                                    Color.clear,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                        .padding(.top, 0.5)
                    Spacer(minLength: 0)
                }

                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.5)
            }
        }
    }
}
