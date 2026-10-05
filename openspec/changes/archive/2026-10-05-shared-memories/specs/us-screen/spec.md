# Spec Delta

## MODIFIED Requirements

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
