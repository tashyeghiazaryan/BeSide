-- Couple stories strip on Us (photo frames for v1; shared by couple members).
-- Client still uses session store until live gateway wires this table.

create table if not exists public.couple_stories (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  author_user_id uuid not null references auth.users (id) on delete cascade,
  image_path text not null,
  created_at timestamptz not null default now()
);

create index if not exists couple_stories_couple_created_idx
  on public.couple_stories (couple_id, created_at desc);

alter table public.couple_stories enable row level security;

create policy "couple_stories_member"
  on public.couple_stories for all to authenticated
  using (
    exists (
      select 1 from public.couple_members m
      where m.couple_id = couple_stories.couple_id
        and m.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.couple_members m
      where m.couple_id = couple_stories.couple_id
        and m.user_id = auth.uid()
    )
    and author_user_id = auth.uid()
  );
