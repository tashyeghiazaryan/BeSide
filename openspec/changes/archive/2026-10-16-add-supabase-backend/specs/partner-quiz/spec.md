# partner-quiz Spec Delta

## MODIFIED Requirements

### Requirement: Partner Quiz hub
The Connection tab SHALL present a Partner Quiz hub as a full-screen soft canvas with Back and beside branding. The hub SHALL run a multiple-choice quiz in which one partner’s truth answers are locked and the other guesses. Each question SHALL offer three or four selectable options. The partner’s truth choice for each question MUST NOT be shown to the guesser before they submit a guess for that question (or before results, if guesses are collected then revealed together). Back SHALL dismiss the hub and return to the Connection carousel. In Supabase mode, round questions and truths SHALL come from the couple’s daily quiz round on the server (with RLS/RPC hiding truths from the guesser). In demo mode, seeded session questions remain allowed.

#### Scenario: Truths hidden while guessing (Supabase)
- **WHEN** the guesser is answering a question before results
- **THEN** the partner’s truth option is not revealed in the UI

### Requirement: Session demo partner truths
For demo backend mode only, partner truth answers SHALL be available without a network round-trip (seeded in the session) so the quiz and results can be completed on one device. In Supabase mode, this requirement MUST NOT apply; truths MUST originate from the answerer’s persisted choices (or an assigned server round) and remain hidden from the guesser until results rules allow.

#### Scenario: Demo quiz completes offline
- **WHEN** backend mode is demo and the user completes the quiz in a fresh session
- **THEN** results can be shown using seeded partner truths without a network round-trip
