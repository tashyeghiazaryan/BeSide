# Design

## Context

Connection already overlays hubs from carousel Start / Sections (`TodaysActivityHub`, `QuestionOfTheDayHub`). Partner Quiz reuses that shell on the existing `partner-quiz` slide. See proposal.md for motivation; specs define guess-then-reveal scoring.

## Goals / Non-Goals

**Goals:**
- Open Partner Quiz hub from carousel Start and Sections.
- Seed ~4 multiple-choice questions with partner truth option ids; user guesses one option per question.
- Advance question-by-question; after the last guess, show results (score + per-question truth vs guess).
- Session state on `MeSessionStore`; hide tab bar while hub is open.

**Non-Goals:**
- Real-time two-device sync or turn-taking UI for the answerer.
- Free-text answers, difficulty tiers, Premium gating, leaderboards.
- Editing guesses after results, or multi-round quiz catalog.

## Decisions

1. **Guesser-first session demo**  
   Current user always plays as the guesser. Partner truths are seeded (Alex’s answers). Avoids a second device and matches “how well do *you* know your partner?”  
   *Alternative:* user answers first as themselves — rejected for v1 (extra step; truths still need partner data).

2. **Per-question advance, reveal at end**  
   Select option → Continue/Next (or auto-advance after select + Confirm). No correctness shown until the results screen so the run feels like a quiz, not flashcards.  
   *Alternative:* instant feedback per question — deferred; results pack the payoff.

3. **Data model**  
   `PartnerQuizQuestion { id, prompt, options: [PartnerQuizOption], partnerTruthOptionID }`  
   Session: `partnerQuizQuestions` (seed), `partnerQuizGuesses: [questionID: optionID]`, `partnerQuizPhase: playing | results`, `partnerQuizIndex`.  
   APIs: `selectPartnerQuizGuess`, `advancePartnerQuiz`, `partnerQuizScore`, `resetPartnerQuiz` (optional on reopen if complete — prefer keep results until reset; reopen can show results if finished).

4. **UI**  
   Soft canvas hub like QotD: header Back + beside; question card; stacked choice chips; primary Continue. Results: large score, then list rows (question, your guess, their answer, check/x). Hide floating tab bar via `hidesFloatingTabBar()`.

5. **Carousel wiring**  
   `isPartnerQuiz` on slide id `partner-quiz`. `handleStart` / `openSection` open `PartnerQuizHub`. Premium remains no-op. Auto-advance pauses while hub open.

## Risks / Trade-offs

- [Seeded truths feel one-sided] → Copy: “Guess how Alex answered”; real answerer turn later.
- [Short quiz] → Four questions is enough for a session demo without fatigue.

## Migration Plan

Session-only seed. No persistence. Rollback = remove hub wiring; slide stays teaser.

## Open Questions

None blocking; question copy can be playful English seeds in code.
