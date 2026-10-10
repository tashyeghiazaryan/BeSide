# Spec Delta

## MODIFIED Requirements

### Requirement: Carousel Start action
Tapping the centered CTA on the Today's Activity slide SHALL open the Today's Activity hub. Tapping Start on the Question of the day slide SHALL open the Question of the day hub. Tapping Start on the partner-quiz slide SHALL open the Partner Quiz hub. Tapping Start on other seeded slides (Premium) MUST NOT open those hubs and MUST NOT navigate to Premium flows in this slice (no-op is allowed). Opening Today's Activity, Question of the day, or Partner Quiz from Sections SHALL behave the same as the matching carousel Start.

#### Scenario: Open Today's Activity from carousel
- **WHEN** the user taps the Today's Activity CTA
- **THEN** the Today's Activity hub opens over the carousel

#### Scenario: Open Question of the day from carousel
- **WHEN** the user taps Start on the Question of the day slide
- **THEN** the Question of the day hub opens over the carousel

#### Scenario: Open Partner Quiz from carousel
- **WHEN** the user taps Start on the partner-quiz slide
- **THEN** the Partner Quiz hub opens over the carousel

#### Scenario: Other Start stays on carousel
- **WHEN** the user taps Start on the Premium slide
- **THEN** neither the Today's Activity hub, the Question of the day hub, nor the Partner Quiz hub opens
