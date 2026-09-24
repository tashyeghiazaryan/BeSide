# Tasks

## 1. Tab shell

- [x] 1.1 Add `beside/beside/App/AppTab.swift` with cases `me`, `partner`, `us`, `connection`, `more`, in that order, each with title Me / Partner / Us / Connection / More, SF Symbol `person` / `person.2` / `heart` / `sparkles` / `ellipsis`, and accessibility identifiers `tab.<case>` and `screen.<case>`. Verify the file compiles as part of the `beside` target (synchronized group; no `project.pbxproj` edit).
- [x] 1.2 Add `beside/beside/App/RootTabView.swift` with a `TabView(selection:)` defaulting to `.me`, one `.tabItem` per `AppTab`, and a private `TabPlaceholder` that centers the tab title and sets `screen.<tab>`. Verify a preview or build shows five tabs and the Me placeholder on first appearance.
- [x] 1.3 Add thin wrappers `Features/Me/MeView.swift`, `Features/Partner/PartnerView.swift`, `Features/Us/UsView.swift`, `Features/Connection/ConnectionView.swift`, and `Features/More/MoreView.swift`, each rendering `TabPlaceholder` for its tab only. Verify none of them import SwiftData or add buttons, lists, or navigation destinations.

## 2. Launch path

- [x] 2.1 Point `besideApp` at `RootTabView()` and remove the SwiftData `ModelContainer`, `import SwiftData`, and `.modelContainer`. Verify the app source no longer references `Item` or `ContentView`.
- [x] 2.2 Delete `beside/beside/ContentView.swift` and `beside/beside/Item.swift`. Verify `xcodebuild` for the `beside` scheme succeeds and the template add/delete item list is gone.

## 3. Shell UI test

- [x] 3.1 Replace `testExample` in `beside/besideUITests/besideUITests.swift` with a test that launches the app, asserts tab buttons `tab.me` through `tab.more` exist in order, asserts `screen.me` is present, then taps Partner, Us, Connection, More, and Me and asserts only the matching `screen.*` identifier is present after each tap. Verify the UI test passes on an iOS simulator and `testLaunchPerformance` is left unchanged.
