# Spec Delta

## Purpose

Shows the Us tab home shell: the couple hero, daily progress, long-term connection progress, and visual entry tiles that later feature slices will open — matching the first viewport of Figma Make Us without shipping full dates/wishlist/memories/love-notes flows yet.

## ADDED Requirements

### Requirement: Us visual treatment matches Figma Make home
The Us tab SHALL use the Us frame visual language from `design-reference` `UsScreen.tsx` for the home viewport: soft light canvas with pastel ambient blurs, frosted glass entry tiles, and matte circular chrome controls. The Us tab MUST NOT present as a blank named-only placeholder when this capability is active.

#### Scenario: Us reads as couple home UI
- **WHEN** the user opens the Us tab
- **THEN** the screen shows a couple hero and glass entry tiles rather than only the word Us

### Requirement: Couple hero
The Us home SHALL show both partners’ display names (e.g. “Anna & Alex”), a “together for …” duration derived from a seeded relationship start date, and two overlapping avatar bubbles (initials and/or placeholder photo treatment matching the reference).

#### Scenario: Names and time together
- **WHEN** the partners are Anna and Alex with a seeded relationship start in the past
- **THEN** the hero shows “Anna & Alex” and a together-for duration string

### Requirement: Daily progress chips
Below the avatars, the Us home SHALL show three daily progress chips labeled mood, partner, and prompt (short labels as in the reference). A chip is marked done only when **both** partners have completed that task for the day (seeded flags). Tapping a chip SHALL toggle a compact tip popover with the task’s full label and explanation; tapping again or elsewhere MAY dismiss it. Chips MUST NOT navigate to Me, Partner, or Connection in this slice.

#### Scenario: Tip on chip tap
- **WHEN** the user taps the mood chip
- **THEN** a tip explains sharing mood & wish and whether the task is done or to-do

#### Scenario: Done requires both partners
- **WHEN** only one partner has shared a mood today
- **THEN** the mood chip is not shown as fully done

### Requirement: Long-term level and streak
Below daily progress, the Us home SHALL show the current long-term level name, a streak label (days), a progress bar for points toward the next level, and current/goal point numbers — using seeded demo values when no live progression exists.

#### Scenario: Level bar visible
- **WHEN** the user opens Us with seeded level 7, points 420, streak 3
- **THEN** the level name, “Streak · 3 days”, and a progress bar reflecting points vs goal are visible

### Requirement: Entry tiles are visual stubs
The Us home SHALL show Important Dates and Love Notes tiles in a two-column grid and a Shared Memories section below, matching the reference layout and seeded preview content where available. Opening full feature flows (dates list/calendar, wishlist, love-notes page/composer, memories gallery/add) is **out of scope**; taps on those entry controls MUST NOT present those flows in this change (no-op is allowed).

#### Scenario: Important Dates tile visible
- **WHEN** the user opens Us with a seeded upcoming important date
- **THEN** the Important Dates tile shows a title/date preview and countdown-style badge treatment without opening a dates modal

#### Scenario: Feature taps stay closed
- **WHEN** the user taps Important Dates, Love Notes, Wishlist affordance, or Shared Memories entry controls
- **THEN** no full-screen feature page or add/composer modal from later Us slices is shown
