# Design

## Context

Implementation already landed in the Us feature and a Supabase migration. This change is a retroactive OpenSpec capture so main specs match the product.

## Decisions

- **Session-first stories**: `MeSessionStore.coupleStories` holds JPEG frames for demo/session; migration `20261102120000_couple_stories.sql` defines the live shape (`image_path`, not blob columns).
- **Nudge over chips**: One navy capsule above the tab bar replaces three tip chips; destinations reuse existing tabs via `onSelectTab`.
- **2×2 tiles**: `UsLayout` / `BeSideMetrics.UsLayout.resolve` tunes inset, tile aspect, and type for 16 / 16 Pro / Max; page inset for Us is 34pt (independent of Me/tab-bar experiments).
- **Stories chrome**: Strip uses negative horizontal padding to avoid clipping rings; archive mirrors Screen photo archive patterns; viewer is full-screen overlay.
- **Out of scope**: Floating tab bar width matching Me cards; Partner/More inset lock to Us.

## Risks / follow-ups

- Live gateway for `couple_stories` + Storage upload path not wired yet.
- Seen-state is local (`seenByMe`); partner-sync of seen rings needs a later slice.
