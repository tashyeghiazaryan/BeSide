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
