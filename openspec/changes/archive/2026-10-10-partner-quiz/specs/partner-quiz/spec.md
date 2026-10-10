# Spec Delta

## Purpose

Lets one partner take a playful multiple-choice quiz by guessing the other’s seeded answers, then see a scored reveal of how well they know them.

## ADDED Requirements

### Requirement: Partner Quiz hub
The Connection tab SHALL present a Partner Quiz hub as a full-screen soft canvas with Back and beside branding. The hub SHALL run a seeded multiple-choice quiz in which the user guesses the partner’s answers. Each question SHALL offer three or four selectable options. The partner’s truth choice for each question SHALL be fixed for the session and MUST NOT be shown to the user before they submit a guess for that question (or before results, if guesses are collected then revealed together). Back SHALL dismiss the hub and return to the Connection carousel.

#### Scenario: Open hub shows first question
- **WHEN** the user opens Partner Quiz
- **THEN** the hub shows a question with multiple-choice options and does not show the partner’s truth for that question

#### Scenario: Select a guess
- **WHEN** the user selects an option on a question
- **THEN** that option is marked selected and the user can submit or advance according to the quiz flow

#### Scenario: Back to carousel
- **WHEN** the user taps Back on the Partner Quiz hub
- **THEN** the hub closes and the Connection carousel remains visible

### Requirement: Quiz results after guesses
After the user has submitted guesses for all seeded questions, the hub SHALL show a results view with the number of correct guesses out of the total and SHALL reveal the partner’s truth for each question (and whether the user’s guess matched).

#### Scenario: Complete quiz shows score
- **WHEN** the user finishes guessing every question
- **THEN** the hub shows a score (correct / total) and per-question truth vs guess

### Requirement: Session demo partner truths
For the in-session demo, partner truth answers SHALL be available without a network round-trip (seeded in the session) so the quiz and results can be completed on one device.

#### Scenario: Seeded truths enable scoring
- **WHEN** the user completes the quiz in a fresh session
- **THEN** each guess can be scored against a seeded partner truth
