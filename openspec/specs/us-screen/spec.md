# us-screen Specification

## Purpose

Shows the Us tab home: the couple hero, couple stories strip, a 2×2 glass tile grid (Important Dates, Little Things / Love Notes, Shared Moments), a daily warmth line, and a navy daily-together nudge above the tab bar. Shared Memories is not a separate home section — past shared photos live in Shared Moments → Archive.

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
Below the avatars / stories strip, the Us home SHALL NOT show three separate mood / partner / prompt progress chips. Instead, Us SHALL show a single navy daily-together nudge as a thin strip above the floating tab bar when there is a next action (or a completed state). The nudge SHALL show short copy for the next step, a `done/total` count for today’s mutual daily tasks (mood share, check partner mood, couple activity), and navigate to Me, Partner, or Connection when tapped. When both partners are done for the day, the nudge MAY hide or show a non-navigating completed state. The Us hero MUST NOT show a long-term level name, streak label, XP progress bar, or point totals.

#### Scenario: Nudge points to next action
- **WHEN** the user has not shared a mood today
- **THEN** the daily nudge invites them to share how they feel and tapping it selects the Me tab

#### Scenario: Progress count
- **WHEN** some but not all mutual daily tasks are done
- **THEN** the nudge shows a `done/total` fraction reflecting mutual completion

#### Scenario: No level or streak chrome
- **WHEN** the user opens Us
- **THEN** the home MUST NOT show a level/milestone name or streak label

### Requirement: Couple stories on Us home
The Us home SHALL place the couple stories strip under the hero and above the entry tiles, per the `couple-stories` capability.

#### Scenario: Strip under hero
- **WHEN** the user opens Us
- **THEN** the stories strip appears under the couple hero before the 2×2 tiles

### Requirement: Entry cards (Important Dates / Love Notes)
The Us home SHALL show a 2×2 glass tile grid for Important Dates, Little Things / Love Notes, and Shared Moments (Screen), with adaptive spacing for iPhone 16 / 16 Pro / Max. Dates and Shared Moments use light glass cards; Love Notes use navy fill with light copy. Wishlist / Add sit on the Dates tile; pencil / compose sit on the Love Notes tile. Tapping tile content opens the corresponding list, compose, or Screen photo page as before.

#### Scenario: Love Notes tile opens page
- **WHEN** the user taps the Love Notes tile body
- **THEN** the Love Notes page opens

#### Scenario: Pencil opens Compose
- **WHEN** the user taps the pencil control on the Love Notes tile
- **THEN** the Compose modal opens without navigating to the page first

### Requirement: Shared Moments card
Within the 2×2 grid, Us SHALL show a Shared Moments tile for sharing a photo that can appear on the home-screen widget. The tile subtitle SHALL convey sending photos and keeping one on a widget. Tapping the tile SHALL open the Screen photo detail page (back returns to Us home). The Us home MUST NOT show a separate Shared Memories section.

#### Scenario: Card opens Screen page
- **WHEN** the user taps the Shared Moments tile
- **THEN** the Screen photo page opens with a back control to return home

#### Scenario: Archive from Screen page
- **WHEN** the user taps Archive on the Screen photo page
- **THEN** an archive page opens for past screen photos (empty when none)

#### Scenario: No Shared Memories on home
- **WHEN** the user opens Us
- **THEN** the home scroll does not show a Shared Memories entry section

### Requirement: Daily warmth footer
Below the entry tiles, Us MAY show a short daily warmth / affirmation line for the couple (non-navigating copy).

#### Scenario: Warmth visible on home
- **WHEN** the user scrolls the Us home
- **THEN** a short warmth line appears below the tile grid

### Requirement: Instagram Stories share from Us
From the Us couple share surface, the user SHALL be able to share a composed couple story card to Instagram Stories when Instagram is available on device. Failure to open Instagram MUST NOT crash the Us home.

#### Scenario: Share opens Instagram when installed
- **WHEN** the user chooses share to Instagram Stories and Instagram is installed
- **THEN** the system handoff to Instagram Stories is attempted with the couple card image

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
