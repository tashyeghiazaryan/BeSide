# Proposal

## Why

Us home still specified three daily progress chips and stacked Dates / Love Notes / Shared Moments rows. The product moved to a warmer couple surface: Instagram-style couple stories under the hero, a 2×2 glass tile grid, a single daily together nudge above the tab bar, and Instagram Stories share — with a Postgres table ready for live sync. Specs and the archive trail need to catch up to what shipped.

## What Changes

- Replace Us daily progress chips with one navy daily-together nudge (next action + `done/total`, navigates Me / Partner / Connection).
- Add couple stories strip under the hero (Add + rings, full-screen viewer, See all → archive grid).
- Persist `couple_stories` in Supabase (RLS for couple members); session store remains the client source until the live gateway is wired.
- Document Us home as adaptive 2×2 tiles (Dates, Little Things / Love Notes, Shared Moments) plus warmth footer and Instagram Stories share from the couple share surface.
- Keep Me / Partner / floating tab bar chrome out of scope (reverted experiments).

## Capabilities

### New Capabilities

- `couple-stories`: Couple photo stories strip, viewer, archive, and storage contract.

### Modified Capabilities

- `us-screen`: Hero + home layout (nudge, tiles, stories placement); remove chip-based daily progress requirement.
- `couple-backend`: Couple-scoped `couple_stories` table + RLS (additive persistence).

## Impact

- SwiftUI: `UsView`, `UsCoupleStory`, `CoupleStoryViewer`, `CoupleStoriesArchivePage`, `MeSessionStore`, Us layout tokens.
- Backend: `supabase/migrations/20261102120000_couple_stories.sql`.
- Main specs: `us-screen`, new `couple-stories`, extend `couple-backend` (create main if missing).
