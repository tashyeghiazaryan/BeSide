import SwiftUI

@main
struct besideApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                // Soft light canvas + glass materials stay light regardless of system appearance.
                .preferredColorScheme(.light)
        }
    }
}
