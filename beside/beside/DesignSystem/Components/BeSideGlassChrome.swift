import SwiftUI

/// Shared liquid-glass chrome used by the floating tab bar and Connection CTAs.
enum BeSideGlassChrome {
    enum Style {
        /// Translucent black glass — same family as the former Connection badge.
        case dark
        /// Frosted material for light canvases (other tabs).
        case frosted
        /// Opaque light plate (legacy / light CTA on dark media).
        case solidOnDark
    }

    @ViewBuilder
    static func background(cornerRadius: CGFloat, style: Style = .frosted) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            switch style {
            case .dark:
                // Match prior Connection pill: black @ ~0.3–0.4 with a soft lift.
                shape.fill(Color.black.opacity(0.38))
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            Color.black.opacity(0.12),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            case .solidOnDark:
                shape.fill(Color.white.opacity(0.94))
                shape.fill(
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
            case .frosted:
                shape.fill(.ultraThinMaterial)
                shape.fill(
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
                shape.fill(
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
                                Color.white.opacity(style == .dark ? 0.35 : 0.9),
                                Color.white.opacity(style == .dark ? 0.45 : 0.95),
                                Color.white.opacity(style == .dark ? 0.35 : 0.9),
                                Color.clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, max(12, cornerRadius * 0.9))
                    .padding(.top, 0.5)
                Spacer(minLength: 0)
            }
            .clipShape(shape)

            shape.stroke(
                Color.white.opacity(style == .dark ? 0.18 : (style == .solidOnDark ? 0.85 : 0.55)),
                lineWidth: style == .dark ? 1 : (style == .solidOnDark ? 0.8 : 0.5)
            )
        }
        .environment(\.colorScheme, style == .dark ? .dark : .light)
    }
}

extension View {
    /// Apply shared BeSide glass chrome behind this view (matches floating tab bar).
    func beSideGlassChrome(
        cornerRadius: CGFloat = BeSideMetrics.tabBarCorner,
        style: BeSideGlassChrome.Style = .frosted
    ) -> some View {
        background {
            BeSideGlassChrome.background(cornerRadius: cornerRadius, style: style)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(style == .dark ? 0.35 : (style == .solidOnDark ? 0.22 : 0.08)),
            radius: style == .frosted ? 16 : 20,
            y: 6
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
    }
}
