# Design

## Context

See `proposal.md` for why. Requirements: `specs/me-screen/spec.md` and the `ios-app-shell` delta.

The app already opens on a five-tab shell; `MeView` is a `TabPlaceholder`. Mood catalog and flow live in `design-reference/src/app/components/moods.tsx` and the Me block of `App.tsx`: six moods, `needsByMood` wishes, current-mood panel, share with brief “Sending…” / “Sent!”, week strip with expand, liquid-glass panels, gradient spheres with per-mood smoke motion, and mood-tinted ambient blurs.

`RootTabView` only mounts the selected tab’s content (others are `Color.clear`) so shell UI tests see one `screen.*` at a time. Me session state must therefore live outside `MeView` or it resets when leaving the tab.

## Goals / Non-Goals

**Goals:**

- Me tab matches the reference’s information structure and interaction order (greet → current → pick mood → pick wish → share → week).
- Catalog data (ids, names, colors, gradients, wishes, smoke patterns) matches `moods.tsx`.
- Visual fidelity to the Figma Make Me frame: frosted panels, sphere grid, ambient blurs, mood-colored wish/share emphasis, week micro-spheres.

**Non-Goals:**

- Restyling the system tab bar into the reference’s floating liquid-glass bar (shell stays native `TabView` for now).
- Ambient audio signatures per mood.
- Partner reaction chip on the current-mood panel (Partner screen owns that later).
- Disk persistence, sync, or real partner delivery.
- Changing how non-Me tabs work beyond updating the shell spec.

## Decisions

### Session store owned above MeView

`MeSessionStore` (`@Observable` or `ObservableObject`) holds selected mood/wish, share phase, history, and expanded day. Create it in `besideApp` or `RootTabView` and inject into `MeView`. Survives tab switches while the process is alive.

Alternative: `@State` only inside `MeView`. Rejected because unmounting Me clears history mid-session.

### Catalog as static Swift models

`Mood` + `MoodCatalog` with the six moods and wish strings from the reference, including hex colors, gradient stops, and `smokePattern` (`floating`, `swirling`, `expanding`, `falling`, `chaotic`). SF Symbols mapped to Lucide: leaf → `leaf.fill`, sparkles → `sparkles`, heart → `heart.fill`, cloud → `cloud.fill`, battery → `battery.25`, zap → `bolt.fill`.

### Mood sphere = animated glass orb

Implement `MoodSphereView` as a circular control: outer glow, gradient fill, moving translucent “smoke” overlay driven by `smokePattern` (SwiftUI animation on offset/scale/rotation — not a particle system), glass highlight, icon, and white selection ring. Dim non-selected spheres when any mood is selected. Prefer closeness to `App.tsx` sphere styling over a flat tinted circle.

### Glass panels and ambient canvas

Screen background: light gray→white gradient plus default green/pink/yellow ambient blurs; when a mood is selected, swap blurs to that mood’s gradient at low opacity (as in the reference). Current-mood panel, wish cards, share button, and week card use ultra-thin material / custom translucent white fills, light borders, and soft shadows — not opaque solid cards.

### Share is a short local async sequence

On share: disable control → “Sending…” (~1s) → “Sent!” (~2s) → append `SharedMood` to history, set as current, clear selection. No `URLSession`. Style sending/sent states with mood tint / lavender success like the reference.

### Week strip

Seven days ending today; seed with the same day-offset pattern as `generateInitialHistory` in the reference (translated to Swift). Filled days use small gradient spheres; empty days use dashed hollow circles. Tap toggles expansion for that day only.

### Layout under Features/Me

- `MeView.swift` — screen composition and ambient background  
- `MeSessionStore.swift` — state  
- `Mood.swift` / `MoodCatalog.swift` — catalog  
- `MoodSphereView.swift`, `CurrentMoodPanel`, `WishList`, `ShareMoodButton`, `WeekMoodStrip`, shared `GlassPanel` styling helper as needed  

Keep `screen.me` accessibility on the Me root so the shell test still finds Me when that tab is selected.

### Shell spec / tests

Update shell expectations: Me is contentful. Existing tab-order UI test stays; add a Me UI test for mood → wish → share → current panel / week strip. Adjust any assertion that required Me to be title-only. Visual fidelity is validated by side-by-side check against the design-reference Me frame in the simulator, not only by UITest identifiers.

## Risks / Trade-offs

- [SwiftUI smoke will not be pixel-identical to CSS motion] → Aim for the same patterns and timing feel; iterate if a sphere looks flat.
- [History lost on app kill] → Accepted for this slice; call out in non-goals.
- [English copy from reference] → Keep English strings for parity with the design reference; localization later.
- [Native tab bar still looks system-default] → Accepted; Me content matches Figma Make first.

## Migration Plan

Local only. Replace Me placeholder, inject session store, extend UI tests. Rollback is revert. No data migration.

## Open Questions

None. Display name for greeting can stay the reference default `"Anna"` until More/profile exists.
