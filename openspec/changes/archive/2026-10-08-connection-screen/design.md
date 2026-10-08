# Design

## Context

Connection is the last major tab still on `TabPlaceholder` (More remains). Figma Make `ConnectionScreen.tsx` is carousel-first: full-bleed media, three seeded slides, and a separate Today's Activity hub (Daily Task phases + pending partner answers). Us already tracks `meActivityDoneToday` / `partnerActivityDoneToday` for the daily “prompt” chip — Connection should set the me flag when the user marks the daily task done.

## Goals / Non-Goals

**Goals:**
- Ship Connection carousel + Today's Activity hub visually aligned with the reference.
- Session-only demo data (slides, tasks, pending answers).
- Wire Mark as done → `meActivityDoneToday` on `MeSessionStore`.

**Non-Goals:**
- Partner quiz engine, Premium paywall, real voice notes, cloud sync.
- Favorites / reaction-picker remnants (deprecated in the reference).
- Changing Us layout beyond reading the existing activity flags.
- More tab implementation.

## Decisions

### 1. Pass `MeSessionStore` into Connection
**Choice:** `RootTabView` passes the shared store into `ConnectionView` like Me/Partner/Us.
**Rationale:** Activity completion and partner name already live there.
**Alternative:** Local `@State` only — rejected; breaks Us daily chip sync.

### 2. Files under `Features/Connection/`
| File | Role |
|------|------|
| `ConnectionCarouselSlide.swift` | Slide model + default seed |
| `ConnectionPendingAnswer.swift` | Pending approval model + seed |
| `TodaysActivityHub.swift` | Full-screen hub |
| `ConnectionView.swift` | Carousel home + presentation |

Reuse `BeSideColor.navy*` / soft pink CTA patterns from Us/Love Notes; extract only if a second identical CTA appears.

### 3. Media
**Choice:** Remote Unsplash URLs via `AsyncImage` (or existing photo helper if suitable) with gradient overlay; solid fallback if load fails.
**Rationale:** Matches reference seed URLs; no asset catalog required for v1.

### 4. Non-activity Start
**Choice:** No-op (button remains tappable, no navigation).
**Rationale:** Spec allows it; avoids fake quiz/paywall UI.

### 5. Auto-advance
**Choice:** ~8s timer while hub is closed and slide count > 1; pause while hub open or user is interacting (reset on swipe/dot).
**Rationale:** Matches reference `carouselAutoMs = 8000`.

## Risks / Trade-offs

- Full-bleed under tab bar may clip CTA — keep center CTA above `BeSideMetrics.tabBarClearance`.
- Async remote images need graceful empty state (no crash, soft placeholder).

## Migration

None — replace placeholder view in place.
