# Tasks

## 1. Model and session store

- [x] 1.1 Create `UsLoveNote.swift` with `LoveNote` struct (id, body, createdAt, direction enum, status enum, readAt), body validation helper (max 100 chars, latin+digits+punctuation+emoji), body-length counter, body-preview truncation, and `LoveNote.demoSeed()` returning at least one incoming demo note — verify the struct compiles and seed returns a non-empty array.
- [x] 1.2 Add `loveNotes: [LoveNote]` array to `MeSessionStore` initialized with demo seeds, plus `sendLoveNote(body:) -> Bool` (validates, prepends outgoing note, returns true), `markNoteRead(id:)` (sets status to .read and readAt), and computed properties for tile state (`loveNotesTileKind`, incoming/outgoing filtered lists) — verify calling `sendLoveNote` adds an outgoing note and `markNoteRead` transitions status.

## 2. Compose modal

- [x] 2.1 Build `LoveNoteComposeModal.swift`: frosted-glass card centered over dimmed scrim, "Write a note" title, multiline text field (max 100 chars) with placeholder "Something warm for them…", character counter (current/100), "Send note" navy CTA disabled when empty, Close (×) button + scrim dismiss — verify modal shows on binding, Send calls `onSend` closure, empty body blocks Send.

## 3. Love Notes page

- [x] 3.1 Build `LoveNotesPage.swift` full-screen page: pink-wash gradient background, header with back chevron + "Love Notes" label + subtitle, scrollable body with two glass sections ("Incoming notes / Left for you" and "Sent by you / On their way"), each with count badge, note rows (icon, body preview, timestamp, status badge), empty-state messages, and navy "Write a/another note" CTA at bottom — verify page opens, sections populate from session store, CTA opens compose.

## 4. Note reader overlay

- [x] 4.1 Build `LoveNoteReaderOverlay.swift`: dark cinematic card (dark gradient background with pink outer glow), envelope emoji, full note body, partner attribution for incoming ("— Partner") or status line for outgoing, Close pill button, scrim dismiss — on dismiss of incoming unread note, call `onMarkRead` closure — verify reader shows note body and incoming dismiss triggers read callback.

## 5. Wire tile and navigation

- [x] 5.1 Update `UsView.swift` Love Notes tile: replace no-op stub with state-aware content (empty / outgoing-only with count badge / incoming-active with brighter pink and count), tile tap opens Love Notes page, pencil button opens Compose modal directly — verify tile text changes with note state and both tap targets navigate correctly.
- [x] 5.2 Add `@State` navigation booleans (`showLoveNotesPage`, `showLoveNoteCompose`, `loveNoteReading: LoveNote?`) and overlay presentation for all three surfaces (page, compose, reader) + sent toast (`showLoveNoteSentToast`) that auto-dismisses after ~3 seconds — verify full flow: tile → page → compose → send → toast, and tile → pencil → compose → send → toast.

## 6. Design system extraction

- [x] 6.1 If not already present, add `BeSideBackground.loveNoteCanvas` (pink-to-purple page gradient) and any pink tile gradient tokens to `DesignSystem/Tokens/` — verify tokens are used by `LoveNotesPage` and tile instead of inline hex values.

## 7. Verification

- [x] 7.1 Add/update UI tests: `testLoveNotesPageOpensFromTile`, `testLoveNoteComposeAndSend`, `testLoveNoteReaderOpensFromPage` — verify tests pass on simulator.
- [x] 7.2 Build the project (`xcodebuild build`) and visually compare compose modal, page, reader, and tile states against `design-reference` Love Notes overlays — verify no build errors and obvious visual gaps are addressed.
