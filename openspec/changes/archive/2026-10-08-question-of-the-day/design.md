# Design

## Context

Connection already has a carousel + overlay hub pattern (`TodaysActivityHub` over `ConnectionView`, Sections index, `MeSessionStore` session flags). Question of the day reuses that shell: new slide + new hub, separate from daily-task submit/approve. See proposal.md for motivation; specs define reveal-when-both-answered behavior.

## Goals / Non-Goals

**Goals:**
- Seed a fourth carousel slide and wire Start / Sections → QotD hub.
- Session model: one question, optional me/partner free-text answers; UI branches composer → waiting → dialogue.
- Dialogue presentation (chat-style bubbles) once both answers exist.
- Hide floating tab bar while the QotD hub is open (same preference as other Connection overlays).

**Non-Goals:**
- Network sync, push, or multi-day question catalog.
- Multiple choice, scoring, or partner-quiz engine.
- Editing answers after submit, or linking QotD to Us daily-progress chips.
- Premium gating.

## Decisions

1. **Separate hub, not inside Today's Activity**  
   QotD is its own carousel entry and overlay (`QuestionOfTheDayHub`), parallel to `TodaysActivityHub`. Keeps daily-task approval UX uncluttered and matches “another screen in the carousel.”  
   *Alternative considered:* nest under Today's Activity — rejected; user asked for a carousel screen.

2. **Session state on `MeSessionStore`**  
   Add `questionOfTheDayPrompt`, `meQuestionAnswer`, `partnerQuestionAnswer` (optional strings). Computed `bothQuestionAnswersReady`. Submit APIs: `submitQuestionOfTheDayAnswer(_:)`, demo `partnerSubmitQuestionOfTheDayAnswer(...)` / short delayed auto-partner after me submit (same demo spirit as daily pending).  
   *Alternative considered:* local `@State` only in the hub — rejected; Sections reopen and tests need durable session state.

3. **Reveal rule**  
   Show partner text only when both strings are non-nil/non-empty. Own answer may appear in waiting state as “sent” confirmation without partner bubble, or only as waiting copy — prefer waiting copy + subtle “You answered” chip so the dialogue moment lands when both are ready.

4. **Dialogue UI**  
   Soft canvas + question card on top; after reveal, vertical stack of bubbles (You trailing / Partner leading) using existing navy/ink + light fills. No new DesignSystem primitive unless a bubble style is clearly reusable twice in this change.

5. **Carousel wiring**  
   Extend `ConnectionCarouselSlide` with `isQuestionOfTheDay` (id `question-of-the-day`). Insert slide after Today's Activity. `handleStart` / `openSection` branch: activity → activity hub; QotD → QotD hub; else no-op. Pause auto-advance while either hub or Sections is open.

6. **Demo partner timing**  
   After me submit, schedule partner answer (~2–3s) with a seeded thoughtful reply so UITests can wait for dialogue without a second device. Expose a deterministic store method tests can also call if timing is flaky.

## Risks / Trade-offs

- [Four carousel slides compress Sections cards] → Sections already sizes by count; accept slightly shorter cards or keep min height.
- [Auto partner feels fake] → Session demo only; copy can say the partner answered; real sync later.
- [Empty submit] → Disable Send until trimmed text non-empty.

## Migration Plan

Ship with seeded slide + session-only state. No persistence migration. Rollback = remove slide/hub and store fields.

## Open Questions

None that block implementation; question copy can be a single English seed string in the store/carousel constants.
