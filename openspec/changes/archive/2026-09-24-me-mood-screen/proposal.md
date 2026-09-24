# Proposal

## Why

The Me tab is still an empty placeholder, while the Figma Make reference already defines the product’s core loop: pick a mood, choose a wish, “share” it, and see this week’s mood history. Filling Me next makes the shell feel like BeSide without waiting on Partner, auth, or a backend.

## What Changes

- Replace the Me placeholder with an interactive Me screen that follows the Main app → Me frame in `design-reference` for both flow and look (greeting, glass current-mood panel, six liquid mood spheres, glass wish cards, share states, weekly history strip).
- Match the reference’s visual language on Me: soft multi-stop background, mood-tinted ambient blurs, frosted-glass panels, gradient spheres with inner smoke-like motion, selection ring, and mood-colored share / wish emphasis.
- Keep all mood/wish/history state on-device for this session (in memory). Share does not leave the phone.
- Seed the week history with the same style of mock entries the reference uses, so the week strip is not empty on first launch.
- Leave ambient mood audio, liquid-glass system tab bar restyle, and Partner reaction chip on Me for later slices.
- **BREAKING** (spec): Me is no longer a featureless placeholder. Partner, Us, Connection, and More stay placeholders.

## Capabilities

### New Capabilities

- `me-screen`: Local Me tab — mood pick, wish pick, local share, current mood, weekly history, Figma Make visual treatment.

### Modified Capabilities

- `ios-app-shell`: Me may show real Me content; only the other four tabs remain empty placeholders without feature actions.

## Impact

- App target under `beside/beside/Features/Me/` and shared mood catalog types; `MeView` stops using `TabPlaceholder`.
- Shell UI test must still pass for tab order; Me-specific UI coverage is added for pick → wish → share and week strip presence.
- No networking, persistence beyond the current app process, auth, Partner reaction UI, or audio.
- Does not change tab names, order, or default tab (Me).
