# Proposal

## Why

The Xcode target `beside` still launches the SwiftData template (`ContentView` + `Item`), so there is no native place to hang BeSide screens. The Figma Make reference in `design-reference/` already defines the signed-in app as five tabs — Me, Partner, Us, Connection, More — and the first slice should lock that navigation before mood, pairing, auth, or backend work.

## What Changes

- Replace the template root with a SwiftUI `TabView` that shows five tabs in design-reference order: Me, Partner, Us, Connection, More.
- Give each tab an empty placeholder screen that identifies the tab and does nothing else.
- Mirror the reference’s screen split in the app target: one view per main screen, with Me as the default tab.
- Remove the unused SwiftData template (`Item`, in-memory/on-disk `ModelContainer`, list CRUD) from the launch path. No persistence is in this slice.
- Leave auth, mood sharing, partner data, Connection activities, Us content, and More settings out of this slice. The reference `AuthScreen` is a separate frame and is not part of the main tab shell.

## Capabilities

### New Capabilities

- `ios-app-shell`: Signed-in navigation shell — five-tab `TabView`, default Me, placeholder content per tab, no backend or auth.

### Modified Capabilities

- None. There are no existing specs.

## Impact

- App target `beside/beside`: `besideApp.swift` stops owning a SwiftData container; `ContentView.swift` and `Item.swift` are replaced by the shell and five feature views. The project uses synchronized root groups, so new Swift files under `beside/beside` are picked up without `project.pbxproj` edits.
- UI tests in `beside/besideUITests` currently only launch the app. They should assert the five tabs and that switching shows the matching placeholder.
- `design-reference/` stays a visual source of tab names, order, and screen boundaries. This slice does not port liquid-glass styling, mood spheres, or screen content.
- No new dependencies, network, accounts, or deployment-target change (iOS 18.5, Swift 5).
