import SwiftUI
import UIKit

/// Story sticker rendered for Instagram Stories share — soft BeSide couple card.
struct CoupleStoryShareCard: View {
    let meName: String
    let partnerName: String
    let mePhoto: UIImage?
    let partnerPhoto: UIImage?
    let subtitle: String

    private let ink = Color(hex: 0x26282B)
    private let rose = Color(hex: 0xE8BEC9)
    private let roseLight = Color(hex: 0xF3D6DE)
    private let roseDeep = Color(hex: 0xD9A8B6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                BesideLogoMark(size: 22)
                Text("beside")
                    .font(.system(size: 16, weight: .ultraLight))
                    .tracking(1.0)
                    .foregroundStyle(ink.opacity(0.55))
                Spacer(minLength: 0)
            }
            .padding(.bottom, 28)

            HStack {
                Spacer(minLength: 0)
                HStack(spacing: -14) {
                    avatar(image: mePhoto, name: meName)
                    avatar(image: partnerPhoto, name: partnerName)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 20)

            Text("\(meName) & \(partnerName)")
                .font(.system(size: 32, weight: .thin))
                .tracking(0.35)
                .foregroundStyle(ink.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

            Text(subtitle)
                .font(.system(size: 18, weight: .light))
                .tracking(0.15)
                .foregroundStyle(Color(hex: 0xC48A9A))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 32)
        .frame(width: 340)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color(hex: 0xFAF6F8),
                            Color(hex: 0xF3EEF6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1.2)
                }
                .shadow(color: ink.opacity(0.1), radius: 24, y: 12)
        }
    }

    private func avatar(image: UIImage?, name: String) -> some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(ink.opacity(0.72))
            }
        }
        .frame(width: 56, height: 56)
        .background {
            Circle()
                .fill(rose.opacity(0.18))
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    roseLight.opacity(0.4),
                                    rose.opacity(0.34),
                                    roseDeep.opacity(0.3),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color.white.opacity(0.9), lineWidth: 2)
        }
    }
}
