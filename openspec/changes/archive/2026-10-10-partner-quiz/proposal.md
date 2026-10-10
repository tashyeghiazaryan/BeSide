# Proposal

## Why

The Connection carousel already teases “How well do you know your partner?” but Start is a no-op. After Today's Activity and Question of the day, couples need a playful quiz ritual—one partner’s truths, the other’s guesses—so the teaser becomes a real session experience.

## What Changes

- Wire the existing **partner-quiz** carousel slide (and Sections Open) to a full-screen Partner Quiz hub.
- Session demo quiz: seeded multiple-choice questions (3–4 options each); the partner’s truth answers are locked; the user guesses.
- After guesses, show a scored results view (correct count + brief per-question reveal).
- Soft canvas + beside branding; hide floating tab bar while the hub is open (same pattern as QotD / daily-task detail).
- Premium Start remains a no-op in this slice.

## Capabilities

### New Capabilities
- `partner-quiz`: Classic “know your partner” multiple-choice quiz — guess partner’s seeded answers, then see score/reveals.

### Modified Capabilities
- `connection-screen`: Start / Sections on the partner-quiz slide open the Partner Quiz hub (Premium stays no-op).

## Impact

- `beside/beside/Features/Connection/` (new hub + quiz models; carousel Start / Sections wiring)
- `MeSessionStore` (session quiz progress / answers / score)
- UITests for open → guess → results → back
- Prefer existing soft canvas / navy tokens
