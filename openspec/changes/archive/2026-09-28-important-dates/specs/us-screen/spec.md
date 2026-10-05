# Spec Delta

## MODIFIED Requirements

### Requirement: Entry tiles are visual stubs
The Us home SHALL show Important Dates and Love Notes tiles in a two-column grid and a Shared Memories section below, matching the reference layout. The Important Dates tile SHALL open the Important Dates flows defined in this capability (list and add). Love Notes, Shared Memories, and the Wishlist affordance on the Important Dates tile remain stubs in this change: taps MUST NOT open those later feature flows (no-op is allowed).

#### Scenario: Important Dates tile opens list
- **WHEN** the user taps the Important Dates tile (not the + or Wishlist controls)
- **THEN** the Important Dates list modal opens

#### Scenario: Other entry taps stay closed
- **WHEN** the user taps Love Notes, Shared Memories, or the Wishlist control on the Important Dates tile
- **THEN** no full-screen Love Notes, Shared Memories, or Wishlist flow is shown

## ADDED Requirements

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
