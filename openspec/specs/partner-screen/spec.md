# partner-screen Specification

## Purpose

Shows the partner’s current mood and week history on the Partner tab, lets the user react (and optionally leave a short note), and surfaces care suggestions — matching Figma Make Partner, including the unpaired invite overlay.

## Requirements

### Requirement: Partner visual treatment matches Figma Make
The Partner tab SHALL use the Partner frame visual language from `design-reference` `PartnerScreen.tsx`: soft canvas with ambient blurs tinted by the partner’s current mood, a mood-tinted frosted hero card with a large gradient mood sphere, glass care-suggestion cards, and a glass “Mood this week” strip. The Partner tab MUST NOT present as a blank named-only placeholder or a flat undecorated form when paired.

#### Scenario: Paired Partner reads as glass mood UI
- **WHEN** the user opens the Partner tab while paired and the partner has a current mood
- **THEN** the screen shows a mood-tinted hero card and ambient background rather than only the word Partner

### Requirement: Partner header and current mood hero
When paired and the partner has shared a mood, the Partner tab SHALL show a title “Your partner’s mood”, a short line that the partner feels that mood today (using the partner display name), and a hero card with that mood’s name, quoted wish, and shared date/time.

#### Scenario: Hero shows current partner mood
- **WHEN** the partner’s current mood is Stressed & Irritated with wish “Just listen without judging.”
- **THEN** the hero shows that mood name, the quoted wish, and a shared timestamp

#### Scenario: Feeling line uses partner name
- **WHEN** the partner display name is Alex and the current mood is stressed
- **THEN** the screen shows a line that Alex feels stressed today

### Requirement: User can send an emoji reaction on the hero
The hero card SHALL offer “Send a reaction” that expands an inline emoji picker (the same eight emojis as the reference). Choosing an emoji and tapping Send SHALL store the reaction locally without network access and confirm briefly. The user MAY send **at most one** reaction per current partner mood; after sending, the UI SHALL show a locked “You reacted” state with no Change/Update. Cancelling the picker SHALL return to “Send a reaction” without saving. When the partner’s current mood is replaced, the reaction slot SHALL reset so a new reaction can be sent.

#### Scenario: Send reaction
- **WHEN** the user opens the reaction picker and taps 🤗 then Send
- **THEN** that reaction is saved locally and a brief “Reaction sent!” confirmation appears

#### Scenario: One reaction per partner mood
- **WHEN** a reaction is already saved for the current partner mood
- **THEN** the UI shows “You reacted” (and note if any) and does not offer Change or Update

#### Scenario: New partner mood resets reaction
- **WHEN** the partner’s current mood is replaced with a new share
- **THEN** the previous reaction is cleared and “Send a reaction” is available again

### Requirement: Optional note on partner mood
After or alongside a reaction, the Partner tab MAY offer an optional short note field that follows the Partner note rules in `Требования полей.md` (Latin/punct/emoji, max 60, validate on send). An empty note is allowed. When a note is saved with a reaction, it MUST appear on the partner mood surface in this session.

#### Scenario: Note optional
- **WHEN** the user sends a reaction with an empty note
- **THEN** the reaction is saved and no note text is required

#### Scenario: Invalid note blocked
- **WHEN** the user enters disallowed characters in the note and tries to save
- **THEN** an inline error is shown and the invalid note is not saved

### Requirement: Care suggestions for the current mood
Below the hero, the Partner tab SHALL show a “Small ways to show you care” section with display-only suggestion cards for the partner’s current mood, using the same mood→suggestions map as the Figma Make reference. Tapping a suggestion MUST NOT send a network request or change stored reaction state.

#### Scenario: Suggestions match mood
- **WHEN** the partner’s current mood is stressed
- **THEN** the care section lists the stressed suggestion set from the product catalog

### Requirement: Partner week history
When paired, the Partner tab SHALL show a “Mood this week” strip for the partner’s last seven days ending today. Days with entries MUST show the latest mood micro-sphere and a count badge when there is more than one entry that day. Tapping a day with entries SHALL open a compact day-detail popup above the strip listing that day’s moods and times (scroll when many). Empty days MUST NOT open a detail. The strip MAY use seed history so the week is not empty on first launch.

#### Scenario: Expand partner day
- **WHEN** the user taps a partner week day that has at least one mood
- **THEN** a day-detail popup above the strip shows that day’s moods and times

#### Scenario: Empty partner day
- **WHEN** the user taps a partner week day with no moods
- **THEN** no day-detail popup opens

### Requirement: Unpaired invite overlay
When the user is not paired with a partner, the Partner tab SHALL show a blurred, non-interactive preview of the Partner content and a non-dismissible modal to invite (share a local invite code) or join (enter a code). Completing invite or join in this session MUST unlock the paired Partner UI without requiring a server. The modal MUST NOT close by tapping outside.

#### Scenario: Unpaired shows invite modal
- **WHEN** the user opens Partner while unpaired
- **THEN** a pairing modal is visible over a blurred Partner preview and outside taps do not dismiss it

#### Scenario: Join unlocks Partner
- **WHEN** the user enters a join code and confirms join in the unpaired modal
- **THEN** the modal dismisses and the paired Partner mood UI is interactive
