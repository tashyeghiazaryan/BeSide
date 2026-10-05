# Design

## Context

See proposal.md for motivation. The Us home has a pink Love Notes tile (currently a no-op stub) and an existing design-system pattern of glass modals + full-screen pages used by Important Dates and Wishlist. The Figma reference (`UsScreen.tsx`) defines the complete visual language: pink-wash gradients, frosted glass sections, matte chrome controls, dark cinematic reader overlay, and tile state variants. The user requests **no triggers** (time, mood, away) — every note is instant-send.

Existing infrastructure:
- `MeSessionStore` already holds Us data (important dates, wishlist items) — love notes array fits the same pattern.
- `UsView.swift` has the tile stub, modal/page presentation via `@State` booleans, and `.ignoresSafeArea(.keyboard)`.
- Design tokens (`BeSideColor`, `BeSideBackground`, `BeSideMetrics`) are in `DesignSystem/`.

## Goals / Non-Goals

**Goals:**
- Fully functional compose → send → list → read flow for love notes.
- Tile reflects note state (empty / outgoing-only / incoming-active).
- Visual match to Figma pink glass aesthetic.
- Reuse design system tokens; extract new ones if needed (pink gradient, pink wash).

**Non-Goals:**
- No trigger system (time, mood, away) — all notes are instant.
- No push notifications or real-time sync — session-only data.
- No maximum-waiting-notes cap (Figma had 5-note limit tied to triggers; without triggers, no limit needed — notes are sent immediately).
- No shared-memories or connection-screen changes.

## Decisions

### 1. Model: flat `LoveNote` struct, no trigger fields
**Choice:** `LoveNote` has `id`, `body`, `createdAt`, `direction` (enum: incoming/outgoing), `status` (enum: sent/read), `readAt`.
**Rationale:** Figma's `triggerKind`, `opensAt`, `targetMood`, `inactivityDays`, `moodUnlockHighlight` fields exist only for conditional triggers, which are dropped. A two-state status (sent → read) replaces the three-state (waiting → unlocked → read). This keeps the model minimal.
**Alternative considered:** Keep `triggerKind` as `.instant` for forward-compat. Rejected — adds no value now and the field can be added later if triggers ship.

### 2. Session store location: extend `MeSessionStore`
**Choice:** Add `loveNotes: [LoveNote]` plus `sendLoveNote(body:)`, `markNoteRead(id:)`, and computed tile-state helpers to `MeSessionStore`.
**Rationale:** Follows the same pattern as `importantDates`, `myWishlist`, `partnerWishlist` — keeps all Us session data in one `@Observable` store already injected into `UsView`.
**Alternative:** Separate `LoveNoteStore` class. Rejected — would need additional `@Environment` wiring for no gain at this scale.

### 3. File structure: one file per UI surface
| File | Content |
|------|---------|
| `UsLoveNote.swift` | `LoveNote` model, direction/status enums, body validation, demo seeds |
| `LoveNotesPage.swift` | Full-screen page: header, incoming section, outgoing section, CTA |
| `LoveNoteComposeModal.swift` | Compose glass card: textarea, counter, send CTA |
| `LoveNoteReaderOverlay.swift` | Dark cinematic reader: body, attribution, close |

**Rationale:** Mirrors the Important Dates pattern (`UsImportantDate.swift`, `ImportantDatesListModal.swift`, `ImportantDatesAddModal.swift`). Each file owns a single concern.

### 4. Navigation: `@State` booleans on `UsView`
**Choice:** `showLoveNotesPage`, `showLoveNoteCompose`, `loveNoteReading: LoveNote?` on `UsView`, presented as overlays/sheets in the same `ZStack` pattern used for dates and wishlist.
**Rationale:** Consistent with existing codebase pattern. Full-screen page uses a custom slide-from-right transition (`.transition(.move(edge: .trailing))`), compose modal uses a centered glass overlay, reader uses a dark overlay.

### 5. Pink design tokens
**Choice:** Add `BeSideBackground.loveNoteCanvas` (pastel pink gradient for the page) and `BeSideColor.loveNotePink` / `loveNotePinkBright` for tile gradients to the design system — only if not already covered by existing tokens. Use `BeSideColor.navyFill`/`navyLabel` for the CTA button on the page (consistent with Important Dates).
**Rationale:** Reuse over duplication per the design-system rule. The page background is a unique pink-to-purple gradient not used elsewhere.

### 6. Toast implementation
**Choice:** A transient overlay on `UsView` that appears for ~3 seconds after `sendLoveNote`, then auto-dismisses. Simple `@State var showSentToast = false` with `Task.sleep` auto-clear.
**Rationale:** Matches existing patterns (Important Dates "Added" success flash). No third-party toast library needed.

## Risks / Trade-offs

- **Session-only data**: Notes are lost on app restart. This is acceptable for the prototype phase; persistence is a separate future slice.
- **No note deletion**: Figma has no delete UI; notes accumulate. Acceptable for demo; can add swipe-to-delete later.
- **Incoming notes are seeded only**: Without a backend, the partner's notes are demo seeds. The model supports future real-time delivery without structural changes.
- **Body validation is client-only**: The 100-char limit and charset filter run locally. Server-side validation would be needed with a real backend.
