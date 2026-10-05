# Design

## Context

Us already ships Important Dates, Love Notes, and Wishlist. Shared Memories is the last major home block still stubbed. Figma Make `UsScreen.tsx` defines the carousel shell, Add modal, gallery (user-added only + month filters), detail overlay, and share. Session data lives in `MeSessionStore`; Wishlist already demonstrates `PhotosPicker` + in-memory image bytes.

## Goals / Non-Goals

**Goals:**
- Functional home carousel, Add modal, gallery with date filter, detail overlay, and system share.
- Visual alignment with Us glass / matte chrome language.
- Session-only store with demo seeds; PhotosPicker for photos (Wishlist pattern).

**Non-Goals:**
- No backend sync, cloud photo upload, or persistence across relaunches.
- No like/heart toggle UI (model may keep `likes` / `likedByMe` for seed parity; Figma detail currently emphasizes Share, not like).
- Edit / delete are in scope (feed ⋯ menu + gallery long-press): reuse Add modal for edit; confirm before delete.
- No changes to Important Dates, Love Notes, or Wishlist flows beyond wiring Shared Memories.

## Decisions

### 1. Model: `UsSharedMemory` in session store
**Choice:** Struct with `id`, `title`, `dateTime`, `description?`, `mood`, `photoData` / displayable image reference, `likes`, `likedByMe`, `addedByUser`. Seed one curated non-user memory and a couple of `addedByUser` demos.
**Rationale:** Matches Figma `SharedMemory` and Important Dates / Love Notes store patterns.
**Alternative:** Separate store class — rejected; extra wiring for no gain.

### 2. Photo storage: in-memory data like Wishlist
**Choice:** Optional `Data` (or existing Wishlist URL/data helper) from `PhotosPicker`; no remote URL field required in product UI (optional URL omitted on iOS unless trivial).
**Rationale:** Wishlist already solved picker + preview; blob URLs are a web concern.
**Alternative:** Photos library asset identifiers — heavier; deferred.

### 3. Gallery filters user-added only
**Choice:** Home carousel shows all memories; gallery grid filters `addedByUser == true` with All + month chips.
**Rationale:** Exact Figma behavior (“Moments you added”).

### 4. Files: one surface per file
| File | Role |
|------|------|
| `UsSharedMemory.swift` | Model + seeds + validation |
| `SharedMemoryAddModal.swift` | Add glass modal |
| `SharedMemoriesPage.swift` | Gallery + filters |
| `SharedMemoryDetailOverlay.swift` | Detail + swipe + share |

Wire from `UsView` via `@State` presentation flags, same as dates / love notes.

### 5. Share
**Choice:** `ShareLink` / `UIActivityViewController` with text summary (mood, title, date, description). Include photo in share payload when available if straightforward.
**Rationale:** Matches Figma `navigator.share` / clipboard fallback intent on iOS.

## Risks / Trade-offs

- **Session-only**: Memories reset on relaunch — acceptable for prototype.
- **Large photo Data in memory**: Cap picker images (e.g. downscale like Wishlist if present) to avoid memory spikes.
- **Carousel gesture vs tap**: Need drag threshold so swipe doesn’t open detail (Figma uses a dragged ref).
