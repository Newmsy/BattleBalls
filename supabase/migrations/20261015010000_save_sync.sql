-- Cloud save v2: compare-and-swap sync with server-assigned revisions.
--
-- v1 (push_save) trusted a per-device counter, so two devices on one account
-- could each think they were newest and the older progress silently won or
-- lost. Now the client says which cloud revision its edits are based on; the
-- write only lands if the cloud is still at that revision, and the server
-- picks the next number. On a mismatch the client gets the cloud copy back
-- and resolves the conflict itself (game/online/save_game.gd).
-- push_save stays for builds still cached in browsers.

create function public.sync_save(p_base_rev bigint, p_data jsonb, p_app_version text default '')
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  cur public.saves;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'bad save' using errcode = '22023';
  end if;

  select * into cur from public.saves where user_id = me for update;
  if not found then
    if coalesce(p_base_rev, 0) <> 0 then
      -- The client thinks there is a cloud save but there isn't (project
      -- reset, or a different account): tell it so instead of writing.
      return jsonb_build_object('saved', false, 'rev', 0, 'data', null);
    end if;
    insert into public.saves (user_id, rev, data, app_version)
    values (me, 1, p_data, coalesce(p_app_version, ''))
    returning * into cur;
    return jsonb_build_object('saved', true, 'rev', cur.rev);
  end if;

  if cur.rev <> p_base_rev then
    return jsonb_build_object('saved', false, 'rev', cur.rev, 'data', cur.data);
  end if;

  update public.saves
    set rev = cur.rev + 1, data = p_data, app_version = coalesce(p_app_version, ''), updated_at = now()
    where user_id = me
    returning * into cur;
  return jsonb_build_object('saved', true, 'rev', cur.rev);
end;
$$;

revoke all on function public.sync_save(bigint, jsonb, text) from public, anon;
grant execute on function public.sync_save(bigint, jsonb, text) to authenticated;
