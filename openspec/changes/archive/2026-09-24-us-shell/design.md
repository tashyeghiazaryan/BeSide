# Design

## Context

See `proposal.md` for why. Specs: `us-screen` and the `ios-app-shell` delta.

`UsView` is still `TabPlaceholder`. Figma Make `UsScreen.tsx` is the visual source for the home viewport. Later slices own dates/wishlist/memories/love-notes flows; this change only lays down the shell they will open from.

## Goals / Non-Goals

**Goals:**
- Us tab matches the reference home structure: ambient, hero, daily chips + tip, level/streak bar, dates/love-notes tiles, memories section chrome.
- Seeded demo data so the screen looks alive without a backend.
- Entry controls that will later open features are present but do not implement those features yet.

**Non-Goals:**
- Important dates list/calendar/add, wishlist, love notes page/composer, shared memories gallery/add/detail.
- Real notifications, photo upload, or server sync.
- Full couple-status Harmonia/Spark/Anchor/Storm modal and status-driven ambient retheme (optional later; home ambient can stay the reference pastel blurs).
- Updating `Требования полей.md` (manual QA checklist; optional follow-up, not required for this change).

## Decisions

1. **Capability name `us-screen`** — Parallel to `me-screen` / `partner-screen`. Subsequent slices modify or extend `us-screen` (or add focused capabilities that Us composes) rather than inventing a second home capability.

2. **Session data on existing store** — Extend `MeSessionStore` (or rename later) with Us home seeds: relationship start, display names already present, daily flags (`moodShared` / partner react / activity) mapped from App.tsx props, level/streak/points. Avoid a separate Us store until state splits naturally.

3. **Stub taps** — Prefer silent no-op (or disabled affordance styling only if reference requires) over “Coming soon” toasts, to keep visual QA clean. Accessibility labels still name the intended action.

4. **Memories / Love Notes preview** — Show static seed copy and layout from the reference empty or seeded tile states; do not port carousel gesture complexity until `shared-memories` / `love-notes` changes.

5. **DesignSystem** — Reuse soft canvas and `GlassPanel` where it matches; Us-specific butter/matte tile treatments may stay local until a second identical use appears (per design-system rule).

## Risks / Trade-offs

- [Stub tiles look tappable but do nothing] → Document in specs; next slice should wire the first tile immediately so the shell does not linger empty.
- [Daily flags vs Me/Partner truth] → Map seeds from existing session where possible; accept demo mismatch until Connection/activity exists.
- [UsScreen.tsx size] → Implement from the home viewport only; do not port modals “for later” into this PR.

## Migration Plan

- Rewrite `UsView`; keep `screen.us` / `tab.us` identifiers.
- Update UI tests that assert Us is placeholder-only.
- No data migration (in-memory seeds).

## Open Questions

- None blocking this slice; notifications action remains deferred.
