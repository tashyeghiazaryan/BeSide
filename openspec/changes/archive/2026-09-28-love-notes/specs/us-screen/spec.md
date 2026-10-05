# Spec Delta

## MODIFIED Requirements

### Requirement: Entry tiles are visual stubs
The Us home SHALL show Important Dates and Love Notes tiles in a two-column grid and a Shared Memories section below, matching the reference layout. The Important Dates tile SHALL open the Important Dates flows. The Love Notes tile SHALL open the Love Notes page; the pencil button SHALL open the Compose modal. Shared Memories and the Wishlist affordance on the Important Dates tile remain stubs in this change: taps MUST NOT open those later feature flows (no-op is allowed).

#### Scenario: Love Notes tile opens page
- **WHEN** the user taps the Love Notes tile body
- **THEN** the Love Notes page opens

#### Scenario: Pencil opens Compose
- **WHEN** the user taps the pencil button on the Love Notes tile
- **THEN** the Compose modal opens without navigating to the page first

#### Scenario: Other entry taps stay closed
- **WHEN** the user taps Shared Memories or the Wishlist control on the Important Dates tile
- **THEN** no full-screen Shared Memories or Wishlist flow is shown
