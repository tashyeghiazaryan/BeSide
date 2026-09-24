# Tasks

## 1. Mood catalog and session state

- [x] 1.1 Add `Mood` / `MoodCatalog` under `beside/beside/Features/Me/` with the six moods (ids, display names, colors, gradient stops, smoke patterns, SF Symbols) and `needsByMood` wish lists matching `design-reference` `moods.tsx`. Verify unit or preview access returns six moods and three wishes for `calm`.
- [x] 1.2 Add `MeSessionStore` with selection, share phase, history (including reference-style seed entries), current shared mood, and expanded day; wire create/inject from `RootTabView` or `besideApp` into `MeView`. Verify leaving Me and returning keeps history in the same process.

## 2. Me screen UI (Figma Make look)

- [x] 2.1 Replace `MeView` placeholder with scrollable Me layout on a soft gradient canvas with default ambient blurs (and mood-tinted blurs when a mood is selected): greeting, “How are you feeling?”, glass current-mood panel, mood grid, conditional wish list, share control, week strip. Keep `screen.me` on the root. Verify Me no longer shows only the word “Me” and panels read as frosted glass, not flat opaque cards.
- [x] 2.2 Implement `MoodSphereView` grid: gradient orbs, glow, smoke-pattern animation, icon, selection ring, dim siblings when one is selected; wire select/deselect (clear wish on change). Verify Calm shows its three wishes and deselecting mood hides wishes; spheres match reference colors more than plain tinted circles.
- [x] 2.3 Style wish cards and share control with glass + selected-mood tint; implement local share sequence (Sending → Sent → append history, update current, clear selection) with no network. Verify share works offline and success styling is visible.
- [x] 2.4 Implement seven-day week strip in a glass card with micro-spheres / empty dashed days and expand/collapse for days with entries. Verify Today is the last slot and empty days do not expand.

## 3. Shell and tests

- [x] 3.1 Adjust shell UI coverage so Me content is allowed while Partner/Us/Connection/More stay placeholders; keep five-tab order and default Me. Verify `testTabShellSwitchesPlaceholders` (or successor) still passes.
- [x] 3.2 Add a Me UI test: open Me, select a mood, select a wish, share, assert current-mood panel shows that mood/wish and week strip exists. Verify the test passes on an iOS simulator.
- [x] 3.3 Visually compare the Me tab in the iOS simulator against the design-reference Main app → Me frame (panels, spheres, ambient tint, week strip) and fix obvious visual gaps before marking the change done. Verify the side-by-side check is recorded as done in the task checkbox.
