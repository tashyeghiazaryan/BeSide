# Tasks

## 1. Session model and catalogs

- [x] 1.1 Extend session store with `isPaired` (demo default `true`), partner week history seed/buckets, and reaction (+ optional note) APIs already used by Partner — verify paired launch shows partner current mood data without a network call.
- [x] 1.2 Add `PartnerCareSuggestions` (or equivalent) mapping the six mood ids to the Figma Make suggestion strings — verify stressed returns the four stressed care lines from the reference.

## 2. Partner UI (Figma Make look)

- [x] 2.1 Rebuild `PartnerView` paired layout: soft canvas, partner-mood ambient blurs, title, “Alex feels … today” line, mood-tinted hero card with large sphere, quoted wish, timestamp — verify simulator Partner matches the reference hero structure (not the old flat card-only form).
- [x] 2.2 Implement inline hero reaction flow (Send a reaction → emoji row → Reaction sent! / locked You reacted; **one reaction per partner mood**) plus optional note field under field rules — verify sending 🤗 persists locally and invalid note shows inline error only on save.
- [x] 2.3 Add “Small ways to show you care” glass suggestion cards for the current partner mood (display-only) — verify cards appear and taps do not change reaction state.
- [x] 2.4 Implement Partner “Mood this week” strip with micro-spheres, count badges, and compact day-detail popup above the strip (scroll when many entries) — verify tapping a day with entries opens the popup and empty days do not.
- [x] 2.5 Implement unpaired invite/join modal over blurred Partner preview (non-dismissible outside tap); invite code copy + join unlocks `isPaired` locally — verify unpaired mode shows the modal and join unlocks interactive Partner UI.

## 3. Shell and verification

- [x] 3.1 Update shell / Partner UI tests so Partner content is allowed while Us/Connection/More stay placeholders — verify tests pass on an iOS simulator.
- [x] 3.2 Visually compare Partner in the simulator against `design-reference` PartnerScreen (hero, care list, week strip, unpaired modal) and fix obvious gaps — verify the side-by-side check is recorded done in this checkbox.
