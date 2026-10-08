import SwiftUI

/// Brand mark from the app icon — soft lavender→pink plate with the rounded white B.
struct BesideLogoMark: View {
    var size: CGFloat = 28

    var body: some View {
        Image("BesideLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        BesideLogoMark(size: 28)
        BesideLogoMark(size: 44)
        BesideLogoMark(size: 88)
    }
    .padding()
}
