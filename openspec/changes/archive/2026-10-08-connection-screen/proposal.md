# Proposal

## Why

The Connection tab is still a named placeholder while Me, Partner, and Us ship real Figma Make flows. Completing Connection unlocks the couple-prompt carousel and Today's Activity hub that the rest of the product already references (daily progress “prompt” chip on Us).

## What Changes

- Replace `ConnectionView` placeholder with a full-bleed media carousel matching `design-reference` `ConnectionScreen.tsx` (seeded slides: Today's Activity, partner quiz teaser, Premium teaser).
- Support horizontal swipe, page dots, optional auto-advance, and a centered Start / “Open your task for today!” CTA.
- Opening Today's Activity presents a full-screen hub: Daily Task phases (closed → open → waiting) and “Awaiting your approval” partner answers (seeded, approvable).
- Session-backed activity completion hooks into existing `MeSessionStore` daily-progress flags where applicable.
- Partner quiz and Premium Start remain non-navigating in this slice (carousel marketing only; no paywall or quiz engine).

## Capabilities

### New Capabilities
- `connection-screen`: Connection tab carousel home + Today's Activity hub (session demo).

### Modified Capabilities
- `ios-app-shell`: Connection is no longer a named-only placeholder; More remains a placeholder.

## Impact

- `beside/beside/Features/Connection/` (new views/models)
- `ConnectionView.swift`, `RootTabView.swift` (pass `MeSessionStore`)
- `MeSessionStore` (activity / pending-answer session state)
- UITests for tab → carousel → Today's Activity happy path
- Design tokens only if glass/CTA patterns need promotion (prefer existing `BeSideColor.navy*`)
