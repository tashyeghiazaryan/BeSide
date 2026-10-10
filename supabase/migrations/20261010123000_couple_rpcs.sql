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
