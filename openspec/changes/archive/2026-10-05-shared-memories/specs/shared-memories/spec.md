# Spec Delta

## Purpose

Session-backed Shared Memories on the Us tab: home carousel, add modal, user-added gallery with date filter, detail viewer, and system share — matching Figma Make `UsScreen` behavior for this slice.

## ADDED Requirements

### Requirement: Shared memory model
A shared memory SHALL have an id, title, dateTime, optional description, mood emoji, optional photo reference, likes count, likedByMe flag, and addedByUser flag. The session store SHALL hold an ordered array of memories and expose demo seeds on first launch (at least one non-user seed and one or more user-added seeds).

#### Scenario: Seed memories on fresh session
- **WHEN** the user opens Us for the first time
- **THEN** the Shared Memories carousel shows seeded memories including at least one titled moment

#### Scenario: User-added flag
- **WHEN** the user successfully adds a memory via Add
- **THEN** that memory is marked addedByUser and appears in the gallery

### Requirement: Us home Shared Memories section
The Us home SHALL show a matte frosted Shared Memories section with title “Shared Memories”, supporting subtitle, a `+` control that opens Add, and a header control that opens the gallery. When memories exist, the section SHALL show a horizontal swipeable card carousel (photo or mood placeholder, title, short date, share control on the card) and page dots when there is more than one card. When empty, the section SHALL show guidance to add the first moment. Tapping a card (without a drag) SHALL open the detail viewer for that memory.

#### Scenario: Open gallery from header
- **WHEN** the user taps the Shared Memories header
- **THEN** the Shared Memories gallery page opens

#### Scenario: Open add from plus
- **WHEN** the user taps `+` on the Shared Memories section
- **THEN** the Add memory modal opens

#### Scenario: Open detail from carousel card
- **WHEN** the user taps a carousel card without having dragged
- **THEN** the memory detail overlay opens for that memory

#### Scenario: Empty carousel
- **WHEN** no memories exist
- **THEN** the section shows empty-state guidance instead of cards

### Requirement: Add memory modal
The Add memory modal SHALL be a centered frosted-glass card over a dimmed/blurred scrim titled “Share a new memory” with subtitle copy. It SHALL collect title (required, max 40), date/time (defaults to now if unset), optional description (max 120), optional photo via device picker (Wishlist-style), and a mood emoji from a fixed set. Title and description SHALL accept Latin letters, digits, common punctuation, spaces, and emoji only; disallowed characters are filtered on input. “Share a memory” SHALL create a new memory with addedByUser true, prepend it to the session list, close the modal, reset fields, and open the gallery with filter All when validation passes. Validation failures SHALL show inline alerts under the relevant field (not system alerts). Empty title, whitespace-only description, or invalid text MUST NOT create a memory. Dismiss via Close or scrim without requiring save.

#### Scenario: Add with title
- **WHEN** the user enters a title and taps Share a memory
- **THEN** the memory is stored, the modal closes, and the gallery opens showing memories

#### Scenario: Incomplete add blocked
- **WHEN** the title is empty and the user taps Share a memory
- **THEN** an inline alert appears under Title and no memory is created

#### Scenario: Description spaces-only blocked
- **WHEN** the description contains only spaces and the user taps Share a memory
- **THEN** an inline alert appears under Description and no memory is created

#### Scenario: Dismiss without saving
- **WHEN** the Add modal is open and the user taps Close or the scrim
- **THEN** the modal closes and no memory is added

### Requirement: Shared Memories gallery page
Tapping the Shared Memories header SHALL open a full-screen gallery page (slide from right) titled Shared Memories with subtitle “Moments you added”, back control, and `+` to Add. The page SHALL list only memories with addedByUser true in a two-column grid, filterable by All or by month chips derived from those memories. Empty states SHALL distinguish “no moments yet” vs “nothing in this month”. Tapping a grid cell SHALL open the detail viewer.

#### Scenario: Gallery shows only user-added
- **WHEN** both seeded non-user and user-added memories exist
- **THEN** the gallery grid shows only user-added memories

#### Scenario: Filter by month
- **WHEN** the user selects a month chip
- **THEN** only user-added memories in that month are shown

#### Scenario: Back to Us
- **WHEN** the user taps back on the gallery
- **THEN** the gallery closes and the Us home remains visible

### Requirement: Memory detail and share
Opening a memory SHALL show a frosted detail overlay with photo or mood hero, title, short date, optional description, and a Share action that presents the system share sheet (or equivalent) with mood, title, date, and description text. The user SHALL dismiss via Close or scrim. Horizontal swipe SHALL move to the previous/next memory in the full session list when available.

#### Scenario: Share memory
- **WHEN** the user taps Share on a memory card or detail
- **THEN** a system share sheet (or share presentation) is offered with that memory’s text summary

#### Scenario: Swipe to next memory
- **WHEN** the detail overlay is open and the user swipes to an adjacent memory
- **THEN** the overlay shows that adjacent memory’s content

#### Scenario: Dismiss detail
- **WHEN** the detail overlay is open and the user taps Close or the scrim
- **THEN** the overlay closes

### Requirement: Edit and delete memory
The user SHALL be able to edit or delete any memory from the Instagram-style feed (⋯ menu) and from the gallery (context menu). Edit SHALL open the Add modal in edit mode, prefilled with the memory’s fields, titled “Edit memory”, with CTA “Save changes”. The same Title/Description validation and inline alerts as Add SHALL apply. Photo MAY be kept, replaced, or removed. Save SHALL update the existing memory in place (no duplicate). Delete SHALL show a confirmation dialog; on confirm the memory is removed from the session list. If the deleted memory was selected in the feed, selection SHALL advance to an adjacent memory or close the feed when none remain.

#### Scenario: Edit from feed
- **WHEN** the user chooses Edit from a feed post menu
- **THEN** the edit modal opens prefilled and saving updates that memory without creating a new one

#### Scenario: Delete confirmed
- **WHEN** the user confirms Delete for a memory
- **THEN** that memory is removed from carousel, gallery, and feed

#### Scenario: Delete cancelled
- **WHEN** the delete confirmation is cancelled
- **THEN** the memory remains unchanged
