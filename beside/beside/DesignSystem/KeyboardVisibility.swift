import Combine
import SwiftUI
import UIKit

enum KeyboardVisibility {
    /// `true` while the software keyboard is on screen.
    static var publisher: AnyPublisher<Bool, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }

    /// Keyboard overlap height in the key window, plus system animation timing.
    struct Frame: Equatable {
        var height: CGFloat
        var duration: TimeInterval
        var animation: Animation

        static let hidden = Frame(
            height: 0,
            duration: 0.25,
            animation: .easeOut(duration: 0.25)
        )
    }

    static func frame(from notification: Notification) -> Frame {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?
            .doubleValue ?? 0.25
        let curveRaw = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?
            .intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
        let animation: Animation = switch curve {
        case .easeIn: .easeIn(duration: duration)
        case .easeOut: .easeOut(duration: duration)
        case .linear: .linear(duration: duration)
        default: .easeInOut(duration: duration)
        }

        guard
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else {
            return Frame(height: 0, duration: duration, animation: animation)
        }

        let overlap = max(0, window.bounds.maxY - endFrame.origin.y)
        return Frame(height: overlap, duration: duration, animation: animation)
    }
}

/// Lifts content with the system keyboard curve instead of fighting UIKit safe-area avoidance.
struct SmoothKeyboardLiftModifier: ViewModifier {
    @State private var keyboard = KeyboardVisibility.Frame.hidden

    var extraBottom: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.height > 0 ? max(0, keyboard.height - 12) + extraBottom : 0)
            .animation(keyboard.animation, value: keyboard.height)
            .ignoresSafeArea(.keyboard)
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            ) { notification in
                // Set height without nested withAnimation so FocusState isn’t delayed.
                keyboard = KeyboardVisibility.frame(from: notification)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { notification in
                var next = KeyboardVisibility.frame(from: notification)
                next.height = 0
                keyboard = next
            }
    }
}

extension View {
    /// Pads the bottom to the keyboard height with the system curve.
    /// Use on **full-screen** roots (Auth). Do **not** use inside sheets — the sheet already
    /// avoids the keyboard; double-lifting clips the nav bar (Cancel over title, etc.).
    func smoothKeyboardLift(extraBottom: CGFloat = 8) -> some View {
        modifier(SmoothKeyboardLiftModifier(extraBottom: extraBottom))
    }
}
