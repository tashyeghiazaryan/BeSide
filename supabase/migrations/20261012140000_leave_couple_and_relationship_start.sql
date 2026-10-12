-- Leave couple (disconnect both) + set relationship start date

create or replace function public.leave_couple()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_couple uuid;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  select m.couple_id into v_couple
  from public.couple_members m
  where m.user_id = v_user
  limit 1;

  if v_couple is null then
    return;
  end if;

  delete from public.invite_codes where couple_id = v_couple;
  -- Cascades couple_members and couple-scoped content.
  delete from public.couples where id = v_couple;
end;
$$;

grant execute on function public.leave_couple() to authenticated;

create or replace function public.set_relationship_start(p_date date)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_couple uuid;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  if p_date is null then
    raise exception 'date required';
  end if;

  select m.couple_id into v_couple
  from public.couple_members m
  where m.user_id = v_user
  limit 1;

  if v_couple is null then
    raise exception 'not in a couple';
  end if;

  update public.couples
  set relationship_start_date = p_date
  where id = v_couple;
end;
$$;

grant execute on function public.set_relationship_start(date) to authenticated;
