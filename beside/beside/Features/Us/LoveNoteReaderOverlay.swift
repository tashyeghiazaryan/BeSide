import SwiftUI

struct LoveNoteReaderOverlay: View {
    let note: LoveNote
    let partnerName: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            scrim.onTapGesture(perform: dismiss)
            card
        }
        .accessibilityIdentifier("us.lovenotes.reader")
    }

    private var scrim: some View {
        Color(hex: 0x26282B).opacity(0.80)
            .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 0) {
            Text("💌")
                .font(.system(size: 48))
                .padding(.bottom, 16)

            Text(note.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 12)

            if note.direction == .incoming {
                Text("— \(partnerName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0xFBCFE8).opacity(0.85))
                    .padding(.bottom, 24)
            } else {
                Text(outgoingStatusText)
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(.bottom, 24)
            }

            Button(action: dismiss) {
                Text("Close")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: 0x1A1A2E).opacity(0.88))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.65))
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 30/255, green: 27/255, blue: 40/255).opacity(0.95),
                            Color(red: 20/255, green: 18/255, blue: 28/255).opacity(0.98),
                        ],
                        startPoint: UnitPoint(x: 0.1, y: 0),
                        endPoint: UnitPoint(x: 0.9, y: 1)
                    )
                )
                .shadow(color: Color(hex: 0xF8BBD0).opacity(0.45), radius: 60)
                .shadow(color: Color(hex: 0xF472B6).opacity(0.28), radius: 100)
                .shadow(color: Color(hex: 0xF8BBD0).opacity(0.35), radius: 1)
        )
    }

    private var outgoingStatusText: String {
        if note.status == .read {
            return "They've read what you sent"
        }
        return "On its way — \(partnerName) will see it soon"
    }

    private func dismiss() {
        onDismiss()
    }
}
