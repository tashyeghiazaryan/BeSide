# Design

## Context

See `proposal.md` for why. Specs: `partner-screen` and the `ios-app-shell` delta.

`PartnerView` already shows a partial partner mood card, emoji grid, and note field backed by `MeSessionStore` (`partnerCurrentMood`, `respondToPartnerMood`). Figma Make `PartnerScreen.tsx` is the visual/interaction source of truth: mood-tinted hero with inline reaction picker, display-only care cards, week strip with upward day popup, and unpaired invite/join modal. Me’s week strip uses in-card expand; Partner’s week popup is a different pattern and should stay separate.

## Goals / Non-Goals

**Goals:**
- Partner tab matches the reference’s information structure and look when paired.
- Reuse DesignSystem tokens/components; extend store for partner week history + pairing without a backend.
- Preserve optional Partner note rules already documented and used for Me reciprocity.

**Non-Goals:**
- Real invite delivery, accounts, or server pairing.
- Favorites / Connection deep links from Partner (reference `favorites` props are unused for this slice).
- Changing Me’s week-strip interaction to match Partner’s upward popup.

## Decisions

1. **Single session store** — Extend `MeSessionStore` (or rename later to a shared session store) with `isPaired`, partner week history buckets, and reaction/note for the partner’s current mood. Alternative: separate `PartnerSessionStore` — rejected for now to avoid splitting seed/demo state that Me already shares.

2. **Hero reaction UX = Figma** — Replace the large 4×2 emoji grid + primary Send button with the inline Heart → emoji row → “Reaction sent!” flow inside the hero. Keep optional note under that section per field rules (extension beyond Figma).

3. **Care suggestions = static catalog** — Port `reactionsMap` from the reference next to `MoodCatalog` (e.g. `PartnerCareSuggestions`). Cards are non-interactive display.

4. **Partner week popup ≠ Me week** — Implement a Partner-specific compact popup above the strip (reference). Do not force Me’s in-card detail into Partner for “consistency”; the two screens intentionally differ in Figma.

5. **Paired by default in demo** — Seed `isPaired = true` so the mood UI is immediately reviewable (Me already assumes a partner). Unpaired modal remains reachable via a debug toggle or by flipping the flag for UI tests. Alternative: default unpaired like the reference’s prop default — rejected for product continuity after Me.

6. **DesignSystem extraction** — Reuse `GlassPanel`, `BeSideBackground.moodAmbient`, `MoodIcon`. Extract shared micro-sphere / count badge only if Partner and Me share identical primitives after visual pass; otherwise keep Partner week chrome local until a second identical use appears.

## Risks / Trade-offs

- [Partner week popup vs Me in-card] → Document in tasks; do not “unify” without a product decision.
- [Note field vs pure Figma] → Keep note secondary and compact; if visual QA fails 1:1, hide note behind reaction-sent state.
- [Pairing is local-only] → Invite/join only flips `isPaired`; no clipboard failure should block unlock in simulator tests (fallback still unlocks).

## Migration Plan

- Rewrite Partner UI behind the existing `PartnerView` / `screen.partner` identifier.
- Update shell UI tests that assert Partner is placeholder-only.
- No data migration (in-memory session only).

## Open Questions

- Whether a long-press or More-settings entry should force unpaired for demos (not required for first apply).
