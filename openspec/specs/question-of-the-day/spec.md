# question-of-the-day Specification

## Purpose

Lets a paired couple answer one shared daily question privately and see both answers as a dialogue only after both partners have submitted.

## Requirements

### Requirement: Question of the day dialogue hub
The Connection tab SHALL present a Question of the day hub as a full-screen soft canvas with Back and beside branding. The hub SHALL show one shared session question and a free-text answer field while the user has not submitted. Submitting a non-empty answer SHALL store the user's answer for the session and MUST NOT reveal the partner's answer until the partner has also submitted. While waiting for the partner, the hub SHALL show waiting guidance without partner answer text. When both partners have submitted, the hub SHALL show both answers as a dialogue (You and Partner turns). Back SHALL dismiss the hub and return to the Connection carousel.

#### Scenario: Open hub shows question and composer
- **WHEN** the user opens Question of the day
- **THEN** the hub shows the shared question and an answer composer

#### Scenario: Submit own answer waits for partner
- **WHEN** the user submits a non-empty answer and the partner has not submitted
- **THEN** the hub shows waiting guidance and does not show the partner's answer

#### Scenario: Reveal dialogue when both answered
- **WHEN** both partners have submitted answers for today's question
- **THEN** the hub shows both answers as a You / Partner dialogue

#### Scenario: Back to carousel
- **WHEN** the user taps Back on the Question of the day hub
- **THEN** the hub closes and the Connection carousel remains visible

### Requirement: Session demo partner answer
For the in-session demo, after the user submits their answer the session SHALL allow a partner answer to become available without a network round-trip (seeded or simulated submit) so the dialogue reveal can be exercised in one session.

#### Scenario: Partner answer arrives in session
- **WHEN** the user has submitted and the demo partner answer is recorded
- **THEN** both answers become visible in the dialogue
