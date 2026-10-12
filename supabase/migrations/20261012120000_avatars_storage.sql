-- Profile avatars bucket (path: {user_id}/avatar.jpg)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "avatars_own_objects" on storage.objects;
create policy "avatars_own_objects"
  on storage.objects for all to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Partners can read each other's avatar objects when in the same couple.
drop policy if exists "avatars_couple_read" on storage.objects;
create policy "avatars_couple_read"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'avatars'
    and exists (
      select 1
      from public.couple_members me
      join public.couple_members them
        on them.couple_id = me.couple_id
      where me.user_id = auth.uid()
        and them.user_id::text = (storage.foldername(name))[1]
    )
  );
