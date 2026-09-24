# Spec Delta

## MODIFIED Requirements

### Requirement: Each tab shows only its placeholder
Selecting Partner, Us, Connection, or More SHALL show that tab's placeholder and hide the other tabs' content. Each of those placeholders MUST identify its tab by the same name as the tab (Partner, Us, Connection, or More). A placeholder on those tabs MUST NOT offer mood sharing, partner reactions, couple content, connection activities, profile editing, settings, or any other feature action. Selecting Me SHALL show the Me screen content defined by the `me-screen` capability instead of a named-only placeholder.

#### Scenario: Switch to Partner
- **WHEN** the user selects the Partner tab
- **THEN** the visible screen identifies itself as Partner and does not show Me, Us, Connection, or More content

#### Scenario: Switch through every tab
- **WHEN** the user selects Us, then Connection, then More, then Me
- **THEN** Us, Connection, and More each show only the placeholder named for that tab, and Me shows the Me screen content

#### Scenario: Placeholder has no feature actions
- **WHEN** the user is on Partner, Us, Connection, or More
- **THEN** the screen has no control that shares a mood, sends a reaction, edits a profile, or starts an activity

#### Scenario: Me is not a blank placeholder
- **WHEN** the user selects the Me tab
- **THEN** the Me screen content is shown rather than a screen that only displays the word Me
