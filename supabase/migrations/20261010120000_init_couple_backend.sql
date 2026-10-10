-- BeSide couple backend v1
-- Apply to a staging Supabase project. Adjust policies as product rules harden.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- Couples + membership + invite codes
-- ---------------------------------------------------------------------------
create table public.couples (
  id uuid primary key default gen_random_uuid(),
  relationship_start_date date,
  created_at timestamptz not null default now()
);

create table public.couple_members (
  couple_id uuid not null references public.couples (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (couple_id, user_id),
  unique (user_id)
);

create table public.invite_codes (
  code text primary key,
  couple_id uuid not null references public.couples (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete cascade,
  expires_at timestamptz,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.couple_progress (
  couple_id uuid primary key references public.couples (id) on delete cascade,
  level int not null default 1,
  points int not null default 0,
  streak_days int not null default 0,
  updated_at timestamptz not null default now()
);

create or replace function public.is_couple_member(p_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.couple_members m
    where m.couple_id = p_couple_id and m.user_id = auth.uid()
  );
$$;

alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.invite_codes enable row level security;
alter table public.couple_progress enable row level security;

create policy "couples_member_select"
  on public.couples for select to authenticated
  using (public.is_couple_member(id));

create policy "couple_members_select"
  on public.couple_members for select to authenticated
  using (public.is_couple_member(couple_id) or user_id = auth.uid());

create policy "invite_codes_creator_select"
  on public.invite_codes for select to authenticated
  using (created_by = auth.uid() or public.is_couple_member(couple_id));

create policy "couple_progress_member_all"
  on public.couple_progress for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id));

-- ---------------------------------------------------------------------------
-- Moods
-- ---------------------------------------------------------------------------
create table public.mood_shares (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  mood_id text not null,
  wish text not null,
  shared_at timestamptz not null default now()
);

create table public.mood_reactions (
  id uuid primary key default gen_random_uuid(),
  mood_share_id uuid not null references public.mood_shares (id) on delete cascade,
  reactor_user_id uuid not null references public.profiles (id) on delete cascade,
  reaction text not null,
  note text not null default '',
  created_at timestamptz not null default now(),
  unique (mood_share_id, reactor_user_id)
);

alter table public.mood_shares enable row level security;
alter table public.mood_reactions enable row level security;

create policy "mood_shares_member"
  on public.mood_shares for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id) and user_id = auth.uid());

create policy "mood_reactions_member"
  on public.mood_reactions for all to authenticated
  using (
    exists (
      select 1 from public.mood_shares s
      where s.id = mood_share_id and public.is_couple_member(s.couple_id)
    )
  )
  with check (
    reactor_user_id = auth.uid()
    and exists (
      select 1 from public.mood_shares s
      where s.id = mood_share_id and public.is_couple_member(s.couple_id)
    )
  );

-- ---------------------------------------------------------------------------
-- Us entities
-- ---------------------------------------------------------------------------
create table public.important_dates (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  title text not null,
  occurs_on date not null,
  kind text not null default 'custom',
  accent_hex text,
  system_image text,
  icon_preset text,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  owner_user_id uuid not null references public.profiles (id) on delete cascade,
  caption text not null,
  photo_path text,
  created_at timestamptz not null default now()
);

create table public.completed_wishes (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  title text not null,
  completed_at timestamptz not null default now(),
  direction text not null check (direction in ('for_me', 'for_partner'))
);

create table public.love_notes (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) <= 100),
  status text not null default 'sent' check (status in ('sent', 'read')),
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.shared_memories (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(title) <= 40),
  description text not null default '' check (char_length(description) <= 120),
  occurred_at timestamptz not null,
  mood_emoji text not null default '',
  photo_path text,
  likes_count int not null default 0,
  created_at timestamptz not null default now()
);

create table public.shared_memory_likes (
  memory_id uuid not null references public.shared_memories (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (memory_id, user_id)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  title text not null,
  subtitle text,
  related_id uuid,
  dedupe_key text,
  read boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, dedupe_key)
);

alter table public.important_dates enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.completed_wishes enable row level security;
alter table public.love_notes enable row level security;
alter table public.shared_memories enable row level security;
alter table public.shared_memory_likes enable row level security;
alter table public.notifications enable row level security;

create policy "important_dates_member"
  on public.important_dates for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id));

create policy "wishlist_items_member"
  on public.wishlist_items for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id) and owner_user_id = auth.uid());

create policy "completed_wishes_member"
  on public.completed_wishes for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id));

create policy "love_notes_member"
  on public.love_notes for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id) and sender_id = auth.uid());

create policy "shared_memories_member"
  on public.shared_memories for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id) and author_id = auth.uid());

create policy "shared_memory_likes_member"
  on public.shared_memory_likes for all to authenticated
  using (
    exists (
      select 1 from public.shared_memories m
      where m.id = memory_id and public.is_couple_member(m.couple_id)
    )
  )
  with check (user_id = auth.uid());

create policy "notifications_own"
  on public.notifications for all to authenticated
  using (user_id = auth.uid() and public.is_couple_member(couple_id))
  with check (user_id = auth.uid() and public.is_couple_member(couple_id));

-- ---------------------------------------------------------------------------
-- Connection: daily / QOTD / quiz
-- ---------------------------------------------------------------------------
create table public.daily_rounds (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  round_date date not null,
  me_task text not null default '',
  partner_task text not null default '',
  unique (couple_id, round_date)
);

create table public.daily_submissions (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.daily_rounds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null default '',
  status text not null default 'submitted' check (status in ('submitted', 'approved', 'declined')),
  submitted_at timestamptz not null default now(),
  unique (round_id, user_id)
);

create table public.qotd_prompts (
  prompt_date date primary key,
  prompt text not null
);

create table public.qotd_answers (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  prompt_date date not null references public.qotd_prompts (prompt_date),
  user_id uuid not null references public.profiles (id) on delete cascade,
  answer text not null,
  created_at timestamptz not null default now(),
  unique (couple_id, prompt_date, user_id)
);

create table public.partner_quiz_rounds (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  round_date date not null,
  answerer_user_id uuid not null references public.profiles (id),
  guesser_user_id uuid not null references public.profiles (id),
  phase text not null default 'answering' check (phase in ('answering', 'guessing', 'results')),
  unique (couple_id, round_date)
);

create table public.partner_quiz_questions (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.partner_quiz_rounds (id) on delete cascade,
  position int not null,
  prompt text not null,
  options jsonb not null,
  truth_option_id text,
  unique (round_id, position)
);

create table public.partner_quiz_guesses (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.partner_quiz_questions (id) on delete cascade,
  guesser_user_id uuid not null references public.profiles (id),
  option_id text not null,
  unique (question_id, guesser_user_id)
);

alter table public.daily_rounds enable row level security;
alter table public.daily_submissions enable row level security;
alter table public.qotd_prompts enable row level security;
alter table public.qotd_answers enable row level security;
alter table public.partner_quiz_rounds enable row level security;
alter table public.partner_quiz_questions enable row level security;
alter table public.partner_quiz_guesses enable row level security;

create policy "daily_rounds_member"
  on public.daily_rounds for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id));

create policy "daily_submissions_member"
  on public.daily_submissions for all to authenticated
  using (
    exists (
      select 1 from public.daily_rounds r
      where r.id = round_id and public.is_couple_member(r.couple_id)
    )
  )
  with check (user_id = auth.uid());

create policy "qotd_prompts_read"
  on public.qotd_prompts for select to authenticated
  using (true);

create policy "qotd_answers_member"
  on public.qotd_answers for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id) and user_id = auth.uid());

create policy "partner_quiz_rounds_member"
  on public.partner_quiz_rounds for all to authenticated
  using (public.is_couple_member(couple_id))
  with check (public.is_couple_member(couple_id));

-- Guesser must not select truth_option_id until phase = results (tighten via RPC later).
create policy "partner_quiz_questions_member"
  on public.partner_quiz_questions for select to authenticated
  using (
    exists (
      select 1 from public.partner_quiz_rounds r
      where r.id = round_id and public.is_couple_member(r.couple_id)
    )
  );

create policy "partner_quiz_guesses_member"
  on public.partner_quiz_guesses for all to authenticated
  using (
    exists (
      select 1
      from public.partner_quiz_questions q
      join public.partner_quiz_rounds r on r.id = q.round_id
      where q.id = question_id and public.is_couple_member(r.couple_id)
    )
  )
  with check (guesser_user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage buckets (run in dashboard or via storage API; SQL helper)
-- ---------------------------------------------------------------------------
-- insert into storage.buckets (id, name, public) values
--   ('wishlist-photos', 'wishlist-photos', false),
--   ('memory-photos', 'memory-photos', false)
-- on conflict do nothing;
