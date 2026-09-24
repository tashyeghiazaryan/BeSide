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
}
