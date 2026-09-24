import SwiftUI

/// Soft glass mood sphere aligned to Figma Make (`App.tsx` Me spheres).
/// Layout size matches `size`; glow is drawn outside that box but does not expand the grid.
struct MoodSphereView: View {
    let moodID: String
    let name: String
    let color: Color
    let gradientColors: [Color]
    let icon: MoodIconKind
    let isSelected: Bool
    let hasSelection: Bool
    let size: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.56),
                                color.opacity(0.31),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(hasSelection && !isSelected ? 0.22 : 0.38)
                    .blur(radius: size * 0.28)
                    .clipShape(Circle())

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if hasSelection && !isSelected {
                    Circle().fill(Color.white.opacity(0.3))
                }

                MoodIcon(kind: icon, size: size * 0.44)
                    .foregroundStyle(Color.white.opacity(hasSelection && !isSelected ? 0.5 : 0.95))
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            }
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(isSelected ? 0.85 : 0.4),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .shadow(
                color: isSelected ? color.opacity(0.35) : .clear,
                radius: isSelected ? 10 : 0
            )
            .scaleEffect(hasSelection && !isSelected ? 0.88 : 1)
            .background {
                // Soft aura — does not affect layout width
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(isSelected ? 0.45 : 0.28),
                                color.opacity(0.12),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: size * 0.9
                        )
                    )
                    .frame(width: size * 1.45, height: size * 1.45)
                    .blur(radius: size * 0.18)
                    .opacity(glowOpacity)
                    .scaleEffect(hasSelection && !isSelected ? 0.85 : 1)
                    .allowsHitTesting(false)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.55) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 1.15, height: size * 1.15)
                    .blur(radius: size * 0.28)
                    .opacity(hasSelection && !isSelected ? 0.1 : 0.2)
                    .allowsHitTesting(false)
            }

            Text(name)
                .font(.system(size: 11, weight: isSelected ? .regular : .light))
                .foregroundStyle(labelColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("mood.\(moodID)")
    }

    private var labelColor: Color {
        if isSelected { return Color.black.opacity(0.85) }
        if hasSelection { return Color.gray.opacity(0.35) }
        return Color.gray.opacity(0.7)
    }

    private var glowOpacity: Double {
        if isSelected { return 0.55 }
        if hasSelection { return 0.12 }
        return 0.35
    }
}
