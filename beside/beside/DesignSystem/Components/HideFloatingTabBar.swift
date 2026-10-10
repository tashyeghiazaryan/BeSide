import SwiftUI

/// Child screens set `true` to hide the root floating tab bar (e.g. full-screen Connection task detail).
struct HideFloatingTabBarKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Connection carousel requests dark chrome; inner hubs leave this `false` for the light bar.
struct DarkFloatingTabBarKey: PreferenceKey {
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

    /// Request dark translucent tab chrome (Connection carousel only).
    func prefersDarkFloatingTabBar(_ dark: Bool = true) -> some View {
        preference(key: DarkFloatingTabBarKey.self, value: dark)
    }
}
