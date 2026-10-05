# Tasks

## 1. Session model

- [x] 1.1 Add `UsImportantDate` (id, title, date, optional accent) and a mutable important-dates array on the session store with Figma-like seeds (next date together, anniversary, partner birthday, special day, Valentine’s, New Year) using next annual occurrence — verify nearest upcoming date drives the home tile preview.
- [x] 1.2 Implement add-custom-date API (title + date) that appends to the session list and refreshes nearest preview — verify adding a nearer date updates the tile title/countdown.

## 2. Modals and tile wiring

- [x] 2.1 Build Important Dates list modal (scrim, glass card, title/subtitle, scrollable rows with icon/title/short date/countdown, empty state, Close + scrim dismiss) — verify opening from the tile shows seeded rows and dismiss works.
- [x] 2.2 Build Add a date calendar modal (month prev/next, Mo–Su grid, day select, title field, two-step Add, success flash, Close + scrim dismiss) — verify selecting day + title commits a date and incomplete Add does not.
- [x] 2.3 Wire Us Important Dates tile tap → list, + → add calendar; keep Wishlist/Love Notes/Memories stubs — verify + opens add (not list) and Gift still no-ops.

## 3. Verification

- [x] 3.1 Add/update UI tests for Us Important Dates list open and add-date happy path (or existence of modal identifiers after open) — verify tests pass on simulator.
- [x] 3.2 Visually compare list + add modals to `design-reference` UsScreen Important Dates overlays and fix obvious gaps — verify checkbox recorded done.
