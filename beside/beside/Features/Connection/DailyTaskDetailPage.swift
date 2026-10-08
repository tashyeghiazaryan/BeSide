import SwiftUI

/// Full-screen daily task — navy surface matching the Daily Task card, with the user's prompt + Mark as done.
struct DailyTaskDetailPage: View {
    let userTask: String
    let onBack: () -> Void
    let onMarkDone: () -> Void

    private var ink: Color { Color(hex: 0x1A1A2E) }

    var body: some View {
        ZStack {
            BeSideColor.navyFill
                .ignoresSafeArea()

            // Soft depth highlights on the navy plate
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -100, y: -180)
                .allowsHitTesting(false)

            Circle()
                .fill(Color(hex: 0xFBCFE8).opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 120, y: 280)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 24)
                content
                Spacer(minLength: 24)
                softPinkButton(title: "Mark as done", showArrow: true, action: onMarkDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("connection.activity.done")
            }
        }
        .hidesFloatingTabBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection.activity.detail")
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 12, weight: .light))
                    }
                    .foregroundStyle(Color.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("connection.activity.detail.back")

                Spacer()
            }

            HStack(spacing: 8) {
                BesideLogoMark(size: 28)
                Text("beside")
                    .font(.system(size: 22, weight: .ultraLight))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Task")
                .font(.system(size: 11, weight: .regular))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.45))
                .frame(maxWidth: .infinity)

            Text("You")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.4))

            Text(userTask)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
    }

    private func softPinkButton(title: String, showArrow: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.4)
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .medium))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(ink.opacity(0.78))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFDF2F8), Color(hex: 0xFBCFE8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: 0xFBCFE8).opacity(0.35), radius: 10, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
