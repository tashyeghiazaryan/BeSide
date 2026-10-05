# Design

## Context

See `proposal.md` for why. Spec delta: `us-screen`.

Us home from `us-shell` already shows an Important Dates tile with seeded nearest-date preview and no-op taps. Figma Make `UsScreen.tsx` defines the list and add-calendar modals (Auth-styled glass overlay).

## Goals / Non-Goals

**Goals:**
- Wire tile → list modal and + → add calendar modal 1:1 with reference structure.
- Session-local seeded + custom dates; live nearest-date tile preview.
- Keep Wishlist control and other Us tiles stubbed.

**Non-Goals:**
- Wishlist / Love Notes / Shared Memories flows.
- Edit, delete, or reorder dates.
- Premium paywall / `isPremium` gating (demo allows add).
- Disk persistence or calendar system integration.
- Marking memory/gallery days on the add calendar (reference marks memory days; optional skip unless cheap).

## Decisions

1. **Extend `us-screen`** — No new capability path; Important Dates is part of Us.

2. **Session model** — Add `[UsImportantDate]` (id, title, date, optional kind/color) on `MeSessionStore`, replace the three nearest-preview fields with derived `nearestImportantDate` from the full list. Seed base dates matching Figma defaults (anniversary, partner birthday, special day, Valentine’s, New Year, next date together).

3. **Modals as SwiftUI overlays** — Full-screen ZStack scrim + card on `UsView` (or small `ImportantDatesListModal` / `ImportantDatesAddModal` files under `Features/Us/`), not NavigationStack push.

4. **Add UX** — Match Figma two-step Add (expand fields → commit) and brief success styling; DatePicker-free custom month grid like the reference for visual parity.

5. **Wishlist + on tile** — + opens add modal; Gift remains no-op until wishlist slice.

## Risks / Trade-offs

- [Custom calendar grid vs `DatePicker`] → Prefer grid for Figma parity; more code, clearer QA vs reference.
- [Annual recurrence] — Seeded annual dates use next occurrence from today (same as Figma `getNextAnnualOccurrence`).
- [Memory day dots on calendar] — Skip unless already have memory data; document as deferred.

## Migration Plan

- Replace stub handlers in `UsView`; keep accessibility ids; add modal ids for UI tests.
- No data migration.

## Open Questions

- None blocking; memory-day markers deferred.
