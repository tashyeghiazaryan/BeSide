# Design

## Context

See proposal.md — Why. `MoreView` is still `TabPlaceholder`. Design truth: `design-reference/src/app/components/MoreScreen.tsx`. Session identity lives on `MeSessionStore` (`displayName`, `partnerDisplayName`, `isPaired`, `isPremium`); auth lifecycle on `AppSessionStore` (`signOut`, phases). Pairing UI already exists via `PartnerPairingModal` on Partner. In-flight `add-supabase-backend` owns auth gate changes — More logout must call `AppSessionStore.signOut()` when live.

## Goals / Non-Goals

**Goals**
- Ship a readable More home matching the reference layout and tokens.
- Wire Pair / Premium / Log out to existing session APIs.
- Stub secondary destinations without blocking the shell.

**Non-Goals (design-level)**
- New backend tables for settings preferences
- Real StoreKit products
- Redesigning Partner pairing itself

## Decisions

1. **Pass `meStore` + optional `session` into `MoreView` from `RootTabView`**  
   Same pattern as `PartnerView`. Alternatives: environment objects — rejected to stay consistent with explicit injection.

2. **Reuse `PartnerPairingModal` for Pair connect/manage**  
   Present as sheet from More rather than duplicating invite/join UI. Alternatives: navigate to Partner tab — worse UX from More.

3. **Demo Premium via existing `unlockDemoPremium()`**  
   Matches Partner Quiz. Alternatives: fake “Active” only in UI — rejected so Connection Premium state stays coherent.

4. **Secondary rows → shared lightweight stub sheet**  
   Title + short body + Done. Alternatives: empty NavigationLinks per row — more files for no product value in this slice.

5. **Edit profile / avatar**  
   Edit profile: simple sheet to edit `displayName` in session (local). Avatar camera button: no-op or photo picker stub without upload. Alternatives: full Storage upload — deferred to backend follow-up.

6. **Log out**  
   If `session?.phase == .authenticated` (or live configured), `await session.signOut()`. Demo mode: keep shell (no-op) or optional confirm — prefer no-op with toast/copy “Demo mode” if needed. Alternatives: always force auth gate — breaks demo QA.

7. **Visual system**  
   Soft canvas / white cards / navy accents / SF Symbols standing in for Lucide (`sparkles`, `link`, `person.2`, `crown`, `bell`, `lock.shield`, `questionmark.circle`, `doc.text`, `rectangle.portrait.and.arrow.right`). Prefer design-system tokens over one-off hex where they exist; extract repeated row chrome into `Features/More` helpers (promote to DesignSystem only if reused outside More).

## Risks / Trade-offs

- [Parallel OpenSpec change] `add-supabase-backend` also touches `ios-app-shell` → Merge shell deltas carefully at archive; More behavior is additive.  
- [Logout vs demo] Accidental sign-out in mixed builds → Gate logout on authenticated phase only.  
- [Stub fatigue] Empty sheets feel unfinished → Keep stub copy honest (“Coming soon”) and short.

## Migration / Rollback

- No schema migration. Rollback = restore `MoreView` placeholder + revert shell spec wording.  
- Session Premium / displayName edits remain in-memory as today.

## Open Questions

- None blocking apply; avatar upload can ship in a later change.
