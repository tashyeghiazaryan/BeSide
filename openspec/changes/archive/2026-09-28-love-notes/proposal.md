# Proposal

## Why

The Us home Love Notes tile is a no-op stub. Love Notes is a core couple feature: one partner writes a short text note, it is sent immediately, and the other partner can read it on their Love Notes page. Shipping this slice makes the pink tile functional and gives users a tangible act-of-love tool.

## What Changes

- Add a `LoveNote` model (id, body, createdAt, direction incoming/outgoing, status sent/read, readAt) to the session store with demo seed notes.
- Build a **Compose modal** (glass card over scrim): text area (max 100 chars, latin + emoji), character counter, "Send note" navy CTA — note is created as outgoing/sent immediately on tap.
- Build a **Love Notes page** (full-screen, slide-from-right): header with back + subtitle, two glass sections — "Incoming notes / Left for you" and "Sent by you / On their way" — each listing note rows with body preview, timestamp, and status badge; navy "Write a/another note" CTA at bottom opens Compose.
- Build a **Note reader overlay** (dark cinematic card): shows full note body, sender attribution for incoming, status line for outgoing, Close button — marks incoming notes as read on dismiss.
- Wire the Us home **Love Notes tile** to open the Love Notes page on tap; the pencil button opens Compose directly.
- Update tile state to reflect outgoing-only / empty / incoming-has-notes variants with matching copy and optional count badge.
- Show a brief "Sent" toast on the Us home after a note is sent from Compose.
- Simplification vs Figma: **no triggers** (time, mood, away). Every note uses instant delivery — triggerKind concept is dropped entirely. No waiting/unlocked distinction: notes go straight to sent→read lifecycle.

## Capabilities

### New Capabilities
- `love-notes`: Compose, send, list, and read love notes between partners on the Us tab — instant delivery only, no conditional triggers.

### Modified Capabilities
- `us-screen`: The Love Notes tile and pencil button become functional entry points (were no-op stubs).

## Impact

- **New files**: `UsLoveNote.swift` (model), `LoveNotesPage.swift` (full-screen list + CTA), `LoveNoteComposeModal.swift` (write modal), `LoveNoteReaderOverlay.swift` (read overlay).
- **Modified files**: `MeSessionStore.swift` (love note array, add/read APIs), `UsView.swift` (tile states, navigation bindings, toast).
- **Design system**: Reuse existing `BeSideColor`, `BeSideBackground`, `BeSideMetrics`. May add pink-wash gradient token to `Backgrounds.swift` if not already present.
- **No new dependencies.**
