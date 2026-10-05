# Spec Delta

## Purpose

Lets each partner compose, send, and read short love notes within the Us tab — instant delivery only, no conditional triggers.

## ADDED Requirements

### Requirement: Love note model
A love note SHALL have an id, body text (max 100 characters, latin letters + digits + common punctuation + emoji), creation timestamp, direction (incoming or outgoing), status (sent or read), and an optional readAt timestamp. The session store SHALL hold an ordered array of love notes and expose seed demo notes on first launch.

#### Scenario: Seed notes on fresh session
- **WHEN** the user opens Us for the first time
- **THEN** at least one incoming demo love note is present in the notes list

#### Scenario: Body character limit
- **WHEN** the user types more than 100 characters in the compose field
- **THEN** input beyond 100 characters is not accepted

### Requirement: Compose and send a note
Tapping the pencil button on the Love Notes tile or the "Write a/another note" CTA on the Love Notes page SHALL open a Compose modal — a frosted-glass card centered over a dimmed scrim with a title "Write a note", a text area with placeholder, a character counter (current/max), and a "Send note" button. The Send button SHALL be inactive when the body is empty. On send, a new outgoing note with status sent SHALL be prepended to the session list, the modal SHALL close, and a brief "Sent" toast SHALL appear on the Us home. The user SHALL dismiss the modal via Close (×) or scrim tap without sending.

#### Scenario: Send a note
- **WHEN** the user types "You make me smile" and taps Send
- **THEN** a new outgoing note appears in the session list with status sent

#### Scenario: Empty body blocked
- **WHEN** the compose body is empty and the user taps Send
- **THEN** no note is created

#### Scenario: Dismiss without sending
- **WHEN** the compose modal is open and the user taps Close or the scrim
- **THEN** the modal closes and no note is added

#### Scenario: Sent toast
- **WHEN** a note is successfully sent
- **THEN** a brief toast confirmation appears on the Us home and auto-dismisses

### Requirement: Love Notes page
Tapping the Love Notes tile SHALL open a full-screen Love Notes page (slide from right). The page SHALL show a header with a back button, "Love Notes" label, and subtitle "Say something sweet — it only takes a moment". The page body SHALL contain two glass sections: "Incoming notes / Left for you" listing notes from the partner, and "Sent by you / On their way" listing the user's outgoing notes. Each section SHALL show a total count badge. Empty sections SHALL show an empty-state message. A navy CTA at the bottom ("Write a note" or "Write another note") SHALL open the Compose modal.

#### Scenario: Open page from tile
- **WHEN** the user taps the Love Notes tile body
- **THEN** the Love Notes page slides in from the right

#### Scenario: Back navigation
- **WHEN** the user taps the back button on the Love Notes page
- **THEN** the page closes and the Us home is visible

#### Scenario: Sections show notes
- **WHEN** the user has both incoming and outgoing notes
- **THEN** both sections list note rows with body preview, timestamp, and status

#### Scenario: Empty incoming section
- **WHEN** no incoming notes exist
- **THEN** the Incoming section shows "No notes for you yet" guidance

### Requirement: Note rows in sections
Each note row SHALL show a circular icon, a short body preview (truncated with ellipsis beyond ~15–52 chars depending on context), a formatted creation timestamp, and a status label. Incoming unlocked/new notes SHALL show "New note" with a body preview and be tappable to open the reader. Incoming read notes SHALL show "Seen" with a preview and a check icon. Outgoing notes SHALL show a status badge (sent / read) and a body preview.

#### Scenario: Incoming new note row
- **WHEN** an incoming note has status sent (unread)
- **THEN** the row shows "New note", a body preview, and is tappable

#### Scenario: Outgoing note status badge
- **WHEN** an outgoing note has status sent
- **THEN** the row shows a "sent" badge

### Requirement: Note reader overlay
Tapping a note row SHALL open a cinematic dark overlay showing a large envelope emoji, the full note body, and either partner attribution (for incoming) or a status line (for outgoing). Dismissing the reader SHALL close it. For incoming notes that were unread, dismissing SHALL mark them as read (status → read, readAt set to now).

#### Scenario: Read an incoming note
- **WHEN** the user taps an unread incoming note and then closes the reader
- **THEN** the note's status changes to read and readAt is set

#### Scenario: Preview an outgoing note
- **WHEN** the user taps an outgoing note
- **THEN** the reader shows the body and a status/delivery line without changing note state

### Requirement: Love Notes tile states
The Love Notes tile on the Us home SHALL reflect the current note state. When no notes exist, the tile SHALL show "Say something sweet — it only takes a moment". When only outgoing notes exist, the tile SHALL show "Your words are on their way" with a count badge. When incoming unread notes exist, the tile surface SHALL use a brighter pink gradient and show a count. The pencil button on the tile SHALL open the Compose modal directly (not the page).

#### Scenario: Empty tile state
- **WHEN** no love notes exist
- **THEN** the tile shows the default "Say something sweet" copy

#### Scenario: Outgoing-only tile
- **WHEN** only outgoing notes exist
- **THEN** the tile shows "Your words are on their way" and a count badge

#### Scenario: Incoming notes active tile
- **WHEN** incoming unread notes exist
- **THEN** the tile surface uses a brighter pink and shows the incoming count
