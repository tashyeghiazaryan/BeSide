# Design

## Context

See `proposal.md` for why this slice exists. Requirements are in `specs/ios-app-shell/spec.md`.

`beside/beside.xcodeproj` is a fresh SwiftUI app (iOS 18.5, Swift 5). `besideApp` builds a SwiftData `ModelContainer` for `Item` and shows `ContentView`, the template split list. Sources live under `beside/beside/` in a synchronized root group, so files added or removed there do not need `project.pbxproj` edits.

`design-reference/src/app/App.tsx` is the signed-in shell: `navItems` order is Me, Partner, Us, Connection, More, and `activeTab` starts at `"me"`. Partner, Us, Connection, and More are separate components. Me is inline in `App.tsx`. Auth is a second phone frame (`AuthScreen`), not a tab. The reference tab bar is a custom liquid-glass control; this slice does not reproduce it.

## Goals / Non-Goals

**Goals:**

- One `TabView` is the app root, with a stable tab enum and one SwiftUI view per reference screen.
- Placeholders are obvious in the simulator and in UI tests.
- The template model and list are gone from the launch path.

**Non-Goals:**

- Liquid-glass tab bar, mood gradients, typography, or any screen content from the reference.
- Navigation stacks inside a tab beyond what a placeholder needs to show its name.
- SwiftData, networking, or a shared app state object. There is nothing to store yet.

## Decisions

### Native `TabView`, not a custom bar

Use `TabView` with `.tabItem` labels. The request is a navigation frame; the reference bar is visual design for a later slice.

Alternative: port the liquid-glass bar now. Rejected because it adds motion and styling without changing the shell contract, and it would be thrown away or heavily revised when screens land.

### Tab identity in one enum

`AppTab` (`me`, `partner`, `us`, `connection`, `more`) owns title, SF Symbol, and accessibility identifier. `RootTabView` binds `TabView(selection:)` to `AppTab` and defaults to `.me`.

Symbols, matched to the reference icons: `person` (Me), `person.2` (Partner), `heart` (Us), `sparkles` (Connection), `ellipsis` (More).

### One file per screen, shared placeholder body

Layout under `beside/beside/`:

- `App/AppTab.swift`
- `App/RootTabView.swift`
- `Features/Me/MeView.swift`
- `Features/Partner/PartnerView.swift`
- `Features/Us/UsView.swift`
- `Features/Connection/ConnectionView.swift`
- `Features/More/MoreView.swift`

Each feature view is a thin wrapper around one private `TabPlaceholder` (title + accessibility identifier `screen.<tab>`). Wrappers stay so the next slice can replace a body without touching the tab shell. `TabPlaceholder` can live next to `RootTabView`; it is not a feature.

Visible placeholder copy is the tab title only, centered. Tab bar items use the same titles, with identifiers `tab.<tab>`, so tests can tell the bar button from the screen label.

### Drop SwiftData from this target

`besideApp` presents `RootTabView()` and does not attach `.modelContainer`. Delete `ContentView.swift` and `Item.swift`. No replacement store.

Alternative: keep the container unused. Rejected because an empty schema still crashes launch on container failure and implies persistence this slice does not have.

### UI test covers the shell

Replace `testExample` in `besideUITests` with a test that launches the app, checks the five tab buttons in order, confirms `screen.me` is present, taps each other tab, and confirms the matching `screen.*` identifier. Leave `testLaunchPerformance` as-is.

## Risks / Trade-offs

- [System tab bar will not look like the Figma bar] → Accepted for this slice. Tab names, order, and screen boundaries stay aligned so a later visual pass can restyle the bar without moving features.
- [A simulator that already ran the template may still have an `Item` store on disk] → The app no longer opens it. No migration. Delete the app from the simulator if a stale store is confusing during development.
- [Five near-empty views look redundant] → They are the attachment points named in the reference. Collapsing them into one view parameterized only by title would make the next slice a restructuring.

## Migration Plan

Local only. Replace the root view, delete the template model and list, run the app and the UI test on the iOS simulator. Rollback is reverting the change; there is no shipped user data.

## Open Questions

None. Visual tokens and whether Me stays a single view or splits like the reference sections can wait until those screens are specified.
