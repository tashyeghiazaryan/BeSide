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
-- RPCs for create/join couple (security definer + membership checks)

create or replace function public.ensure_profile(p_display_name text default '')
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  row public.profiles;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  insert into public.profiles (id, display_name)
  values (auth.uid(), coalesce(nullif(trim(p_display_name), ''), 'Partner'))
  on conflict (id) do update
    set display_name = case
      when nullif(trim(p_display_name), '') is null then public.profiles.display_name
      else trim(p_display_name)
    end,
    updated_at = now()
  returning * into row;

  return row;
end;
$$;

create or replace function public.create_couple_with_invite(p_display_name text default '')
returns table (
  couple_id uuid,
  invite_code text,
  display_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_couple uuid;
  v_code text;
  v_name text;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile(p_display_name);

  if exists (select 1 from public.couple_members where user_id = v_user) then
    raise exception 'already in a couple';
  end if;

  insert into public.couples default values
  returning id into v_couple;

  insert into public.couple_members (couple_id, user_id)
  values (v_couple, v_user);

  insert into public.couple_progress (couple_id)
  values (v_couple);

  -- Short readable code: BESIDE-XXXX
  v_code := 'BESIDE-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));

  insert into public.invite_codes (code, couple_id, created_by, expires_at)
  values (v_code, v_couple, v_user, now() + interval '7 days');

  select p.display_name into v_name from public.profiles p where p.id = v_user;

  return query select v_couple, v_code, v_name;
end;
$$;

create or replace function public.join_couple_with_code(p_code text, p_display_name text default '')
returns table (
  couple_id uuid,
  partner_user_id uuid,
  display_name text,
  partner_display_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_code text := upper(trim(p_code));
  v_invite public.invite_codes;
  v_partner uuid;
  v_my_name text;
  v_partner_name text;
  v_member_count int;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile(p_display_name);

  if exists (select 1 from public.couple_members where user_id = v_user) then
    raise exception 'already in a couple';
  end if;

  select * into v_invite
  from public.invite_codes
  where code = v_code
  for update;

  if not found then
    raise exception 'invalid invite code';
  end if;

  if v_invite.consumed_at is not null then
    raise exception 'invite already used';
  end if;

  if v_invite.expires_at is not null and v_invite.expires_at < now() then
    raise exception 'invite expired';
  end if;

  select count(*) into v_member_count
  from public.couple_members
  where couple_id = v_invite.couple_id;

  if v_member_count >= 2 then
    raise exception 'couple is full';
  end if;

  insert into public.couple_members (couple_id, user_id)
  values (v_invite.couple_id, v_user);

  update public.invite_codes
  set consumed_at = now()
  where code = v_code;

  select m.user_id into v_partner
  from public.couple_members m
  where m.couple_id = v_invite.couple_id and m.user_id <> v_user
  limit 1;

  select p.display_name into v_my_name from public.profiles p where p.id = v_user;
  select p.display_name into v_partner_name from public.profiles p where p.id = v_partner;

  return query select v_invite.couple_id, v_partner, v_my_name, coalesce(v_partner_name, 'Partner');
end;
$$;

create or replace function public.fetch_couple_context()
returns table (
  user_id uuid,
  couple_id uuid,
  partner_user_id uuid,
  display_name text,
  partner_display_name text,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile('');

  return query
  select
    v_user,
    m.couple_id,
    partner.user_id,
    coalesce(me.display_name, ''),
    partner_profile.display_name,
    ic.code
  from public.profiles me
  left join public.couple_members m on m.user_id = me.id
  left join public.couple_members partner
    on partner.couple_id = m.couple_id and partner.user_id <> me.id
  left join public.profiles partner_profile on partner_profile.id = partner.user_id
  left join lateral (
    select c.code
    from public.invite_codes c
    where c.couple_id = m.couple_id
      and c.consumed_at is null
      and (c.expires_at is null or c.expires_at > now())
    order by c.created_at desc
    limit 1
  ) ic on true
  where me.id = v_user;
end;
$$;

grant execute on function public.ensure_profile(text) to authenticated;
grant execute on function public.create_couple_with_invite(text) to authenticated;
grant execute on function public.join_couple_with_code(text, text) to authenticated;
grant execute on function public.fetch_couple_context() to authenticated;
-- Storage buckets + permissive couple-scoped policies (tighten later)
insert into storage.buckets (id, name, public)
values
  ('wishlist-photos', 'wishlist-photos', false),
  ('memory-photos', 'memory-photos', false)
on conflict (id) do nothing;

-- Authenticated users can read/write objects under their couple folder prefix:
-- path: {couple_id}/{...}
create policy "wishlist_photos_auth_rw"
  on storage.objects for all to authenticated
  using (bucket_id = 'wishlist-photos')
  with check (bucket_id = 'wishlist-photos');

create policy "memory_photos_auth_rw"
  on storage.objects for all to authenticated
  using (bucket_id = 'memory-photos')
  with check (bucket_id = 'memory-photos');

-- Seed a few QOTD prompts (dates relative to migration day — app also upserts today)
insert into public.qotd_prompts (prompt_date, prompt) values
  (current_date, 'What''s one small thing that made you smile today?'),
  (current_date + 1, 'What do you want more of together this week?'),
  (current_date + 2, 'What is one thing your partner did recently that you appreciated?')
on conflict (prompt_date) do nothing;

-- Allow authenticated insert into qotd_prompts for ensureTodayQOTDPrompt
create policy "qotd_prompts_insert_auth"
  on public.qotd_prompts for insert to authenticated
  with check (true);
-- Fix: RETURNS TABLE (couple_id ...) shadows table columns → "column reference couple_id is ambiguous"

create or replace function public.create_couple_with_invite(p_display_name text default '')
returns table (
  couple_id uuid,
  invite_code text,
  display_name text
)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_user uuid := auth.uid();
  v_couple uuid;
  v_code text;
  v_name text;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile(p_display_name);

  if exists (select 1 from public.couple_members cm where cm.user_id = v_user) then
    raise exception 'already in a couple';
  end if;

  insert into public.couples default values
  returning id into v_couple;

  insert into public.couple_members (couple_id, user_id)
  values (v_couple, v_user);

  insert into public.couple_progress (couple_id)
  values (v_couple);

  v_code := 'BESIDE-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));

  insert into public.invite_codes (code, couple_id, created_by, expires_at)
  values (v_code, v_couple, v_user, now() + interval '7 days');

  select p.display_name into v_name from public.profiles p where p.id = v_user;

  couple_id := v_couple;
  invite_code := v_code;
  display_name := v_name;
  return next;
end;
$$;

create or replace function public.join_couple_with_code(p_code text, p_display_name text default '')
returns table (
  couple_id uuid,
  partner_user_id uuid,
  display_name text,
  partner_display_name text
)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_user uuid := auth.uid();
  v_code text := upper(trim(p_code));
  v_invite public.invite_codes;
  v_partner uuid;
  v_my_name text;
  v_partner_name text;
  v_member_count int;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile(p_display_name);

  if exists (select 1 from public.couple_members cm where cm.user_id = v_user) then
    raise exception 'already in a couple';
  end if;

  select ic.* into v_invite
  from public.invite_codes ic
  where ic.code = v_code
  for update;

  if not found then
    raise exception 'invalid invite code';
  end if;

  if v_invite.consumed_at is not null then
    raise exception 'invite already used';
  end if;

  if v_invite.expires_at is not null and v_invite.expires_at < now() then
    raise exception 'invite expired';
  end if;

  select count(*) into v_member_count
  from public.couple_members cm
  where cm.couple_id = v_invite.couple_id;

  if v_member_count >= 2 then
    raise exception 'couple is full';
  end if;

  insert into public.couple_members (couple_id, user_id)
  values (v_invite.couple_id, v_user);

  update public.invite_codes ic
  set consumed_at = now()
  where ic.code = v_code;

  select m.user_id into v_partner
  from public.couple_members m
  where m.couple_id = v_invite.couple_id and m.user_id <> v_user
  limit 1;

  select p.display_name into v_my_name from public.profiles p where p.id = v_user;
  select p.display_name into v_partner_name from public.profiles p where p.id = v_partner;

  couple_id := v_invite.couple_id;
  partner_user_id := v_partner;
  display_name := v_my_name;
  partner_display_name := coalesce(v_partner_name, 'Partner');
  return next;
end;
$$;

create or replace function public.fetch_couple_context()
returns table (
  user_id uuid,
  couple_id uuid,
  partner_user_id uuid,
  display_name text,
  partner_display_name text,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  perform public.ensure_profile('');

  return query
  select
    v_user,
    m.couple_id,
    partner.user_id,
    coalesce(me.display_name, ''),
    partner_profile.display_name,
    ic.code
  from public.profiles me
  left join public.couple_members m on m.user_id = me.id
  left join public.couple_members partner
    on partner.couple_id = m.couple_id and partner.user_id <> me.id
  left join public.profiles partner_profile on partner_profile.id = partner.user_id
  left join lateral (
    select c.code
    from public.invite_codes c
    where c.couple_id = m.couple_id
      and c.consumed_at is null
      and (c.expires_at is null or c.expires_at > now())
    order by c.created_at desc
    limit 1
  ) ic on true
  where me.id = v_user;
end;
$$;
