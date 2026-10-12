# ios-app-shell Specification

## Purpose

Gives the native BeSide app a signed-in navigation shell of five empty tabs so later screens can attach to a stable structure without auth, data, or feature logic.

## Requirements

### Requirement: App opens on the five-tab shell
The app SHALL open directly into a tab shell with exactly five tabs, in this order: Me, Partner, Us, Connection, More. The app MUST NOT present an authentication, onboarding, or pairing gate before the shell. The Me tab MUST be selected on launch.

#### Scenario: Cold launch
- **WHEN** the user launches the app
- **THEN** the shell shows the five tabs in the order Me, Partner, Us, Connection, More, and the Me tab is selected

#### Scenario: No sign-in step
- **WHEN** the user launches the app with no account and no stored session
- **THEN** the shell is shown without asking the user to sign in, pair, or complete onboarding

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

### Requirement: Shell does not depend on backend or stored user data
The shell MUST be usable with no network, no account, and no previously stored user content. The app MUST NOT show the template item list (timestamps with add and delete) in place of the shell.

#### Scenario: Offline launch
- **WHEN** the user launches the app with no network connection
- **THEN** all five tabs are still available and each shows its placeholder

#### Scenario: Template list is gone
- **WHEN** the user launches the app
- **THEN** the screen does not list stored items and does not offer add or delete for those items
