# Spec Delta

## MODIFIED Requirements

### Requirement: Each tab shows only its placeholder
Selecting Us, Connection, or More SHALL show that tab's placeholder and hide the other tabs' content. Each of those placeholders MUST identify its tab by the same name as the tab (Us, Connection, or More). A placeholder on those tabs MUST NOT offer mood sharing, partner reactions, couple content, connection activities, profile editing, settings, or any other feature action. Selecting Me SHALL show the Me screen content defined by the `me-screen` capability. Selecting Partner SHALL show the Partner screen content defined by the `partner-screen` capability instead of a named-only placeholder.

#### Scenario: Switch to Us
- **WHEN** the user selects the Us tab
- **THEN** the visible screen identifies itself as Us and does not show Me, Partner, Connection, or More content

#### Scenario: Switch through remaining placeholders and real tabs
- **WHEN** the user selects Connection, then More, then Partner, then Me
- **THEN** Connection and More each show only the placeholder named for that tab, Partner shows Partner screen content, and Me shows Me screen content

#### Scenario: Placeholder has no feature actions
- **WHEN** the user is on Us, Connection, or More
- **THEN** the screen has no control that shares a mood, sends a reaction, edits a profile, or starts an activity

#### Scenario: Partner is not a blank placeholder
- **WHEN** the user selects the Partner tab
- **THEN** the Partner screen content is shown rather than a screen that only displays the word Partner
