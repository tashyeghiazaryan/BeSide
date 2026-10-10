# couple-backend Spec Delta

## ADDED Requirements

### Requirement: Authenticated session with restore
When backend mode is Supabase, the app SHALL require an authenticated Supabase user before showing the five-tab shell. On cold launch with a valid stored session, the app SHALL restore that session without asking for OTP again. On cold launch with no session, the app SHALL present sign-in (email OTP) and MUST NOT show Me/Partner/Us/Connection feature content until authenticated.

#### Scenario: Restore signed-in session
- **WHEN** the user launches the app with a valid Supabase session
- **THEN** the five-tab shell appears without a new OTP challenge

#### Scenario: Signed-out launch
- **WHEN** the user launches the app with no Supabase session
- **THEN** sign-in is shown and the tab shell is not shown

### Requirement: Couple membership and invite codes
An authenticated user SHALL belong to at most one active couple for v1. The app SHALL let an unpaired user create a couple (generating a server-issued invite code) or join a couple by submitting a valid code. Completing create or join MUST persist membership server-side. Invalid, expired, or already-used codes MUST NOT unlock the paired Partner UI. Local-only unlock without server confirmation MUST NOT be used in Supabase mode.

#### Scenario: Create couple issues code
- **WHEN** an unpaired authenticated user creates a couple
- **THEN** the server stores membership and returns an invite code the user can share

#### Scenario: Join with valid code
- **WHEN** an unpaired authenticated user submits a valid open invite code
- **THEN** they become the second member of that couple and the paired Partner UI unlocks

#### Scenario: Reject invalid code
- **WHEN** the user submits an unknown or closed invite code
- **THEN** pairing fails with an error and the user remains unpaired

### Requirement: Couple-scoped persistence with RLS
Couple feature data (mood shares, reactions, important dates, wishlist items, love notes, shared memories, daily activity, QOTD answers, partner quiz rounds, and couple progress) SHALL be stored in Postgres with row-level security so that only members of the same `couple_id` can read or write that couple’s rows. The client MUST send authenticated requests; anonymous access to couple tables MUST be denied.

#### Scenario: Partner can read mood share
- **WHEN** user A in a couple shares a mood
- **THEN** user B in the same couple can read that mood share after sync

#### Scenario: Outside couple denied
- **WHEN** a user who is not a member of couple C requests couple C’s rows
- **THEN** the query returns no rows (or is denied) and no couple C content is shown

### Requirement: Media storage for photos
Wishlist and shared-memory photos SHALL upload to Supabase Storage. Database rows SHALL reference storage paths or signed/public URLs — not large base64 payloads in text columns. Deleting a memory or wishlist item SHOULD remove or orphan-clean the associated object according to the storage policy.

#### Scenario: Memory photo upload
- **WHEN** the user adds a shared memory with a photo
- **THEN** the photo is stored in Storage and the memory row references that object

### Requirement: Sync and realtime for partner-visible updates
When both partners are authenticated and paired, partner-visible writes (mood shares, reactions, love notes, QOTD answers, daily submissions/approvals, quiz round progress) SHALL become available on the other device via Realtime subscription and/or refresh-on-appear. Session-only demo partner timers MUST NOT be the primary delivery mechanism in Supabase mode.

#### Scenario: Reaction appears on Me
- **WHEN** the partner sends a reaction to the user’s latest mood share
- **THEN** the user’s Me current-mood / history surface shows that reaction after sync without requiring app reinstall

### Requirement: Field validation on write
Server-bound writes SHALL enforce the product field rules: custom wish max 80; partner reaction note max 60; love note body max 100; shared memory title max 40 and description max 120; allowed character sets as defined by the relevant feature specs / `Требования полей.md`. Invalid payloads MUST be rejected (client and/or RPC) and MUST NOT create partial rows.

#### Scenario: Oversized wish rejected
- **WHEN** the user attempts to share a custom wish longer than 80 characters
- **THEN** the share does not persist and the user sees a validation error

### Requirement: Offline and degraded behavior
When the device is offline or Supabase is unreachable, the app SHALL fail writes that require the server with a clear error (or a documented retry queue if implemented) and MUST NOT claim success for partner-visible actions that did not persist. Read surfaces MAY show the last successfully synced cache when available.

#### Scenario: Share while offline
- **WHEN** the user activates mood share with no network in Supabase mode
- **THEN** the app does not show a false success that implies the partner received the mood

### Requirement: Demo backend mode
The client MAY provide a `demo` backend mode that keeps session-only behavior for local QA and UITests. Demo mode MUST NOT be required for production builds that target a live Supabase project. Specs that refer to session demo partner answers/truths apply only in demo mode unless a feature still lacks a backend implementation.

#### Scenario: Demo mode local share
- **WHEN** backend mode is demo and the user shares a mood
- **THEN** behavior matches the pre-Supabase session store (local success without network)
