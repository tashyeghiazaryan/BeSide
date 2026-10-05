# Tasks

## 1. Model and session store

- [x] 1.1 Create `UsSharedMemory.swift` with `UsSharedMemory` (id, title, dateTime, description, mood, photoData, likes, likedByMe, addedByUser), mood option list, and `demoSeed()` including at least one non-user and one user-added memory — verify the type compiles and seed is non-empty.
- [x] 1.2 Add `sharedMemories` to `MeSessionStore` with seed init, `addSharedMemory(...)` (requires non-empty title; sets addedByUser), and helpers for user-added / month filter keys — verify add prepends a user-added memory and filters exclude non-user items from the gallery list.

## 2. Add memory modal

- [x] 2.1 Build `SharedMemoryAddModal.swift`: centered frosted glass over scrim, title/subtitle, title field, date/time picker, optional description, PhotosPicker + preview, mood emoji chips, Share a memory CTA (blocked when title empty), Close/scrim dismiss — verify Add commits via callback and empty title does not.

## 3. Gallery page

- [x] 3.1 Build `SharedMemoriesPage.swift`: soft canvas, back + Shared Memories / Moments you added header, `+` opens Add, All + month filter chips, 2-column grid of user-added memories (photo or mood placeholder), empty states, cell tap opens detail — verify only user-added rows appear and month filter narrows the grid.

## 4. Detail overlay

- [x] 4.1 Build `SharedMemoryDetailOverlay.swift`: frosted detail with photo/mood hero, title, date, description, Share (system share sheet), Close/scrim dismiss, horizontal swipe to adjacent memories in the full list — verify Share presents and swipe changes the shown memory.

## 5. Wire Us home section

- [x] 5.1 Replace Shared Memories stub in `UsView.swift` with live carousel (swipe cards, dots, empty copy), header → gallery, `+` → Add, card tap → detail, card share → system share — verify gestures do not open detail after a drag.
- [x] 5.2 Add `@State` presentation for gallery, add modal, and detail (selected id) on `UsView` and ensure Add success opens gallery with filter All — verify end-to-end: `+` → add → gallery → detail → share → dismiss.

## 6. Verification

- [x] 6.1 Add/update UI tests for opening gallery from Shared Memories header, adding a memory, and opening detail from a carousel/gallery cell — verify tests compile and cover the happy path.
- [x] 6.2 Build (`xcodebuild build`) and spot-check carousel, Add modal, gallery filters, and detail against `design-reference` Shared Memories — verify no build errors and obvious visual gaps are addressed.

## 7. Edit / delete

- [x] 7.1 Add `updateSharedMemory` / `deleteSharedMemory` on `MeSessionStore` (same field validation as add; photo replace / remove) — verify update mutates in place and delete removes by id.
- [x] 7.2 Extend `SharedMemoryAddModal` for edit mode (prefill, Save changes, keep/replace/remove photo) — verify edit saves without creating a duplicate.
- [x] 7.3 Wire Edit/Delete from Instagram feed (⋯ menu) and gallery (context menu) with delete confirmation; after delete advance feed selection — verify both surfaces can edit and delete.
