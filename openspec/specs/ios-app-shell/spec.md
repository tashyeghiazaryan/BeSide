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

### Requirement: Shell does not depend on backend or stored user data
The shell MUST be usable with no network, no account, and no previously stored user content. The app MUST NOT show the template item list (timestamps with add and delete) in place of the shell.

#### Scenario: Offline launch
- **WHEN** the user launches the app with no network connection
- **THEN** all five tabs are still available and each shows its placeholder

#### Scenario: Template list is gone
- **WHEN** the user launches the app
- **THEN** the screen does not list stored items and does not offer add or delete for those items
