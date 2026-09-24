# Spec Delta

## Purpose

Lets the user express how they feel on the Me tab by picking a mood and a wish, seeing a local share confirmation, and reviewing this week’s moods — all without a server — with visuals matching the Figma Make Me frame.

## ADDED Requirements

### Requirement: Me shows greeting and current mood
On the Me tab the app SHALL show a time-based greeting that includes a display name, a short “How are you feeling?” prompt, and a current-mood panel. When no mood has been shared in this session, the panel MUST explain that the user can select a mood below. When a mood has been shared, the panel MUST show that mood’s name, the chosen wish, and when it was shared.

#### Scenario: Empty current mood
- **WHEN** the user opens the Me tab and has not shared a mood in this session
- **THEN** the screen shows a greeting and a current-mood panel that invites them to select a mood

#### Scenario: Current mood after share
- **WHEN** the user has shared a mood and wish in this session
- **THEN** the current-mood panel shows that mood’s name, the wish text, and a shared time

### Requirement: Me visual treatment matches Figma Make
The Me tab SHALL use the Main app → Me visual language from `design-reference`: a light soft gradient canvas, frosted translucent panels with light borders for the current-mood block, wish cards, and week strip, and six circular mood spheres that use each mood’s catalog color/gradient with a centered icon. While a mood is selected, the background MUST show ambient color blurs tinted by that mood. Selected spheres MUST be emphasized (for example a bright ring and fuller opacity); non-selected spheres MUST appear dimmed. Wish cards and the share control MUST pick up the selected mood’s color when active. The Me tab MUST NOT use a flat undecorated list or plain untinted circular buttons in place of this treatment.

#### Scenario: Glass panels and spheres visible
- **WHEN** the user opens the Me tab
- **THEN** the current-mood area and mood controls appear as frosted panels and colored gradient spheres rather than a plain text-only or untinted control list

#### Scenario: Mood tint on selection
- **WHEN** the user selects a mood
- **THEN** ambient background tint reflects that mood and the selected sphere is visually emphasized over the others

### Requirement: User picks one of six moods
The Me tab SHALL offer exactly six moods in this set: Calm & Balanced, Joy & High Energy, Love & Connection, Sad & Vulnerable, Exhausted & Low Battery, Stressed & Irritated. Tapping a mood SHALL select it; tapping the selected mood again SHALL clear the selection and any selected wish. Selecting a different mood SHALL clear the previous wish.

#### Scenario: Select a mood
- **WHEN** the user taps Joy & High Energy
- **THEN** that mood is selected and the other moods are not selected

#### Scenario: Deselect a mood
- **WHEN** the user taps the already selected mood
- **THEN** no mood is selected and no wish list is shown

### Requirement: User picks a wish for the selected mood
After a mood is selected, the Me tab SHALL show the wish options for that mood from the product catalog. Tapping a wish SHALL select it. Wish options MUST NOT appear when no mood is selected.

#### Scenario: Wishes appear for mood
- **WHEN** the user selects Calm & Balanced
- **THEN** the three Calm wish options from the catalog are shown

#### Scenario: No wishes without mood
- **WHEN** no mood is selected
- **THEN** no wish options are shown

### Requirement: Share stays on the device
When a mood and a wish are both selected, the Me tab SHALL offer a control to share with the partner. Activating it MUST NOT require network access and MUST NOT send data to a server. After share completes, the app SHALL briefly confirm success, then clear the in-progress mood and wish selection while keeping the shared entry as the current mood and in the week history.

#### Scenario: Share without network
- **WHEN** the user has selected a mood and a wish and activates share with no network
- **THEN** the share succeeds locally and a success confirmation appears

#### Scenario: Selection clears after share
- **WHEN** the local share confirmation finishes
- **THEN** no mood or wish remains selected for a new share, and the shared mood appears in the current-mood panel

### Requirement: Week history shows the last seven days
The Me tab SHALL show a “My mood this week” strip for the last seven days ending today. Days without entries MUST be visually empty. Days with entries MUST show the latest mood for that day. The strip MAY start with mock seed entries so the week is not empty on first launch. Tapping a day that has entries SHALL expand or collapse a short list of that day’s moods and times.

#### Scenario: Week strip visible
- **WHEN** the user opens the Me tab
- **THEN** a week history section labeled for this week’s moods is visible with seven day slots

#### Scenario: Expand a day with entries
- **WHEN** the user taps a day that has at least one mood entry
- **THEN** that day’s mood entries and times are shown

#### Scenario: Empty day stays empty
- **WHEN** the user taps a day with no mood entries
- **THEN** no day detail list opens
