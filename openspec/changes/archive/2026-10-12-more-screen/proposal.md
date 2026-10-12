# Proposal

## Why

Me, Partner, Us, and Connection are real screens, but More is still a named placeholder. Couples need a home for profile, pairing, Premium, preferences, support, and sign-out — matching Figma Make `MoreScreen` — especially now that auth/pairing live behind Supabase.

## What Changes

- Replace the More tab placeholder with a More screen matching `design-reference` `MoreScreen.tsx`: header, profile card, Pair / Subscription / Preferences / Support / Account sections, version footer.
- Wire session state (`displayName`, partner name, `isPaired`, `isPremium`) from `MeSessionStore` (+ `AppSessionStore` for auth logout).
- Pair row opens the existing pairing flow; Premium uses the demo Premium unlock pattern already used in Partner Quiz; Log out signs out when Supabase auth is active (demo mode may no-op or return to demo shell).
- Secondary destinations (edit profile, avatar, notifications, privacy, help, terms) MAY open lightweight sheets or stubs in this slice — no real billing, account deletion, or legal CMS.

## Non-goals

- StoreKit / real subscription billing
- Avatar upload to Supabase Storage
- Full privacy export / delete-account flows
- In-app FAQ content CMS
- Changing Me / Partner / Us / Connection feature surfaces beyond shell wiring

## Capabilities

### New Capabilities
- `more-screen`: Profile, pair, subscription teaser, preferences/support rows, and account logout on the More tab.

### Modified Capabilities
- `ios-app-shell`: More is no longer a named-only placeholder; it shows More screen content.

## Impact

- `beside/beside/Features/More/` (replace `MoreView` placeholder; optional subviews/sheets)
- `RootTabView` (pass `meStore` / `session` into More)
- `MeSessionStore` / `AppSessionStore` (read profile/pair/premium; logout)
- Reuse `PartnerPairingModal` patterns where possible
- `besideUITests` shell expectations for More
- OpenSpec: new `more-screen` main spec after archive; `ios-app-shell` delta
- Coexists with in-flight `add-supabase-backend` (logout/auth wiring should follow that change’s session APIs)
