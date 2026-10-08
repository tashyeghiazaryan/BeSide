# Spec Delta

## MODIFIED Requirements

### Requirement: Each tab shows only its placeholder
Selecting More SHALL show that tab's placeholder and hide the other tabs' content. The More placeholder MUST identify itself as More and MUST NOT offer mood sharing, partner reactions, couple content, connection activities, profile editing, settings, or any other feature action. Selecting Me SHALL show the Me screen content defined by the `me-screen` capability. Selecting Partner SHALL show the Partner screen content defined by the `partner-screen` capability. Selecting Us SHALL show the Us screen content defined by the `us-screen` capability. Selecting Connection SHALL show the Connection screen content defined by the `connection-screen` capability instead of a named-only placeholder.

#### Scenario: Switch to Connection
- **WHEN** the user selects the Connection tab
- **THEN** the visible screen shows Connection screen content and does not show Me, Partner, Us, or More content

#### Scenario: Switch through remaining placeholders and real tabs
- **WHEN** the user selects More, then Us, then Partner, then Me, then Connection
- **THEN** More shows only the placeholder named for that tab, Us shows Us screen content, Partner shows Partner screen content, Me shows Me screen content, and Connection shows Connection screen content

#### Scenario: More placeholder has no feature actions
- **WHEN** the user is on More
- **THEN** the screen has no control that shares a mood, sends a reaction, edits a profile, or starts an activity

#### Scenario: Connection is not a blank placeholder
- **WHEN** the user selects the Connection tab
- **THEN** the Connection screen content is shown rather than a screen that only displays the word Connection

#### Scenario: Us is not a blank placeholder
- **WHEN** the user selects the Us tab
- **THEN** the Us screen content is shown rather than a screen that only displays the word Us
