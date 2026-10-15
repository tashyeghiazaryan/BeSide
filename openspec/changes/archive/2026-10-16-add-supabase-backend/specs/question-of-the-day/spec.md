# question-of-the-day Spec Delta

## MODIFIED Requirements

### Requirement: Question of the day dialogue hub
The Connection tab SHALL present a Question of the day hub as a full-screen soft canvas with Back and beside branding. The hub SHALL show one shared daily question and a free-text answer field while the user has not submitted. Submitting a non-empty answer SHALL store the user's answer for the couple/day and MUST NOT reveal the partner's answer until the partner has also submitted. While waiting for the partner, the hub SHALL show waiting guidance without partner answer text. When both partners have submitted, the hub SHALL show both answers as a dialogue (You and Partner turns). Back SHALL dismiss the hub and return to the Connection carousel. In Supabase mode, answers MUST persist and load from the backend; in demo mode, session storage is sufficient.

#### Scenario: Wait until partner answers (Supabase)
- **WHEN** the user submits an answer and the partner has not yet submitted
- **THEN** the hub shows waiting guidance and does not show partner answer text

#### Scenario: Dialogue when both answered (Supabase)
- **WHEN** both partners have submitted answers for today’s question
- **THEN** the hub shows both answers as You and Partner turns after sync

### Requirement: Session demo partner answer
For demo backend mode only, after the user submits their answer the session SHALL allow a partner answer to become available without a network round-trip (seeded or simulated submit) so the dialogue reveal can be exercised on one device. In Supabase mode, this requirement MUST NOT apply; the partner answer MUST come from the partner’s authenticated submit.

#### Scenario: Partner answer arrives in demo session
- **WHEN** backend mode is demo and the user has submitted their answer
- **THEN** a partner answer can appear in-session without a network round-trip so the dialogue can be reviewed
