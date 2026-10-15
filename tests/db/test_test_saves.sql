-- test_saves: the shared test slot (test mode, game/online/test_user.gd).

\set fay '''ffffffff-0000-0000-0000-000000000006'''
\set gus '''99999999-0000-0000-0000-000000000007'''

insert into auth.users (id) values (:fay), (:gus);

set role authenticated;
select tests.as_user(:fay);
do $$
declare r jsonb;
begin
  r := public.test_load_save(1);
  assert (r ->> 'rev')::int = 0 and r -> 'data' = 'null'::jsonb, 'empty slot';
  r := public.test_sync_save(1, 4, '{"wins": 1}');
  assert r ->> 'saved' = 'false' and (r ->> 'rev')::int = 0, 'no slot yet: a non-zero base is refused';
  r := public.test_sync_save(1, 0, '{"wins": 1}', '0.3.0');
  assert r ->> 'saved' = 'true' and (r ->> 'rev')::int = 1, 'first save gets rev 1';
  r := public.test_sync_save(1, 0, '{"wins": 7}');
  assert r ->> 'saved' = 'false' and (r ->> 'rev')::int = 1 and r -> 'data' ->> 'wins' = '1', 'second creator hears about the first';
  begin
    perform public.test_sync_save(10, 0, '{}');
    assert false, 'slots stop at 9';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.test_sync_save(1, 1, '"x"');
    assert false, 'non-object save should be refused';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform count(*) from public.test_saves;
    assert false, 'no direct table access';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Another device (another guest) shares the slot, and nothing else.
select tests.as_user(:gus);
do $$
declare r jsonb;
begin
  r := public.test_load_save(1);
  assert (r ->> 'rev')::int = 1 and r -> 'data' ->> 'wins' = '1', 'any device reads the slot';
  r := public.test_sync_save(1, 1, '{"wins": 2}');
  assert r ->> 'saved' = 'true' and (r ->> 'rev')::int = 2, 'and builds on it';
  assert (select count(*) from public.saves) = 0, 'own account save untouched';
end $$;

reset role;
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.test_load_save(1);
    assert false, 'anon cannot read';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
