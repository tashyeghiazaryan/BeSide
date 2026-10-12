# Tasks

## 1. More screen shell UI

- [x] 1.1 Replace `MoreView` placeholder with soft-canvas layout (header, profile card, section cards, version footer) matching `MoreScreen.tsx` and verify accessibility id `screen.more` still resolves
- [x] 1.2 Add shared More row / section helpers (icon, label, hint, chevron, danger style) and verify Pair / Subscription / Preferences / Support / Account sections render

## 2. Session wiring

- [x] 2.1 Pass `MeSessionStore` (+ optional `AppSessionStore`) from `RootTabView` into `MoreView`; bind profile name, Free/Premium, paired partner label and verify UI updates when store fields change
- [x] 2.2 Wire Pair row to present existing `PartnerPairingModal` (unpaired connect + paired manage) and verify modal opens/dismisses from More
- [x] 2.3 Wire Try Premium → `unlockDemoPremium()` (or equivalent) and verify Subscription row shows Premium active
- [x] 2.4 Wire Log out → `AppSessionStore.signOut()` when authenticated; demo mode safe no-op; verify authenticated logout leaves the tab shell

## 3. Stubs and polish

- [x] 3.1 Add lightweight stub/sheet destinations for Edit profile (optional local name edit), Notifications, Privacy, Help, Terms; avatar control may stub; verify each opens and dismisses
- [x] 3.2 Update UITests: More shows profile/sections (not blank placeholder); keep tab order; add smoke for Premium unlock and/or pairing entry if stable

## 4. Verify

- [x] 4.1 Build via `beside.xcworkspace` on an iOS simulator and smoke More → Pair / Premium / stub / Back to other tabs
