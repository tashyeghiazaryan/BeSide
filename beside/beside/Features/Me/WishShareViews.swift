import SwiftUI

struct WishListView: View {
    let mood: Mood
    let wishes: [String]
    let selectedWish: String?
    @Binding var customWish: String
    var fieldError: WishShareAlert?
    var isCustomFieldFocused: FocusState<Bool>.Binding
    let onSelect: (String) -> Void

    private var isCustomSelected: Bool {
        let trimmed = customWish.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && selectedWish == trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your wishes...")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(BeSideColor.textTertiary)
                .padding(.leading, 4)

            ForEach(Array(wishes.enumerated()), id: \.offset) { index, wish in
                let isSelected = selectedWish == wish
                Button {
                    isCustomFieldFocused.wrappedValue = false
                    onSelect(wish)
                } label: {
                    Text(wish)
                        .font(.system(size: 16, weight: isSelected ? .regular : .light))
                        .foregroundStyle(isSelected ? BeSideColor.wishText : BeSideColor.wishTextIdle)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background { wishChrome(isSelected: isSelected, hasError: false) }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("wish.\(mood.id).\(index)")
            }

            VStack(alignment: .leading, spacing: 6) {
                TextField("Or write your own…", text: cappedCustomWish, axis: .vertical)
                    .font(.system(size: 16, weight: isCustomSelected ? .regular : .light))
                    .foregroundStyle(BeSideColor.wishText)
                    .lineLimit(1...3)
                    .focused(isCustomFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { isCustomFieldFocused.wrappedValue = false }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .padding(.bottom, 12)
                    .background {
                        wishChrome(
                            isSelected: isCustomSelected || isCustomFieldFocused.wrappedValue,
                            hasError: fieldError == .invalidWish || fieldError == .emptyWish
                        )
                    }
                    .accessibilityIdentifier("wish.custom")
                    .overlay(alignment: .bottomTrailing) {
                        Text("\(customWish.count)/\(WishTextRules.maxLength)")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(
                                customWish.count >= WishTextRules.maxLength
                                    ? Color(hex: 0xE11D48).opacity(0.85)
                                    : BeSideColor.textTertiary
                            )
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                    }

                if let message = fieldError?.inlineMessage {
                    Text(message)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color(hex: 0xE11D48))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .accessibilityIdentifier(
                            fieldError == .emptyWish ? "wish.error.empty" : "wish.error.invalid"
                        )
                }
            }
            .id("wish.custom.block")
        }
    }

    /// Hard-caps at 80 characters so TextField cannot keep overflow in its buffer.
    private var cappedCustomWish: Binding<String> {
        Binding(
            get: { customWish },
            set: { newValue in
                let limited = WishTextRules.limitLength(WishTextRules.normalizeInput(newValue))
                customWish = limited
                if WishTextRules.normalizeInput(newValue).count > WishTextRules.maxLength {
                    let snapped = limited
                    Task { @MainActor in
                        customWish = snapped
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func wishChrome(isSelected: Bool, hasError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                            ? mood.color.opacity(0.22)
                            : Color.white.opacity(0.35)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        hasError
                            ? Color(hex: 0xE11D48).opacity(0.85)
                            : (isSelected ? mood.color.opacity(0.45) : Color.white.opacity(0.5)),
                        lineWidth: hasError ? 1.5 : 1
                    )
            }
    }
}

struct ShareMoodButton: View {
    let mood: Mood
    let phase: SharePhase
    let enabled: Bool
    /// Visual emphasis when a valid wish is ready (idle only).
    var looksReady: Bool = true
    let action: () -> Void

    var body: some View {
        Group {
            switch phase {
            case .idle:
                Button(action: action) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                        Text("Share with partner")
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(BeSideColor.shareIdleText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background { shareBackground(tint: mood.color.opacity(0.22)) }
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .opacity(looksReady ? 1 : 0.55)
                .accessibilityIdentifier("share.button")

            case .sending:
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Sending...")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(BeSideColor.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background { shareBackground(tint: mood.color.opacity(0.16)) }
                .accessibilityIdentifier("share.sending")

            case .sent:
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                    Text("Sent!")
                }
                .font(.system(size: 16, weight: .light))
                .tracking(0.6)
                .foregroundStyle(BeSideColor.navyLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BeSideColor.navyFill)
                }
                .accessibilityIdentifier("share.sent")
            }
        }
    }

    @ViewBuilder
    private func shareBackground(tint: Color, border: Color? = nil) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(border ?? mood.color.opacity(0.28), lineWidth: 1.2)
            }
            .shadow(color: mood.color.opacity(0.12), radius: 12, y: 4)
    }
}
