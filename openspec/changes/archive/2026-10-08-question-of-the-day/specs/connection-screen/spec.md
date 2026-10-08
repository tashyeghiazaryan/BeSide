# Spec Delta

## MODIFIED Requirements

### Requirement: Connection carousel home
The Connection tab SHALL show a full-bleed media carousel (edge-to-edge under the floating tab bar) with a “Connection” chrome label, seeded slides including at least Today's Activity, Question of the day, a partner-quiz teaser, and a Premium teaser. Each slide SHALL show title and supporting body over a darkened photo (or solid fallback). When a slide includes paired You/Partner tasks, those lines SHALL appear under the body. Users SHALL change slides by horizontal swipe and by tapping page dots when more than one slide exists. Auto-advance MAY cycle slides when no Connection hub overlay is open.

#### Scenario: Open Connection tab
- **WHEN** the user selects the Connection tab
- **THEN** a full-bleed carousel is shown with the Connection label and at least one seeded slide

#### Scenario: Swipe between slides
- **WHEN** the user swipes horizontally on the carousel
- **THEN** the next or previous slide becomes visible

#### Scenario: Today's Activity slide shows paired tasks
- **WHEN** the Today's Activity slide is visible
- **THEN** the slide shows You and Partner task copy and a CTA labeled to open today's task

#### Scenario: Question of the day slide is seeded
- **WHEN** the user browses the Connection carousel or Sections index
- **THEN** a Question of the day slide is available among the seeded slides

### Requirement: Carousel Start action
Tapping the centered CTA on the Today's Activity slide SHALL open the Today's Activity hub. Tapping Start on the Question of the day slide SHALL open the Question of the day hub. Tapping Start on other seeded slides (partner-quiz, Premium) MUST NOT open those hubs and MUST NOT navigate to quiz or Premium flows in this slice (no-op is allowed). Opening either hub from Sections SHALL behave the same as the matching carousel Start.

#### Scenario: Open Today's Activity from carousel
- **WHEN** the user taps the Today's Activity CTA
- **THEN** the Today's Activity hub opens over the carousel

#### Scenario: Open Question of the day from carousel
- **WHEN** the user taps Start on the Question of the day slide
- **THEN** the Question of the day hub opens over the carousel

#### Scenario: Other Start stays on carousel
- **WHEN** the user taps Start on the partner-quiz or Premium slide
- **THEN** neither the Today's Activity hub nor the Question of the day hub opens
