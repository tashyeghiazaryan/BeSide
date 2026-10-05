# Proposal

## Why

The Us home shell shows an Important Dates tile as a stub. Figma Make already defines the list modal, add-date calendar flow, and live tile preview. Wiring that slice next unlocks the first interactive Us feature and replaces the no-op tile taps from `us-shell`.

## What Changes

- Make the Important Dates home tile interactive: tap opens the full dates list modal; the + control opens the add-date calendar modal (Wishlist control on the tile stays a stub for a later slice).
- Show seeded important dates (anniversary, birthdays, holidays, “Next date together”, etc.) plus user-added custom dates in-session.
- List modal: frosted glass overlay, scrollable rows with title, short date, countdown badge; dismiss via close or scrim.
- Add-date calendar modal: month navigation, day selection, title field, two-step Add (expand fields → commit); brief success state; updates the home tile nearest-date preview.
- Store important dates on the shared session store (local only); refresh nearest-date preview used by the Us tile.
- Update `us-screen` so Important Dates is a real flow; Love Notes / Shared Memories / Wishlist remain stubs.

## Capabilities

### New Capabilities
- (none — extends existing Us capability)

### Modified Capabilities
- `us-screen`: Important Dates list + add calendar replace stub no-ops; tile preview stays live from session dates.

## Impact

- `Features/Us/` — modals + date model helpers; wire `UsView` tile taps.
- `MeSessionStore` (or Us-facing API) — seeded + user-added important dates; nearest preview fields.
- Reuse DesignSystem glass / navy where it fits; Auth-style dates glass may stay local until second use.
- UI tests for opening list / add flows.
- Out of scope: Wishlist page, Love Notes, Shared Memories, disk persistence, premium paywall, edit/delete dates.
