# Proposal

## Why

Connection already ships Today's Activity as a full session flow, but the carousel still has only teaser Start actions for everything else. Couples need a second daily ritual — a shared question both answer privately, revealed together — that fits the same Connection home without waiting on a quiz engine or Premium.

## What Changes

- Add a seeded **Question of the day** carousel slide (alongside Today's Activity, partner-quiz teaser, Premium teaser).
- Start on that slide opens a full-screen **dialogue** hub: one shared question, free-text answers from both partners.
- Answers stay hidden until both have submitted; then both answers appear as a dialogue (You / Partner bubbles).
- Session demo only: seed one question; partner answer can be simulated in-session (same spirit as daily-task partner submit/approve demos).
- Sections index includes the new slide and can open the same hub.
- Partner-quiz and Premium Start remain no-ops in this slice.

## Capabilities

### New Capabilities
- `question-of-the-day`: Shared daily question dialogue on Connection — answer privately, reveal when both answered.

### Modified Capabilities
- `connection-screen`: Carousel seeds an extra Question of the day slide; Start on that slide opens the QotD hub (not Today's Activity); other non-activity Starts stay no-op except QotD.

## Impact

- `beside/beside/Features/Connection/` (new QotD views/models; carousel slide seed; `ConnectionView` Start / Sections wiring)
- `MeSessionStore` (session QotD question + answer state)
- UITests: open QotD from carousel → submit → reveal dialogue when both answered
- Prefer existing soft canvas / navy tokens; dialogue bubbles may reuse glass patterns from DesignSystem if already shared
