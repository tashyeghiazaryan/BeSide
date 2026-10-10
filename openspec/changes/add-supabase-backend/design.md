# Design

## Context

Today `RootTabView` owns one `@State MeSessionStore` passed into Me / Partner / Us / Connection. All couple entities are in-memory; pairing is local; partner actions are `Task.sleep` demos. Specs and archived designs explicitly deferred persistence and server pairing. Target stack: **Supabase** (Auth, Postgres, Storage, Realtime) + existing SwiftUI shell.

## Goals / Non-Goals

**Goals:**
- Durable couple-scoped data with RLS so only members of a couple see that couple’s rows.
- Real invite/join pairing (server-validated code).
- Mood share + reaction loop works across two devices.
- Us entities (dates, wishlist, love notes, memories) and Connection (daily, QOTD, quiz) backed by the same couple context.
- iOS client can run in `demo` (current session store) or `supabase` mode during migration.
- Field length/charset rules from `Требования полей.md` / existing specs enforced client-side and ideally mirrored in DB checks or RPCs.

**Non-Goals:** See proposal.md (billing, APNs, CRDT, full Auth UI polish).

## Decisions

1. **Supabase as BaaS**  
   Auth OTP + Postgres + Storage + Realtime covers the couple product without a custom API server for v1.  
   *Alternative:* custom Nest/Firebase — rejected for speed and RLS-first couple isolation.

2. **Couple as first-class row**  
   Tables: `profiles`, `couples`, `couple_members`, `invite_codes`. Almost every feature row carries `couple_id` (+ `user_id` when ownership matters).  
   *Alternative:* only `partner_id` on user — rejected; couple_id simplifies RLS and shared content.

3. **Auth: email OTP**  
   Align with `design-reference` AuthScreen. Session restore on launch when backend mode is on. Signed-out users see auth, not the five-tab shell.  
   *Alternative:* keep shell always (current ios-app-shell) — rejected for real accounts; shell requirement is MODIFIED.

4. **Incremental cutover via repositories**  
   Protocols (`MoodShareRepository`, `CoupleService`, …) with `Session*` implementations wrapping today’s store behavior and `Supabase*` implementations. UI keeps talking to stores; stores call repositories.  
   *Alternative:* big-bang rewrite of `MeSessionStore` — higher risk.

5. **Realtime for partner-visible events**  
   Subscribe on `couple_id` for mood_shares, reactions, love_notes, qotd_answers, daily_submissions. Pull-on-appear as fallback.  
   *Alternative:* polling only — worse UX for QOTD/dialogue reveal.

6. **Media via Storage**  
   Buckets `wishlist-photos`, `memory-photos`. Client uploads JPEG; DB stores path/URL. Stop stuffing base64 into `photoURL`.  
   *Alternative:* keep base64 in Postgres — rejected (size/RLS noise).

7. **Partner quiz integrity**  
   Answerer truths stored server-side; RLS (or RPC) hides truths from guesser until results phase. Roles assigned per daily round.  
   *Alternative:* client-trusted truths — rejected (cheating).

8. **Demo mode retained until phase complete**  
   `BackendMode.demo` keeps current QA/UITests green. `BackendMode.supabase` requires project URL/key. Session demo partner timers only in demo (or `#if DEBUG`).

## Schema (v1 outline)

| Table / bucket | Maps from |
|----------------|-----------|
| `profiles` | displayName, avatar |
| `couples`, `couple_members`, `invite_codes` | pairing, relationship_start |
| `couple_progress` | level, points, streak |
| `mood_shares`, `mood_reactions` | SharedMood + partner reaction |
| `important_dates` | UsImportantDate |
| `wishlist_items`, `completed_wishes` | UsWishlistItem / UsCompletedWish |
| `love_notes` | LoveNote |
| `shared_memories` (+ likes) | UsSharedMemory |
| `notifications` | UsNotification (optional inbox) |
| `daily_rounds`, `daily_submissions` | Connection daily task |
| `qotd_prompts`, `qotd_answers` | Question of the day |
| `partner_quiz_rounds`, `partner_quiz_questions`, `partner_quiz_guesses` | Partner quiz |
| Storage buckets | wishlist / memory photos |

Exact SQL lives in `supabase/migrations/`.

## Client architecture

```
besideApp
  └── AppContainer (auth session + BackendMode)
        ├── AuthGate (supabase mode)
        └── RootTabView
              ├── MeMoodStore / PartnerMoodStore / UsStore / ConnectionStore
              └── repositories → SupabaseClient
```

During prep, `MeSessionStore` may remain the facade while repositories are introduced underneath.

## Risks / Trade-offs

- [Shell auth gate breaks “no sign-in” UITests] → Update UITests; keep demo mode for local QA.
- [Monolithic store hard to swap] → Introduce protocols first; migrate feature-by-feature.
- [Realtime cost / complexity] → Start with pull + selective Realtime channels.
- [Invite code collisions] → Server-generated short codes with uniqueness + expiry.
- [Photo privacy] → Private buckets + signed URLs or couple-scoped policies.

## Migration Plan

1. Apply SQL migrations to a staging Supabase project; configure iOS secrets locally.
2. Ship Auth + pairing behind backend mode; features still demo until their phase.
3. Migrate mood loop → Us → Connection; remove demo timers when each phase is green.
4. Archive this OpenSpec change when tasks are done and canonical specs updated.
5. Rollback: flip `BackendMode` to `demo`; migrations are additive (no destructive drops in v1).

## Open Questions

- Exact OTP copy / onboarding screens vs minimal email entry (product).
- Whether Wishlist / Notifications get their own OpenSpec capabilities in this change or a follow-up (recommended: include in `couple-backend` + `us-screen` MODIFIED; optional new specs later).
- Production vs staging project ownership (who creates the Supabase org).
