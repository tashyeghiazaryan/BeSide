import SwiftUI

/// Shared More / sheet chrome matched to Figma AuthScreen ambient + frosted cards.
enum MoreChrome {
    static var pageBackground: some View {
        ZStack {
            BeSideBackground.authCanvas
            BeSideBackground.authAmbientBlobs()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    static func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .light))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Color.black.opacity(0.28))
            .padding(.top, 22)
            .padding(.bottom, 8)
            .padding(.horizontal, 4)
    }

    static func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .light))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.black.opacity(0.28))
    }

    /// Auth primary CTA fill (`#2D2D44`).
    static let ctaFill = Color(hex: 0x2D2D44)
}

struct MoreGlassCard<Content: View>: View {
    var padding: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        AuthFrostedCard(cornerRadius: 24, padding: padding) {
            content()
        }
    }
}
