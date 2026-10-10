# me-screen Spec Delta

## MODIFIED Requirements

### Requirement: Share reaches the partner when backend is live
When a mood and a wish are both selected, the Me tab SHALL offer a control to share with the partner. In Supabase mode, activating share MUST persist the mood share for the couple and make it available to the partner after sync; success confirmation MUST only follow a successful persist (or an explicit offline retry policy that does not claim partner delivery). After share completes, the app SHALL briefly confirm success, then clear the in-progress mood and wish selection while keeping the shared entry as the current mood and in the week history. In demo mode, share MAY succeed locally without network (legacy session behavior).

#### Scenario: Share persists in Supabase mode
- **WHEN** the user has selected a mood and a wish and activates share while online in Supabase mode
- **THEN** the share is stored for the couple, a success confirmation appears, and the partner can read that mood after sync

#### Scenario: Selection clears after share
- **WHEN** the share confirmation finishes
- **THEN** no mood or wish remains selected for a new share, and the shared mood appears in the current-mood panel

#### Scenario: Demo mode local share
- **WHEN** backend mode is demo and the user shares with no network
- **THEN** the share succeeds locally and a success confirmation appears

### Requirement: Week history shows the last seven days
The Me tab SHALL show a “My mood this week” strip for the last seven days ending today. Days without entries MUST be visually empty. Days with entries MUST show the latest mood for that day. In Supabase mode, entries SHALL come from persisted mood shares for the current user and MUST survive app relaunch. In demo mode, the strip MAY start with mock seed entries. Tapping a day that has entries SHALL expand or collapse a short list of that day’s moods and times. Partner reactions on a share SHALL appear when synced (not only from seeds).

#### Scenario: Week strip visible
- **WHEN** the user opens the Me tab
- **THEN** a week history section labeled for this week’s moods is visible with seven day slots

#### Scenario: History survives relaunch (Supabase)
- **WHEN** the user shared a mood earlier, killed the app, and relaunches while signed in
- **THEN** that mood still appears in the current-mood panel or week history as appropriate

#### Scenario: Expand a day with entries
- **WHEN** the user taps a day that has at least one mood entry
- **THEN** that day’s mood entries and times are shown
