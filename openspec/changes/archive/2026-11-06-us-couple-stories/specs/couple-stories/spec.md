# Spec Delta — couple-stories

## Purpose

Instagram-style couple photo stories on Us: strip, full-screen viewer, archive grid, and session-first create flow until live sync is wired.

## ADDED Requirements

### Requirement: Couple stories strip under Us hero
Below the Us hero (and above the 2×2 entry tiles), the Us home SHALL show a horizontal Instagram-style stories strip: an Add control, then rings for each couple story newest-first. Rings MUST NOT be hard-clipped mid-circle by page inset (full-bleed scroll with matching content padding). Unseen stories SHALL use a distinct ring treatment from seen stories.

#### Scenario: Empty strip still shows Add
- **WHEN** the couple has no stories yet
- **THEN** the strip shows an Add control so the user can create the first story

#### Scenario: Rings list newest first
- **WHEN** multiple stories exist
- **THEN** they appear newest-first after Add

### Requirement: Add story from camera or library
Tapping Add SHALL offer camera and photo library. A successful capture or pick SHALL append a couple story (JPEG) authored by the current user into the session couple-stories list and show it in the strip.

#### Scenario: Add from library
- **WHEN** the user picks a photo from the library for a couple story
- **THEN** a new story appears in the strip for the couple

### Requirement: Full-screen story viewer
Tapping a story ring SHALL open a full-screen viewer over the story list. The viewer SHALL support advancing through stories, mark the current user’s stories as seen when viewed, and dismiss back to Us home.

#### Scenario: Open and dismiss viewer
- **WHEN** the user taps a story ring then closes the viewer
- **THEN** Us home is visible again and that story is marked seen for the current user

### Requirement: Stories archive via See all
When at least one story exists, Us SHALL expose a See all control above the strip. Tapping it SHALL open a grid archive of past couple stories. Tapping a cell SHALL open the same full-screen viewer positioned on that story.

#### Scenario: See all opens archive
- **WHEN** stories exist and the user taps See all
- **THEN** a grid archive of those stories opens

#### Scenario: Archive cell opens viewer
- **WHEN** the user taps a story cell in the archive
- **THEN** the full-screen viewer opens on that story
