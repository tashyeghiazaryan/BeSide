# Proposal

## Why

The Us home Shared Memories block is still a no-op stub. Shared Memories is the couple photo-and-caption surface in the Figma Make Us reference: a home carousel, add flow, gallery with date filters, and a detail viewer with share. Shipping this slice completes the last major Us home entry after Important Dates and Love Notes.

## What Changes

- Add a `SharedMemory` session model (id, title, dateTime, optional description, mood emoji, optional photo, likes / likedByMe, addedByUser) with demo seeds (one seeded “Evening on the rooftop” plus sample user-added moments).
- Wire the Us home **Shared Memories** section: matte glass shell, header opens the gallery, `+` opens Add, horizontal swipe carousel of memory cards (photo or mood placeholder), page dots, empty copy when none exist; card tap opens detail; share on the card uses the system share sheet.
- Build an **Add memory** frosted-glass modal: title (required), date/time, optional description, PhotosPicker (and optional URL for demo parity), mood emoji picker, “Share a memory” CTA — commits to the session store, marks `addedByUser`, refreshes carousel, and opens the gallery.
- Build a **Shared Memories gallery** full-screen page (slide-from-right): back, “Moments you added” subtitle, month filter chips (All + months present), 2-column grid of **user-added** memories only, empty states, `+` / CTA to Add.
- Build a **Memory detail** overlay: photo or mood hero, title, date, description, Share CTA; horizontal swipe to adjacent memories in the full list; dismiss via Close or scrim.
- Keep Wishlist on Important Dates as a separate existing flow; this change does not alter wishlist behavior.

## Capabilities

### New Capabilities
- `shared-memories`: Session-backed shared memories on Us — home carousel, add modal, user-added gallery with date filter, detail viewer, and share.

### Modified Capabilities
- `us-screen`: Shared Memories section and its `+` / gallery affordances become functional (were stubs). Wishlist on Important Dates is unchanged by this slice.

## Impact

- **New files**: `UsSharedMemory.swift`, `SharedMemoryAddModal.swift`, `SharedMemoriesPage.swift`, `SharedMemoryDetailOverlay.swift` (names may match Important Dates / Love Notes file conventions).
- **Modified files**: `MeSessionStore.swift` (memories array + add/like/share helpers), `UsView.swift` (section wiring, overlays, navigation).
- **Design system**: Reuse `BeSideColor` / `BeSideBackground` / glass patterns; extract only if a second use appears.
- **Photos**: Follow Wishlist’s `PhotosPicker` + in-memory image data pattern (session-only; no backend upload).
- **No new dependencies.**
