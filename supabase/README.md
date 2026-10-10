# BeSide Supabase

Project: [`zrrmalscmamggsqjdbzy`](https://supabase.com/dashboard/project/zrrmalscmamggsqjdbzy)

API URL: `https://zrrmalscmamggsqjdbzy.supabase.co`

## One-time setup

1. Open [SQL Editor](https://supabase.com/dashboard/project/zrrmalscmamggsqjdbzy/sql/new) and run **`apply_all.sql`** (paste file **contents**, not the path).
2. Auth → Providers → **Email** enabled.
3. **Auth email for iOS (important):** the app uses a **6-digit code**, not the magic link.
   - [URL Configuration](https://supabase.com/dashboard/project/zrrmalscmamggsqjdbzy/auth/url-configuration): set **Site URL** to `https://zrrmalscmamggsqjdbzy.supabase.co` (not `http://localhost:3000`).
   - [Email Templates](https://supabase.com/dashboard/project/zrrmalscmamggsqjdbzy/auth/templates) → **Confirm signup** and **Magic Link**: put the code in the body, e.g.  
     `Your BeSide code is {{ .Token }}`  
     (users must type this in the app; clicking the link opens localhost and fails).
4. Storage buckets `wishlist-photos` / `memory-photos` (created by migration when applied).
5. Settings → API → **anon public** key → local `beside/beside/Backend/SupabaseSecrets.plist` (gitignored).
6. Open `beside/beside.xcworkspace`, build, run.

## CLI (optional)

```bash
export SUPABASE_ACCESS_TOKEN=sbp_...   # Account → Access Tokens
supabase link --project-ref zrrmalscmamggsqjdbzy
supabase db push
```
