# Spec Delta — us-screen

## MODIFIED Requirements

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

#### Scenario: No Shared Memories on home
- **WHEN** the user opens Us
- **THEN** the home scroll does not show a Shared Memories entry section

## ADDED Requirements

### Requirement: Couple stories on Us home
The Us home SHALL place the couple stories strip under the hero and above the entry tiles, per the `couple-stories` capability.

#### Scenario: Strip under hero
- **WHEN** the user opens Us
- **THEN** the stories strip appears under the couple hero before the 2×2 tiles

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
