# more-screen Specification

## Purpose

Gives the More tab a profile and settings home so partners can manage pairing, Premium, preferences, support links, and sign-out without leaving the five-tab shell.

## Requirements

### Requirement: More screen layout
The More tab SHALL present a scrollable soft-canvas screen with a “More” header and short supporting subtitle, a profile card (avatar initial or image affordance, display name, Free/Premium plan label, Edit profile control), then sectioned cards for Pair, Subscription, Preferences, Support, and Account, plus an app version footer. The floating tab bar SHALL remain visible. The screen MUST identify itself for accessibility as More (not a blank named-only placeholder).

#### Scenario: Open More tab
- **WHEN** the user selects the More tab
- **THEN** the More screen shows the header, profile card, and the Pair / Subscription / Preferences / Support / Account sections

#### Scenario: Profile reflects session identity
- **WHEN** the More screen is visible
- **THEN** the profile card shows the session display name and whether the plan is Free or Premium

### Requirement: Pair section
When the user is unpaired, the Pair section SHALL offer a control to connect with a partner (invite/code flow). When paired, it SHALL show that a partner is connected (using the partner display name when available) and offer a manage-pair affordance. Tapping the unpaired connect control SHALL open the existing pairing flow used elsewhere in the app. Tapping manage-pair MAY open the same pairing/manage UI or a lightweight sheet in this slice.

#### Scenario: Unpaired connect
- **WHEN** the user is unpaired and taps Connect with your partner
- **THEN** the pairing flow opens

#### Scenario: Paired row
- **WHEN** the user is paired and opens More
- **THEN** the Pair section indicates the partner connection (by name when known)

### Requirement: Subscription section
The Subscription section SHALL show Try Premium when the user is not Premium, or Premium active when they are. Tapping Try Premium SHALL use the session demo Premium unlock (no StoreKit). Tapping Premium active MAY open a lightweight manage sheet or no-op that keeps the user on More.

#### Scenario: Unlock demo Premium
- **WHEN** the user is not Premium and taps Try Premium
- **THEN** the session marks Premium active and the Subscription row reflects Premium

### Requirement: Preferences and Support rows
Preferences SHALL include Notifications and Privacy & data rows. Support SHALL include Help & FAQ and Terms & privacy policy rows. Tapping these rows SHALL open a lightweight sheet or stub destination in this slice (full settings backends are out of scope).

#### Scenario: Open a preferences or support stub
- **WHEN** the user taps Notifications, Privacy & data, Help & FAQ, or Terms & privacy policy
- **THEN** a sheet or stub screen opens and can be dismissed back to More

### Requirement: Account log out
The Account section SHALL include a Log out control. In Supabase-authenticated mode, Log out SHALL sign the user out of the app session so the auth gate can appear. In demo backend mode, Log out MAY be a no-op that keeps the demo shell, or may reset to the demo entry — but MUST NOT crash.

#### Scenario: Log out when authenticated
- **WHEN** the user is in Supabase authenticated mode and taps Log out
- **THEN** the session ends and the five-tab shell is no longer shown until they sign in again
