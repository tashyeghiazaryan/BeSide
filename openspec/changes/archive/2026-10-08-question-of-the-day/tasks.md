# Tasks

## 1. Session model + carousel seed

- [x] 1.1 Add QotD session fields and submit APIs on `MeSessionStore` (prompt, me/partner answers, `bothQuestionAnswersReady`, submit + demo partner submit / delayed auto-partner) and verify store methods set answers and reveal readiness in a quick preview or unit-style check
- [x] 1.2 Seed a `question-of-the-day` slide in `ConnectionCarousel.demoSlides()` (after Today's Activity) with `isQuestionOfTheDay` helper and verify the slide appears in carousel/Sections data

## 2. Question of the day hub UI

- [x] 2.1 Build `QuestionOfTheDayHub` (soft canvas, Back, branding, question card, composer → waiting → dialogue bubbles) and verify accessibility identifiers for hub, composer, send, waiting, dialogue, back
- [x] 2.2 Apply floating-tab-bar hide preference while the hub is open and verify tab bar stays hidden until Back

## 3. Connection wiring

- [x] 3.1 Wire `ConnectionView` Start / Sections / overlay state so QotD opens its hub, Today's Activity still opens activity hub, quiz/Premium stay no-op, and auto-advance pauses for either hub; verify Start on QotD opens hub and partner-quiz Start does not
- [x] 3.2 Update Sections UITest expectations for the new slide row id and verify Open on QotD reaches the hub

## 4. Tests + build

- [x] 4.1 Add UITest: carousel/sections → QotD → submit answer → wait for dialogue reveal → Back to carousel; verify identifiers and both bubbles
- [x] 4.2 Run `xcodebuild` UI tests (or at least Connection-related tests) and verify they pass
