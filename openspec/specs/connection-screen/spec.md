# connection-screen Specification

## Purpose

Connection tab home for couple prompts: a full-bleed media carousel and a Today's Activity hub so partners can open daily tasks and approve each other's answers in-session, matching Figma Make `ConnectionScreen`.

## Requirements

### Requirement: Connection carousel home
The Connection tab SHALL show a full-bleed media carousel (edge-to-edge under the floating tab bar) with a “Connection” chrome label, seeded slides including at least Today's Activity, a partner-quiz teaser, and a Premium teaser. Each slide SHALL show title and supporting body over a darkened photo (or solid fallback). When a slide includes paired You/Partner tasks, those lines SHALL appear under the body. Users SHALL change slides by horizontal swipe and by tapping page dots when more than one slide exists. Auto-advance MAY cycle slides when the Today's Activity hub is closed.

#### Scenario: Open Connection tab
- **WHEN** the user selects the Connection tab
- **THEN** a full-bleed carousel is shown with the Connection label and at least one seeded slide

#### Scenario: Swipe between slides
- **WHEN** the user swipes horizontally on the carousel
- **THEN** the next or previous slide becomes visible

#### Scenario: Today's Activity slide shows paired tasks
- **WHEN** the Today's Activity slide is visible
- **THEN** the slide shows You and Partner task copy and a CTA labeled to open today's task

### Requirement: Carousel Start action
Tapping the centered CTA on the Today's Activity slide SHALL open the Today's Activity hub. Tapping Start on other seeded slides MUST NOT open the Today's Activity hub and MUST NOT navigate to quiz or Premium flows in this slice (no-op is allowed).

#### Scenario: Open Today's Activity from carousel
- **WHEN** the user taps the Today's Activity CTA
- **THEN** the Today's Activity hub opens over the carousel

#### Scenario: Other Start stays on carousel
- **WHEN** the user taps Start on the partner-quiz or Premium slide
- **THEN** the Today's Activity hub does not open

### Requirement: Today's Activity hub — Daily Task
The Today's Activity hub SHALL be a full-screen soft canvas with Back, beside branding, and a Daily Task card. The Daily Task SHALL progress through closed → open → waiting: closed shows a hint and “Open your daily task”; open shows You/Partner task text and “Mark as done”; waiting shows a waiting-for-partner message. Marking done SHALL set the user's daily activity completion for the session (so Us daily progress can reflect it). Back SHALL dismiss the hub and return to the carousel.

#### Scenario: Open daily task
- **WHEN** the hub is on closed and the user taps Open your daily task
- **THEN** the card shows You and Partner task text and Mark as done

#### Scenario: Mark daily task done
- **WHEN** the user taps Mark as done
- **THEN** the card shows the waiting-for-partner state and the session marks the user activity complete for today

#### Scenario: Back to carousel
- **WHEN** the user taps Back on the hub
- **THEN** the hub closes and the carousel remains visible

### Requirement: Today's Activity hub — awaiting approval
Below Daily Task, the hub SHALL show an “Awaiting your approval” section with seeded partner answer cards (name, time label, preview text) and an Approve control. Approving SHALL remove that answer from the pending list for the session. When none remain, the section SHALL show empty guidance.

#### Scenario: Approve partner answer
- **WHEN** a pending partner answer is shown and the user taps Approve
- **THEN** that answer disappears from the list

#### Scenario: Empty pending list
- **WHEN** no pending answers remain
- **THEN** the section shows that no answers are waiting
