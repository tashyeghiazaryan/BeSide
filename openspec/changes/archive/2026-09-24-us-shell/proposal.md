# Proposal

## Why

Us is still a named-only placeholder while Me and Partner are real screens. Figma Make `UsScreen` is large; shipping it in slices keeps review and archive manageable. The first slice is the home shell — the couple hero, daily progress, long-term bar, and entry tiles — so later slices (dates, wishlist, memories, love notes) attach to a stable Us surface.

## What Changes

- Replace the Us tab placeholder with a native SwiftUI Us home that matches the first viewport of `design-reference` `UsScreen.tsx`: soft ambient canvas, couple names + time together + avatar bubbles, daily progress chips with tip popover, long-term level/streak progress bar.
- Show the home entry tiles visually (Important Dates preview, Love Notes preview, Shared Memories section chrome) with **seeded display data**; taps that open feature flows are **stubs** (no-op or no navigation) until later OpenSpec changes.
- Notifications bell may appear as chrome matching the reference; action is a no-op in this slice.
- Wire session/demo seed for relationship start date, display names, daily flags, level/streak/points — local only, no network.
- Update shell expectations so Us is real content, not a named-only placeholder.

## Capabilities

### New Capabilities
- `us-screen`: Us tab home shell — couple hero, daily progress, long-term progress, and stub entry tiles per Figma Make first viewport.

### Modified Capabilities
- `ios-app-shell`: Us tab shows Us screen content instead of a blank placeholder.

## Impact

- `Features/Us/` (rewrite `UsView`; likely small helper types for daily tasks / level seed).
- Session store: extend shared session (or a thin Us-facing API on the existing store) for names, relationship start, daily completion flags, level/streak — reuse Me/Partner pairing where flags already exist.
- Reuse `DesignSystem` (`GlassPanel`, soft canvas / ambient); extract repeated Us chrome only on second use.
- UI tests / shell tests that still expect Us as a named-only placeholder.
- Later changes: `important-dates`, `wishlist`, `shared-memories`, `love-notes` — out of scope here.
