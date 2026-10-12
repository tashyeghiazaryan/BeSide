# Spec Delta

## MODIFIED Requirements

### Requirement: Each tab shows only its placeholder
Selecting More SHALL show the More screen content defined by the `more-screen` capability and hide the other tabs' content. Selecting Me SHALL show the Me screen content defined by the `me-screen` capability. Selecting Partner SHALL show the Partner screen content defined by the `partner-screen` capability. Selecting Us SHALL show the Us screen content defined by the `us-screen` capability. Selecting Connection SHALL show the Connection screen content defined by the `connection-screen` capability. The shell MUST NOT show a named-only More placeholder that only displays the word More without profile/settings content.

#### Scenario: Switch to Connection
- **WHEN** the user selects the Connection tab
- **THEN** the visible screen shows Connection screen content and does not show Me, Partner, Us, or More content

#### Scenario: Switch through real tabs including More
- **WHEN** the user selects More, then Us, then Partner, then Me, then Connection
- **THEN** More shows More screen content, Us shows Us screen content, Partner shows Partner screen content, Me shows Me screen content, and Connection shows Connection screen content

#### Scenario: More is not a blank placeholder
- **WHEN** the user selects the More tab
- **THEN** the More screen content is shown rather than a screen that only displays the word More

#### Scenario: Connection is not a blank placeholder
- **WHEN** the user selects the Connection tab
- **THEN** the Connection screen content is shown rather than a screen that only displays the word Connection

#### Scenario: Us is not a blank placeholder
- **WHEN** the user selects the Us tab
- **THEN** the Us screen content is shown rather than a screen that only displays the word Us
