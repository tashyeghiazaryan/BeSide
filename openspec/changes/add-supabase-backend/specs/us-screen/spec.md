# us-screen Spec Delta

## MODIFIED Requirements

### Requirement: Daily progress chips
The Us home SHALL show daily progress chips that reflect whether each partner completed the day’s Me/Partner/Connection rituals. In Supabase mode, chip state SHALL be derived from persisted couple activity for the current local day (mood shares, partner checks, connection activity), not from hard-coded session seeds alone. In demo mode, chips MAY continue to use session flags/seeds.

#### Scenario: Chip updates after mood share (Supabase)
- **WHEN** the user shares a mood today while paired online
- **THEN** the corresponding daily progress chip on Us reflects completion after sync

### Requirement: Long-term level and streak
The Us home SHALL show the couple’s long-term level and streak. In Supabase mode, level/points/streak SHALL load from couple progress persisted for the couple and update when rewarded actions (for example partner quiz claim) succeed on the server. In demo mode, values MAY remain session-local.

#### Scenario: Progress loads for couple (Supabase)
- **WHEN** a paired user opens Us after points were granted on another device
- **THEN** the level/points display matches the persisted couple progress after sync

### Requirement: Important Dates list modal
When the Important Dates list is open, the Us tab SHALL show a centered frosted-glass modal over a dimmed/blurred scrim titled “Important dates” with subtitle “All your moments together”. The modal SHALL list all couple important dates sorted by soonest upcoming occurrence, each row showing title, short date, and a countdown-style badge. An empty list MUST show guidance to add a date via +. The user SHALL dismiss the modal by tapping Close or the scrim. In Supabase mode, the list SHALL load from persisted couple dates and survive relaunch.

#### Scenario: List shows persisted dates (Supabase)
- **WHEN** the couple previously added dates and the user reopens the list after relaunch
- **THEN** those dates still appear sorted by soonest upcoming occurrence

### Requirement: Add Important Date calendar modal
Tapping + on the Important Dates tile SHALL open an “Add a date” frosted-glass calendar modal (closing the list if it was open). The modal SHALL offer month prev/next, a month grid (Monday-start), selecting a day, a title field, and an Add control that expands inline fields on first use and commits on a second tap when title and date are set. After a successful add, the new date SHALL appear in the list and the home tile nearest-date preview SHALL update. Empty title or missing date MUST NOT add. Dismiss via Close or scrim without requiring save. In Supabase mode, add MUST persist for the couple; in demo mode, storage for this session is sufficient.

#### Scenario: Add date persists (Supabase)
- **WHEN** the user successfully adds a titled date while online in Supabase mode
- **THEN** the date is stored for the couple and appears in the list and on the home tile when it is the nearest upcoming date
