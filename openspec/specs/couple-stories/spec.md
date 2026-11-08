# couple-stories Specification

## Purpose

Instagram-style couple photo stories on Us: strip, full-screen viewer, archive grid, and session-first create flow until live sync is wired.

## Requirements

### Requirement: Couple stories strip under Us hero
Below the Us hero (and above the 2×2 entry tiles), the Us home SHALL show a horizontal Instagram-style stories strip: an Add control, then rings for each **live** couple story newest-first. A story is live for 24 hours from `createdAt`; after that it MUST leave the strip rings. Rings MUST NOT be hard-clipped mid-circle by page inset (full-bleed scroll with matching content padding). Unseen stories SHALL use a distinct ring treatment from seen stories.

#### Scenario: Empty strip still shows Add
- **WHEN** the couple has no live stories
- **THEN** the strip shows an Add control so the user can create the first story

#### Scenario: Rings list newest first
- **WHEN** multiple live stories exist
- **THEN** they appear newest-first after Add

#### Scenario: Expired story leaves the strip
- **WHEN** a story is older than 24 hours
- **THEN** it does not appear as a ring on the strip

### Requirement: Stories expire from the strip after 24 hours
Each couple story SHALL remain in the Us strip for 24 hours from creation. After expiry the story MUST NOT appear in strip rings or in the strip-launched viewer sequence.

#### Scenario: Just under 24 hours still live
- **WHEN** a story was created less than 24 hours ago
- **THEN** it appears in the strip

### Requirement: Stories enter history immediately and stay
The moment a story is created it SHALL appear in See all / history and SHALL remain there indefinitely (including after the 24-hour strip window). History MUST list live and expired stories newest-first. Expiry MUST remove the story only from the strip, never from history.

#### Scenario: New story in history right away
- **WHEN** the user adds a story
- **THEN** it is listed in See all / history immediately, not only after 24 hours

#### Scenario: Expired story still in history
- **WHEN** a story is older than 24 hours and the user opens See all
- **THEN** that story is still listed in the history grid

### Requirement: Add story from camera or library
Tapping Add SHALL offer camera and photo library. A successful capture or pick SHALL append a couple story (JPEG) authored by the current user into the session couple-stories list, show it in the strip while live, and add it to history immediately.

#### Scenario: Add from library
- **WHEN** the user picks a photo from the library for a couple story
- **THEN** a new story appears in the strip and in history for the couple

### Requirement: Full-screen story viewer
Tapping a story ring SHALL open a full-screen viewer over the story list. The viewer SHALL support advancing through stories, mark the current user’s stories as seen when viewed, and dismiss back to Us home.

#### Scenario: Open and dismiss viewer
- **WHEN** the user taps a story ring then closes the viewer
- **THEN** Us home is visible again and that story is marked seen for the current user

### Requirement: Stories archive via See all
When at least one story exists (live or expired), Us SHALL expose a See all control above the strip. Tapping it SHALL open a history grid of all couple stories newest-first. Tapping a cell SHALL open the full-screen viewer over the full history list positioned on that story.

#### Scenario: See all opens archive
- **WHEN** stories exist and the user taps See all
- **THEN** a grid of those stories opens, including ones still live on the strip

#### Scenario: Archive cell opens viewer
- **WHEN** the user taps a story cell in the archive
- **THEN** the full-screen viewer opens on that story
