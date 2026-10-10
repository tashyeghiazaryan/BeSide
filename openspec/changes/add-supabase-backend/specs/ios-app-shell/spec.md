# ios-app-shell Spec Delta

## MODIFIED Requirements

### Requirement: App opens on the five-tab shell
When the user is authenticated (and, in Supabase mode, past any required auth gate), the app SHALL show a tab shell with exactly five tabs, in this order: Me, Partner, Us, Connection, More. The Me tab MUST be selected when the shell first appears after auth. In demo backend mode, the app MAY open directly into the shell without authentication, onboarding, or pairing gates (preserving prior local QA behavior).

#### Scenario: Cold launch signed-in
- **WHEN** the user launches the app with a valid session (Supabase mode) or in demo mode
- **THEN** the shell shows the five tabs in the order Me, Partner, Us, Connection, More, and the Me tab is selected

#### Scenario: Cold launch signed-out (Supabase mode)
- **WHEN** the user launches the app in Supabase mode with no account and no stored session
- **THEN** sign-in is shown and the five-tab shell is not shown until authentication succeeds

### Requirement: Shell launch does not require prior couple content
The shell MUST remain usable when the authenticated user has no previously stored couple content (empty histories, unpaired). The app MUST NOT show the template item list (timestamps with add and delete) in place of the shell. Offline launch in demo mode MUST still show all five tabs. In Supabase mode, offline launch with a restored session MAY show the shell with cached or empty feature content; offline launch without a session follows the auth gate.

#### Scenario: Empty couple content
- **WHEN** a newly authenticated unpaired user reaches the shell
- **THEN** all five tabs are available and the template item list is not shown

#### Scenario: Template list is gone
- **WHEN** the user reaches the shell
- **THEN** the screen does not list stored template items and does not offer add or delete for those items
