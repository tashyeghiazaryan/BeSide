# Proposal

## Why

Partner is still a thin stand-in: a simple glass card plus emoji/note form. The Figma Make `PartnerScreen` already defines the full paired experience — hero mood card, inline reaction, care suggestions, week history, and the unpaired invite overlay. Building Partner 1:1 next keeps the shell coherent after Me.

## What Changes

- Replace the current Partner placeholder/partial UI with a native SwiftUI Partner screen that matches `design-reference` `PartnerScreen.tsx` (layout, glass treatment, mood-tinted ambient, interactions).
- Show the partner’s current mood as a hero card: large mood sphere, name, quoted wish, timestamp, and an inline “Send a reaction” / emoji picker flow.
- Show “Small ways to show you care” — display-only suggestion cards driven by the partner’s current mood catalog (same copy map as the reference).
- Show “Mood this week” for the partner’s last seven days with micro-spheres, count badges, and a compact day-detail popup that opens above the strip (reference Partner pattern, not Me’s in-card expand).
- Support unpaired state: blurred preview + non-dismissible invite/join modal (invite code copy, join code entry) matching the reference; seed/demo defaults to paired so the mood UI is reachable.
- Keep optional short note after a reaction so Partner stays aligned with `Требования полей.md` and Me’s “partner reacted + note” reciprocity (small product extension beyond pure Figma, styled under the hero reaction area).
- Update shell expectations so Partner is real content, not a named-only placeholder.

## Capabilities

### New Capabilities
- `partner-screen`: Partner tab shows the partner’s mood, reactions, care suggestions, week history, and pairing overlay per Figma Make.

### Modified Capabilities
- `ios-app-shell`: Partner tab shows Partner screen content instead of a blank placeholder.

## Impact

- `Features/Partner/` (rewrite `PartnerView`, likely split hero / care / week / pairing pieces).
- Shared mood catalog / store: partner history, pairing flag, reaction (+ optional note) already partly on `MeSessionStore` — extend rather than invent a second source of truth where possible.
- Reuse `DesignSystem` (`GlassPanel`, `BeSideBackground`, mood icons/tokens); extract any second-use Partner chrome into DesignSystem.
- UI tests / shell tests that still expect Partner as a named-only placeholder.
- Field rules doc already covers Partner note; no new input types beyond invite/join code for the pairing modal.
