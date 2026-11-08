# couple-backend Specification

## Purpose

Server-side persistence and RLS for couple-scoped BeSide data on Supabase, including the couple stories table used by Us.

## Requirements

### Requirement: Couple stories table with RLS
Postgres SHALL provide a `couple_stories` table keyed by `couple_id`, with `author_user_id`, `image_path`, and `created_at`. Row-level security SHALL allow only members of that couple to read/write rows, and inserts MUST set `author_user_id` to the authenticated user. Until the live Swift gateway wires this table, the iOS session store MAY hold stories in memory; the schema MUST still exist so live mode can attach without a second migration shape. DEBUG / session demo partner timers MAY remain for unpaired demo; they MUST NOT be the primary delivery path once the live gateway reads this table.

#### Scenario: Member can insert own story row
- **WHEN** an authenticated couple member inserts a story with their user id as author
- **THEN** the row is stored for that couple

#### Scenario: Non-member denied
- **WHEN** a user who is not a member of the couple queries that couple’s stories
- **THEN** no rows are returned (or the operation is denied)
