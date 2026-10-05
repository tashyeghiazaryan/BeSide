# us-screen Specification

## Purpose

Shows the Us tab home: the couple hero, daily progress, long-term connection progress, Important Dates, Love Notes, and Shared Memories entry flows — matching the Figma Make Us home layout.

## Requirements

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
Below the avatars, the Us home SHALL show three daily progress chips labeled mood, partner, and prompt (short labels as in the reference). A chip is marked done only when **both** partners have completed that task for the day (seeded flags). Tapping a chip SHALL toggle a compact tip popover with the task’s full label and explanation; tapping again or elsewhere SHALL dismiss it without moving the long-term progress bar or the rest of the page layout. Chips MUST NOT navigate to Me, Partner, or Connection in this slice.

#### Scenario: Tip on chip tap
- **WHEN** the user taps the mood chip
- **THEN** a tip explains sharing mood & wish and whether the task is done or to-do

#### Scenario: Done requires both partners
- **WHEN** only one partner has shared a mood today
- **THEN** the mood chip is not shown as fully done

#### Scenario: Dismiss tip
- **WHEN** a tip is open and the user taps the same chip again or taps elsewhere on the Us screen
- **THEN** the tip closes and the progress bar position is unchanged

### Requirement: Long-term level and streak
Below daily progress, the Us home SHALL show the current long-term level name, a streak label (days), a progress bar for points toward the next level, and current/goal point numbers — using seeded demo values when no live progression exists.

#### Scenario: Level bar visible
- **WHEN** the user opens Us with seeded level 7, points 420, streak 3
- **THEN** the level name, “Streak · 3 days”, and a progress bar reflecting points vs goal are visible

### Requirement: Entry tiles are visual stubs
The Us home SHALL show Important Dates and Love Notes tiles in a two-column grid and a Shared Memories section below, matching the reference layout. The Important Dates tile SHALL open the Important Dates flows. The Love Notes tile SHALL open the Love Notes page; the pencil button SHALL open the Compose modal. The Shared Memories section SHALL open the Shared Memories flows (gallery from the header, Add from `+`, detail from carousel cards). The Wishlist affordance on the Important Dates tile remains as previously implemented (or a stub if not yet shipped): this change MUST NOT remove Wishlist behavior.

#### Scenario: Love Notes tile opens page
- **WHEN** the user taps the Love Notes tile body
- **THEN** the Love Notes page opens

#### Scenario: Pencil opens Compose
- **WHEN** the user taps the pencil button on the Love Notes tile
- **THEN** the Compose modal opens without navigating to the page first

#### Scenario: Shared Memories opens gallery
- **WHEN** the user taps the Shared Memories header
- **THEN** the Shared Memories gallery page opens

#### Scenario: Shared Memories plus opens Add
- **WHEN** the user taps `+` on the Shared Memories section
- **THEN** the Add memory modal opens

### Requirement: Important Dates list modal
When the Important Dates list is open, the Us tab SHALL show a centered frosted-glass modal over a dimmed/blurred scrim titled “Important dates” with subtitle “All your moments together”. The modal SHALL list all session important dates sorted by soonest upcoming occurrence, each row showing title, short date, and a countdown-style badge. An empty list MUST show guidance to add a date via +. The user SHALL dismiss the modal by tapping Close or the scrim.

#### Scenario: List shows seeded dates
- **WHEN** the user opens the Important Dates list with seeded dates present
- **THEN** rows for those dates are visible with titles and countdown badges

#### Scenario: Dismiss list
- **WHEN** the list modal is open and the user taps Close or the scrim
- **THEN** the modal closes and the Us home remains visible

### Requirement: Add Important Date calendar modal
Tapping + on the Important Dates tile SHALL open an “Add a date” frosted-glass calendar modal (closing the list if it was open). The modal SHALL offer month prev/next, a month grid (Monday-start), selecting a day, a title field, and an Add control that expands inline fields on first use and commits on a second tap when title and date are set. After a successful add, the new date SHALL appear in the session list and the home tile nearest-date preview SHALL update. Empty title or missing date MUST NOT add. Dismiss via Close or scrim without requiring save.

#### Scenario: Open add calendar from +
- **WHEN** the user taps + on the Important Dates tile
- **THEN** the Add a date calendar modal opens

#### Scenario: Add custom date
- **WHEN** the user selects a day, enters a title, and confirms Add
- **THEN** the date is stored for this session and appears in the list and on the home tile when it is the nearest upcoming date

#### Scenario: Incomplete add blocked
- **WHEN** the user taps Add without both a title and a selected day
- **THEN** no new date is added
