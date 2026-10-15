-- Test save slots: while the game's test mode is on (game/online/test_user.gd),
-- every device syncs its save with one shared slot instead of the signed-in
-- account's row, so Newms can carry one game across several devices before
-- real sign-in works everywhere.
--
-- Same compare-and-swap rules as sync_save (*_save_sync.sql). Slots are open
-- to any signed-in player (every visitor is at least a guest), so nothing may
-- ever trust them: no other table, RPC or PvP rule reads test_saves, and the
-- worst anyone can do is read or overwrite a test slot. Drop this table once
-- test mode is switched off for good.

create table public.test_saves (
  slot int primary key check (slot between 1 and 9),
  rev bigint not null check (rev >= 0),
  data jsonb not null check (pg_column_size(data) <= 262144),
  app_version text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid
);

-- Only reachable through the two functions below.
alter table public.test_saves enable row level security;
revoke all on public.test_saves from anon, authenticated;

create function public.test_load_save(p_slot int)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  cur public.test_saves;
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  select * into cur from public.test_saves where slot = p_slot;
  if not found then
    return jsonb_build_object('rev', 0, 'data', null);
  end if;
  return jsonb_build_object('rev', cur.rev, 'data', cur.data);
end;
$$;

create function public.test_sync_save(p_slot int, p_base_rev bigint, p_data jsonb, p_app_version text default '')
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  cur public.test_saves;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_slot is null or p_slot not between 1 and 9 then
    raise exception 'bad slot' using errcode = '22023';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'bad save' using errcode = '22023';
  end if;

  select * into cur from public.test_saves where slot = p_slot for update;
  if not found then
    if coalesce(p_base_rev, 0) <> 0 then
      return jsonb_build_object('saved', false, 'rev', 0, 'data', null);
    end if;
    -- Two devices creating the slot at once: the loser hears about the winner.
    insert into public.test_saves (slot, rev, data, app_version, updated_by)
    values (p_slot, 1, p_data, left(coalesce(p_app_version, ''), 40), me)
    on conflict (slot) do nothing
    returning * into cur;
    if not found then
      select * into cur from public.test_saves where slot = p_slot;
      return jsonb_build_object('saved', false, 'rev', cur.rev, 'data', cur.data);
    end if;
    return jsonb_build_object('saved', true, 'rev', cur.rev);
  end if;

  if cur.rev <> p_base_rev then
    return jsonb_build_object('saved', false, 'rev', cur.rev, 'data', cur.data);
  end if;

  update public.test_saves
    set rev = cur.rev + 1, data = p_data, app_version = left(coalesce(p_app_version, ''), 40),
        updated_at = now(), updated_by = me
    where slot = p_slot
    returning * into cur;
  return jsonb_build_object('saved', true, 'rev', cur.rev);
end;
$$;

revoke all on function public.test_load_save(int) from public, anon;
revoke all on function public.test_sync_save(int, bigint, jsonb, text) from public, anon;
grant execute on function public.test_load_save(int) to authenticated;
grant execute on function public.test_sync_save(int, bigint, jsonb, text) to authenticated;
