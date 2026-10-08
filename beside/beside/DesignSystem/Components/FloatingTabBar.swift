import SwiftUI

/// Floating liquid-glass tab bar matching Figma Make (`App.tsx` bottom nav).
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var tabNamespace

    /// Connection’s full-bleed media makes ultra-thin glass go dark — use denser chrome so icons stay readable.
    private var solidOnDarkMedia: Bool { selection == .connection }

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
            color: Color.black.opacity(solidOnDarkMedia ? 0.22 : 0.08),
            radius: solidOnDarkMedia ? 24 : 20,
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
            .foregroundStyle(isActive ? BeSideColor.tabActive : BeSideColor.tabInactive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: BeSideMetrics.tabBarItemCorner, style: .continuous)
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
                            RoundedRectangle(cornerRadius: BeSideMetrics.tabBarItemCorner, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
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

    private var barChrome: some View {
        ZStack {
            if solidOnDarkMedia {
                // Opaque light plate so navy/gray tab icons stay visible over dark photos.
                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                RoundedRectangle(cornerRadius: BeSideMetrics.tabBarCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.98),
                                Color.white.opacity(0.9),
                                Color(hex: 0xF3F4F6).opacity(0.92),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
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
            }

            // Top specular highlight
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
                .stroke(
                    Color.white.opacity(solidOnDarkMedia ? 0.85 : 0.55),
                    lineWidth: solidOnDarkMedia ? 0.8 : 0.5
                )
        }
    }
}
