import SwiftUI

/// Child screens set `true` to hide the root floating tab bar (e.g. full-screen Connection task).
struct HideFloatingTabBarKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Request that `RootTabView` hide the floating tab bar while this view is visible.
    func hidesFloatingTabBar(_ hide: Bool = true) -> some View {
        preference(key: HideFloatingTabBarKey.self, value: hide)
    }
}
