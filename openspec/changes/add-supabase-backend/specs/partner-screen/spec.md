# partner-screen Spec Delta

## MODIFIED Requirements

### Requirement: User can send an emoji reaction on the hero
When a partner current mood is shown, the Partner tab SHALL let the user send exactly one emoji reaction for that mood share. In Supabase mode, the reaction MUST persist against that mood share and become visible on the partner’s Me surfaces after sync. A second reaction for the same mood share MUST NOT replace or duplicate the first. In demo mode, the reaction MAY remain session-local.

#### Scenario: Send reaction once
- **WHEN** the user selects an allowed reaction emoji on the partner mood hero
- **THEN** the reaction is saved for that mood share and the UI shows it as sent

#### Scenario: Partner sees reaction (Supabase)
- **WHEN** user A reacts to user B’s mood share while both are paired online
- **THEN** user B’s Me surface shows A’s reaction after sync

### Requirement: Optional note on partner mood
After or alongside a reaction, the Partner tab MAY offer an optional short note field that follows the Partner note rules in `Требования полей.md` (Latin/punct/emoji, max 60, validate on send). An empty note is allowed. When a note is saved with a reaction in Supabase mode, it MUST persist with the reaction and appear on the partner’s Me surface after sync. In demo mode, it MUST appear on the partner mood surface in this session.

#### Scenario: Note saved with reaction
- **WHEN** the user sends a valid note with a reaction
- **THEN** the note is stored with that reaction for the mood share

### Requirement: Unpaired invite overlay
When the user is not paired with a partner, the Partner tab SHALL show a blurred, non-interactive preview of the Partner content and a non-dismissible modal to invite (share an invite code) or join (enter a code). In Supabase mode, create/join MUST complete via the server (`couple-backend`); only a confirmed membership unlocks the paired Partner UI. In demo mode, completing invite or join in-session MAY unlock without a server. The modal MUST NOT close by tapping outside.

#### Scenario: Unpaired shows invite modal
- **WHEN** the user opens Partner while unpaired
- **THEN** a pairing modal is visible over a blurred Partner preview and outside taps do not dismiss it

#### Scenario: Join unlocks Partner (Supabase)
- **WHEN** the user enters a valid join code and the server accepts membership
- **THEN** the modal dismisses and the paired Partner mood UI is interactive
