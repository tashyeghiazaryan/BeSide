import SwiftUI

enum BeSideColor {
    static let textPrimary = Color.black.opacity(0.75)
    static let textSecondary = Color.black.opacity(0.35)
    static let textTertiary = Color.black.opacity(0.28)
    static let textMuted = Color.gray
    static let textMutedSoft = Color.gray.opacity(0.7)

    static let canvasTop = Color(hex: 0xFFFFFF)
    static let canvasBottom = Color(hex: 0xFBFCFD)

    static let wishText = Color(hex: 0x333333)
    static let wishTextIdle = Color(hex: 0x666666)
    static let shareIdleText = Color(hex: 0x444444)

    /// Floating tab bar (Figma Make gray-900 / gray-400@55%).
    static let tabActive = Color(hex: 0x111827)
    static let tabInactive = Color(hex: 0x9CA3AF).opacity(0.55)

    /// Auth Continue / primary CTA navy (Figma Make).
    static let navyStart = Color(hex: 0x1A1A2E)
    static let navyEnd = Color(hex: 0x2D2D44)
    static let navyLabel = Color.white.opacity(0.92)

    static var navyFill: LinearGradient {
        LinearGradient(
            colors: [navyStart, navyEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum BeSideBackground {
    /// Soft multi-stop canvas behind Me / main tabs (Figma Make).
    static var softCanvas: LinearGradient {
        LinearGradient(
            colors: [BeSideColor.canvasTop, Color.white, BeSideColor.canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func defaultAmbientBlobs() -> some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.34))
                .frame(width: 300, height: 300)
                .blur(radius: 72)
                .offset(x: -90, y: -40)
            Circle()
                .fill(Color.pink.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 72)
                .offset(x: 110, y: 180)
            Circle()
                .fill(Color.yellow.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 64)
        }
        .allowsHitTesting(false)
    }

    /// Mood-tinted ambient blurs (Figma Make Me — after tapping a sphere).
    static func moodAmbient(color: Color, gradientColors: [Color]) -> some View {
        ZStack {
            // Soft full-screen wash so the canvas reads as that mood
            color.opacity(0.24)

            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .opacity(0.52)
                .offset(x: -110, y: -200)

            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors.reversed(),
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .opacity(0.52)
                .offset(x: 120, y: 260)

            Circle()
                .fill(color.opacity(0.62))
                .frame(width: 280, height: 280)
                .blur(radius: 84)
                .opacity(0.42)
                .offset(x: 20, y: 40)
        }
        .allowsHitTesting(false)
    }
}

enum BeSideMetrics {
    /// Horizontal inset for glass cards on phone (Figma `px-5` + shadow room).
    static let pageInset: CGFloat = 28
    static let glassCorner: CGFloat = 22
    static let glassCornerLarge: CGFloat = 28

    /// Floating liquid-glass tab bar (Figma Make).
    static let tabBarCorner: CGFloat = 22
    static let tabBarItemCorner: CGFloat = 16
    static let tabBarHorizontalInset: CGFloat = 16
    /// Space so scroll content clears the floating bar + home indicator.
    static let tabBarClearance: CGFloat = 88

    /// Adaptive Me layout for iPhone 14+ size classes (sized for comfortable real-device use).
    struct MeLayout: Equatable {
        var pageInset: CGFloat
        var sphereSize: CGFloat
        var heroTitleSize: CGFloat
        var greetingSize: CGFloat
        var sectionLabelSize: CGFloat
        var bodySize: CGFloat
        var captionSize: CGFloat
        var topSpacer: CGFloat
        var gapAfterCurrentMood: CGFloat
        var gapAfterSpheres: CGFloat
        var tabBarClearance: CGFloat
        /// Soft cap on Plus / Max so cards don’t stretch edge-to-edge.
        var contentMaxWidth: CGFloat?

        /// Baseline: iPhone 14 / 15 / 16 (390×844).
        static let standard = MeLayout(
            pageInset: 18,
            sphereSize: 62,
            heroTitleSize: 30,
            greetingSize: 16,
            sectionLabelSize: 13,
            bodySize: 17,
            captionSize: 14,
            topSpacer: 10,
            gapAfterCurrentMood: 22,
            gapAfterSpheres: 18,
            tabBarClearance: 88,
            contentMaxWidth: nil
        )

        /// - Parameters:
        ///   - width: window width in points
        ///   - height: window height in points
        ///   - safeBottom: home-indicator inset
        static func resolve(width: CGFloat, height: CGFloat, safeBottom: CGFloat) -> MeLayout {
            // 14 / 15 / 16 ……… ~390
            // 14–16 Pro ……… ~393–402
            // Plus / Pro Max … ~428–440
            let pageInset: CGFloat
            let sphereSize: CGFloat
            let heroTitleSize: CGFloat
            let greetingSize: CGFloat
            let contentMaxWidth: CGFloat?

            if width <= 390 {
                pageInset = 18
                sphereSize = 62
                heroTitleSize = 30
                greetingSize = 16
                contentMaxWidth = nil
            } else if width <= 410 {
                pageInset = 20
                sphereSize = 66
                heroTitleSize = 31
                greetingSize = 17
                contentMaxWidth = nil
            } else {
                pageInset = 24
                sphereSize = 72
                heroTitleSize = 32
                greetingSize = 17
                contentMaxWidth = 440
            }

            let compactHeight = height < 860
            let topSpacer: CGFloat = compactHeight ? 10 : 16
            let gapAfterCurrentMood: CGFloat = compactHeight ? 20 : 26
            let gapAfterSpheres: CGFloat = compactHeight ? 16 : 20

            // Floating bar content (~64) + home indicator.
            let tabBarClearance = 64 + max(safeBottom, 8)

            return MeLayout(
                pageInset: pageInset,
                sphereSize: sphereSize,
                heroTitleSize: heroTitleSize,
                greetingSize: greetingSize,
                sectionLabelSize: 13,
                bodySize: 17,
                captionSize: 14,
                topSpacer: topSpacer,
                gapAfterCurrentMood: gapAfterCurrentMood,
                gapAfterSpheres: gapAfterSpheres,
                tabBarClearance: tabBarClearance,
                contentMaxWidth: contentMaxWidth
            )
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
