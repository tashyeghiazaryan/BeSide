# love-notes Spec Delta

## MODIFIED Requirements

### Requirement: Love note model
A love note SHALL have an id, body text (max 100 characters, latin letters + digits + common punctuation + emoji), creation timestamp, sender/recipient (direction derived for the current user as incoming or outgoing), status (sent or read), and an optional readAt timestamp. In Supabase mode, notes SHALL persist for the couple and MUST be readable by both members after sync. In demo mode, the session store MAY hold an ordered array and expose seed demo notes on first launch.

#### Scenario: Notes load for couple (Supabase)
- **WHEN** a paired user opens Love Notes after notes were exchanged earlier
- **THEN** outgoing and incoming notes appear without relying only on session seeds

### Requirement: Compose and send a note
Tapping the pencil button on the Love Notes tile or the "Write a/another note" CTA on the Love Notes page SHALL open a Compose modal — a frosted-glass card centered over a dimmed scrim with a title "Write a note", a text area with placeholder, a character counter (current/max), and a "Send note" button. The Send button SHALL be inactive when the body is empty. On send in Supabase mode, a new outgoing note with status sent SHALL persist for the couple, become available to the partner after sync, the modal SHALL close, and a brief "Sent" toast SHALL appear on the Us home. In demo mode, the note SHALL be prepended to the session list. The user SHALL dismiss the modal via Close (×) or scrim tap without sending.

#### Scenario: Send delivers to partner (Supabase)
- **WHEN** the user sends a valid note while online and paired
- **THEN** the partner sees that note as incoming after sync

### Requirement: Note reader overlay
Opening a note SHALL show a reader overlay with the note body and metadata. Marking an incoming unread note as read SHALL set status read and readAt. In Supabase mode, read state MUST sync so the sender can observe read when the product surfaces it. Dismiss via Close or scrim.

#### Scenario: Read receipt syncs (Supabase)
- **WHEN** the recipient opens an unread incoming note while online
- **THEN** the note’s read state is persisted for the couple
