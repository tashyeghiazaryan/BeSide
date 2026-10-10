# Tasks

## 1. Quiz model + session state

- [x] 1.1 Add seeded `PartnerQuizQuestion` / option models and session fields on `MeSessionStore` (questions, index, guesses, phase, score helpers, select/advance/reset) and verify a full guess run reaches results with a correct score in a quick store check
- [x] 1.2 Add `isPartnerQuiz` / `partnerQuizID` on `ConnectionCarousel` and verify the existing partner-quiz slide matches

## 2. Partner Quiz hub UI

- [x] 2.1 Build `PartnerQuizHub` (soft canvas, Back, branding, question + MC options + Continue, results score + per-question reveal) with accessibility identifiers and verify playing → results flow in Preview/UI
- [x] 2.2 Apply `hidesFloatingTabBar()` on the hub and verify the tab bar stays hidden until Back

## 3. Connection wiring

- [x] 3.1 Wire `ConnectionView` Start / Sections / overlay so partner-quiz opens the hub, QotD and Today's Activity unchanged, Premium stays no-op, auto-advance pauses; verify Start on partner-quiz opens hub
- [x] 3.2 Extend UITests: Sections/carousel → Partner Quiz → answer all → results → Back; verify score identifiers and Premium Start still does not open hubs

## 4. Build

- [x] 4.1 Run Connection-related UITests (including new Partner Quiz) via `xcodebuild` and verify they pass
