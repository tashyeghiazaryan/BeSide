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
        /// Figma Make Dates widgets — frosted white glass + soft contour glow.
        case widgetFrosted
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
            case .widgetFrosted:
                shape.fill(.ultraThinMaterial)
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.54),
                            Color.white.opacity(0.48),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear,
                            Color.white.opacity(0.06),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Top specular highlight
            VStack {
                Capsule()
                    .fill(topHairline(style: style))
                    .frame(height: style == .widgetFrosted ? 1.2 : 1)
                    .padding(.horizontal, max(12, cornerRadius * 0.9))
                    .padding(.top, 0.5)
                Spacer(minLength: 0)
            }
            .clipShape(shape)

            shape.stroke(
                Color.white.opacity(
                    style == .dark ? 0.18
                        : (style == .solidOnDark ? 0.85
                            : (style == .widgetFrosted ? 0.72 : 0.55))
                ),
                lineWidth: style == .dark ? 1 : (style == .solidOnDark ? 0.8 : (style == .widgetFrosted ? 1 : 0.5))
            )
        }
        .environment(\.colorScheme, style == .dark ? .dark : .light)
    }

    private static func topHairline(style: Style) -> LinearGradient {
        switch style {
        case .dark:
            return LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.35),
                    Color.white.opacity(0.45),
                    Color.white.opacity(0.35),
                    Color.clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .widgetFrosted:
            // Make: navy → rose → white → lilac
            return LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: 0x1A1A2E).opacity(0.35),
                    Color(hex: 0xE8BEC9).opacity(0.7),
                    Color.white.opacity(0.95),
                    Color(hex: 0xC4B5FD).opacity(0.55),
                    Color.clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
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
        }
    }
}

extension View {
    /// Apply shared BeSide glass chrome behind this view (matches floating tab bar).
    func beSideGlassChrome(
        cornerRadius: CGFloat = BeSideMetrics.tabBarCorner,
        style: BeSideGlassChrome.Style = .frosted
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background {
            BeSideGlassChrome.background(cornerRadius: cornerRadius, style: style)
        }
        .clipShape(shape)
        .overlay {
            if style == .widgetFrosted {
                // Soft contour glow (Figma Make widgets).
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color(hex: 0xFCE7F3).opacity(0.55),
                                Color.white.opacity(0.75),
                                Color(hex: 0xE0E7FF).opacity(0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                    .blur(radius: 0.4)
                    .allowsHitTesting(false)
            }
        }
        .shadow(
            color: style == .widgetFrosted
                ? Color(hex: 0x1A1A2E).opacity(0.08)
                : Color.black.opacity(style == .dark ? 0.35 : (style == .solidOnDark ? 0.22 : 0.08)),
            radius: style == .widgetFrosted ? 18 : (style == .frosted ? 16 : 20),
            y: style == .widgetFrosted ? 8 : 6
        )
        .shadow(
            color: style == .widgetFrosted
                ? Color.white.opacity(0.7)
                : Color.black.opacity(0.04),
            radius: style == .widgetFrosted ? 10 : 3,
            y: style == .widgetFrosted ? -1 : 1
        )
        .shadow(
            color: style == .widgetFrosted
                ? Color(hex: 0xFBCFE8).opacity(0.28)
                : Color.clear,
            radius: style == .widgetFrosted ? 14 : 0,
            y: style == .widgetFrosted ? 4 : 0
        )
    }
}
