# connection-screen Spec Delta

## MODIFIED Requirements

### Requirement: Today's Activity hub — Daily Task
The Today's Activity hub SHALL be a full-screen soft canvas with Back, beside branding, and a Daily Task card. The Daily Task SHALL progress through closed → open → waiting: closed shows a hint and “Open your daily task”; open shows You/Partner task text and “Mark as done”; waiting shows a waiting-for-partner message. Marking done SHALL set the user's daily activity completion for today (so Us daily progress can reflect it). In Supabase mode, open/mark-done MUST persist for the couple’s daily round so the partner’s device can observe progress after sync. In demo mode, completion MAY remain session-local. Back SHALL dismiss the hub and return to the carousel.

#### Scenario: Mark done persists (Supabase)
- **WHEN** the user marks the daily task done while online
- **THEN** the card shows the waiting-for-partner state and the couple’s daily progress records the user’s completion for today

### Requirement: Today's Activity hub — awaiting approval
Below Daily Task, the hub SHALL show an “Awaiting your approval” section with partner answer cards (name, time label, preview text) and an Approve control. Approving SHALL remove that answer from the pending list. When none remain, the section SHALL show empty guidance. In Supabase mode, pending cards SHALL come from the partner’s persisted submissions for the couple (not only session seeds), and Approve MUST persist so the partner’s waiting state can resolve after sync. In demo mode, seeded session cards remain allowed.

#### Scenario: Approve partner submission (Supabase)
- **WHEN** the partner submitted an answer and the user approves it while online
- **THEN** the card leaves the pending list for both members after sync
