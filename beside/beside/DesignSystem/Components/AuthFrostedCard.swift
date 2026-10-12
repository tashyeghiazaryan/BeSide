import SwiftUI

/// Frosted white card from Figma AuthScreen — gradient fill, blur, soft border, deep shadow.
struct AuthFrostedCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.88),
                                        Color.white.opacity(0.68),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 24, y: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .environment(\.colorScheme, .light)
    }
}
