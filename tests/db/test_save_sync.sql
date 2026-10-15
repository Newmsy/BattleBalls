-- sync_save: compare-and-swap cloud saves with server-assigned revisions.

\set dana '''dddddddd-0000-0000-0000-000000000004'''
\set eve  '''eeeeeeee-0000-0000-0000-000000000005'''

insert into auth.users (id) values (:dana), (:eve);

set role authenticated;
select tests.as_user(:dana);
do $$
declare r jsonb;
begin
  r := public.sync_save(3, '{"wins": 1}');
  assert r ->> 'saved' = 'false' and (r ->> 'rev')::int = 0, 'no cloud save: a non-zero base is refused';
  r := public.sync_save(0, '{"wins": 1}', '0.2.0');
  assert r ->> 'saved' = 'true' and (r ->> 'rev')::int = 1, 'first save gets rev 1';
  r := public.sync_save(1, '{"wins": 2}');
  assert r ->> 'saved' = 'true' and (r ->> 'rev')::int = 2, 'based on the cloud copy: lands as rev 2';
  -- A second device still based on rev 1 is told about rev 2 instead.
  r := public.sync_save(1, '{"wins": 9}');
  assert r ->> 'saved' = 'false' and (r ->> 'rev')::int = 2 and r -> 'data' ->> 'wins' = '2', 'stale base is refused with the cloud copy';
  assert (select data ->> 'wins' from public.saves) = '2', 'cloud unchanged after a refused write';
  begin
    perform public.sync_save(2, '[1, 2]');
    assert false, 'non-object save should be refused';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Each player only ever touches their own row.
select tests.as_user(:eve);
do $$
declare r jsonb;
begin
  r := public.sync_save(0, '{"wins": 5}');
  assert r ->> 'saved' = 'true' and (r ->> 'rev')::int = 1, 'eve starts at rev 1';
  assert (select count(*) from public.saves) = 1, 'eve sees only her save';
end $$;

reset role;
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.sync_save(0, '{}');
    assert false, 'anon cannot sync';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
