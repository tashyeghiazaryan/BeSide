# Tasks

## 1. Models and session store

- [x] 1.1 Add `ConnectionCarouselSlide` + default three-slide seed (Today's Activity with You/Partner tasks, partner quiz, Premium) — verify seed non-empty and activity slide has both tasks.
- [x] 1.2 Add pending-answer model + demo seed; extend `MeSessionStore` with pending answers list, `approvePendingAnswer(id:)`, and ensure `markDailyActivityDone()` (or equivalent) sets `meActivityDoneToday` — verify approve removes one item and mark-done flips the flag.

## 2. Today's Activity hub

- [x] 2.1 Build `TodaysActivityHub`: soft canvas + ambient blurs, Back, beside mark/title, Daily Task navy card (closed / open / waiting), soft-pink CTAs, awaiting-approval glass section with Approve — verify phase transitions and Back dismisses.

## 3. Carousel home

- [x] 3.1 Rebuild `ConnectionView`: full-bleed slide media + gradient, Connection pill, dots, title/body/You–Partner copy, centered CTA, swipe + dot navigation, auto-advance when hub closed — verify swipe changes slides and activity CTA opens hub.
- [x] 3.2 Wire `RootTabView` to pass `meStore` into `ConnectionView`; Start on non-activity slides is no-op — verify Connection tab shows carousel not placeholder.

## 4. Verification

- [x] 4.1 Add/update UITests: open Connection tab, open Today's Activity, mark done (or open task), approve a pending answer — verify tests compile.
- [x] 4.2 `xcodebuild build` and spot-check against `design-reference` ConnectionScreen — verify no build errors.
