# Tasks

## 1. Session seeds for Us home

- [x] 1.1 Extend session store with Us home seeds: relationship start date, long-term level/points/streak, and daily completion flags for mood / partner-check / prompt (both partners) — verify Us can read non-empty demo values without a network call.
- [x] 1.2 Derive “together for …” duration from the relationship start date (same rules as Figma `calculateTimeTogether`) — verify a multi-year seed renders a years/months string on Us.

## 2. Us home UI

- [x] 2.1 Rebuild `UsView` home: soft canvas + pastel ambient blurs, optional notifications bell chrome (no-op), hero with “{me} & {partner}”, time-together line, overlapping avatar bubbles — verify simulator Us matches the reference hero structure (not the placeholder word Us).
- [x] 2.2 Implement daily progress chips (mood / partner / prompt) with both-partners done styling and tip popover on tap — verify tapping mood shows the tip and done state requires both flags.
- [x] 2.3 Implement long-term level name, streak label, progress bar, and points row from seeds — verify level 7 / 420 points / streak 3 appear as in demo defaults.
- [x] 2.4 Add Important Dates + Love Notes grid tiles and Shared Memories section chrome with seeded preview copy; keep feature taps as no-ops — verify tiles are visible and taps do not open dates/wishlist/love-notes/memories flows.

## 3. Shell and verification

- [x] 3.1 Update shell / Us UI tests so Us content is allowed while Connection/More stay placeholders — verify tests pass on an iOS simulator.
- [x] 3.2 Visually compare Us home in the simulator against `design-reference` UsScreen first viewport (hero, daily, level bar, tiles) and fix obvious gaps — verify the side-by-side check is recorded done in this checkbox.
