# Tasks

## 0. Prep (repo + OpenSpec)

- [x] OpenSpec change `add-supabase-backend` (proposal, design, deltas, tasks)
- [x] Update `openspec/config.yaml` project context
- [x] Add `supabase/migrations/` initial schema + RLS sketch
- [x] Add iOS `Backend/` scaffolding (config, couple context, repository protocols, demo adapters)
- [ ] Create staging Supabase project; fill local `SupabaseSecrets.plist` (gitignored)
- [x] Add Supabase Swift package to `beside` target and resolve dependencies

## 1. Auth + profiles + pairing

- [x] Wire Supabase Auth email OTP + session restore (client + AuthGateView)
- [x] Auth gate before five-tab shell when `BackendMode.supabase`
- [x] `profiles` upsert on first login via `ensure_profile` RPC
- [x] Create couple / generate invite code / join by code (`CoupleService` + RPCs)
- [x] Replace local-only pairing unlock with server membership (live mode)
- [ ] Apply `supabase/apply_all.sql` on project `zrrmalscmamggsqjdbzy`
- [ ] Add local `SupabaseSecrets.plist` with anon key
- [ ] Update UITests for signed-out / signed-in / unpaired paths

## 2. Mood share + reactions (core loop)

- [x] `CoupleBackendGateway` mood share + reaction writes
- [x] Me share writes `mood_shares`; Partner week via poll/snapshot
- [x] Partner reaction writes `mood_reactions`; Me sees via poll (`mood_reactions` join)
- [x] One reaction per share (DB unique + client guard)
- [x] Persist week history across relaunch in live mode (clears seeds on attach)

## 3. Us — dates, wishlist, notes, memories, progress

- [x] Important dates CRUD + couple scope
- [x] Wishlist CRUD + Storage upload
- [x] Love notes send/read + poll sync
- [x] Shared memories CRUD + Storage + signed URLs
- [x] `couple_progress` updates on quiz claim; daily chips from submissions
- [x] Notifications remain client-derived with `dedupeKey` (inbox table later)

## 4. Connection — daily, QOTD, quiz

- [x] Daily rounds/submissions/approvals across devices
- [x] QOTD prompts + answers; demo partner timer gated off in live mode
- [ ] Partner quiz question/truth rows fully server-authored (points claim synced; deck still local seed for v1)
- [x] Gate `scheduleDemo*` timers outside demo / when `liveGateway` set

## 5. Hardening

- [x] Client field validation kept; DB checks on notes/memories lengths
- [x] `syncError` surface on store (wire banner later if needed)
- [ ] Storage cleanup on entity delete
- [ ] Smoke test two-device pairing on staging (needs anon key + SQL apply)
- [ ] Archive OpenSpec change; merge deltas into `openspec/specs/`; refresh `Требования полей.md` server notes
