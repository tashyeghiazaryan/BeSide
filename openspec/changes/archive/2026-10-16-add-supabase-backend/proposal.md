# Proposal

## Why

The app is a polished SwiftUI prototype: every couple feature runs through an in-memory `MeSessionStore` with seeded partner data and timed demo replies. Two real devices cannot share moods, reactions, notes, memories, or Connection rituals, and relaunch wipes state. Shipping BeSide as a couple product requires a real backend with auth, couple pairing, persistence, media, and sync — without rewriting the UI contracts already locked in OpenSpec.

## What Changes

- Introduce **Supabase** as the couple backend: Auth (email OTP), Postgres + RLS, Storage (wishlist/memory photos), Realtime (or pull) for partner-visible updates.
- Add a new OpenSpec capability **`couple-backend`** for auth, pairing, schema, sync, validation, and offline/degraded rules.
- **Modify** feature specs that currently require “no server / session-only / demo partner” so share, reactions, Us content, and Connection flows persist and sync when paired.
- Prepare the iOS project: repository protocols, Supabase config placeholder, SQL migrations under `supabase/`, and a clear cutover path from session demo → live couple data.
- Keep existing screen UX (Me / Partner / Us / Connection) unless a spec delta says otherwise; demo partner simulators become DEBUG-only or removed per phase.

## Non-goals (this change)

- StoreKit / real Premium billing (keep `isPremium` flag behavior until a later slice).
- APNs / system push (in-app notification inbox may sync; push later).
- Offline-first CRDT or full local DB; optimistic UI + clear errors are enough for v1.
- Porting the full Figma `AuthScreen` polish beyond a working OTP + restore flow.
- Splitting every feature into separate OpenSpec changes (tasks are phased inside this change).

## Capabilities

### New Capabilities
- `couple-backend`: Authenticated users, couple membership / invite codes, Postgres schema + RLS, Storage paths, sync contracts, field validation on write, offline/degraded behavior.

### Modified Capabilities
- `ios-app-shell`: Allow auth session restore / signed-out gate before the five-tab shell when backend mode is enabled.
- `me-screen`: Mood+wish share persists and reaches the partner; week history survives relaunch.
- `partner-screen`: Partner mood from partner device; reactions sync to Me; pairing via server-validated codes.
- `us-screen`: Important dates and daily/level inputs backed by couple data (not session seeds alone).
- `shared-memories`: Durable memories + Storage for photos.
- `love-notes`: Delivery and read receipts across devices.
- `connection-screen`: Daily task submissions / approvals from partner device.
- `question-of-the-day`: Both answers from backend; drop session-only demo partner answer as the primary path.
- `partner-quiz`: Partner truths from backend round; drop session-only seeded truths as the primary path.

## Impact

- New: `supabase/migrations/`, `beside/beside/Backend/`, OpenSpec `couple-backend` + deltas above.
- Refactor path: thin feature stores or repositories behind `MeSessionStore` (or replace it incrementally).
- Secrets: Supabase URL + anon key via local plist/xcconfig (not committed).
- Tests: unit tests for mappers/validation; later integration against a staging project.
- QA doc `Требования полей.md` “no server” notes become stale once phases land — update when archiving.
