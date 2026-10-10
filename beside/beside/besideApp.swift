import SwiftUI

@main
struct besideApp: App {
    init() {
        AppBackend.shared.validateLaunchConfiguration()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                // Soft light canvas + glass materials stay light regardless of system appearance.
                .preferredColorScheme(.light)
        }
    }
}
