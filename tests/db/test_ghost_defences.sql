-- Ghost Arena defences: players save their own squad only, and
-- arena_opponents serves other players' squads nearest your trophies.
-- Runs after test_backend.sql (file names sort), which created alice, bob and cara.

\set alice '''aaaaaaaa-0000-0000-0000-000000000001'''
\set bob   '''bbbbbbbb-0000-0000-0000-000000000002'''
\set cara  '''cccccccc-0000-0000-0000-000000000003'''

set role authenticated;
select tests.as_user(:alice);
insert into public.arena_defences (user_id, lineup, rules_version, trophies, power)
values (:alice, '{"slots": [{"critter": "vampire"}, {"critter": "laser"}, {"critter": "spiker"}]}', 7, 1200, 9000);
do $$ begin
  begin
    insert into public.arena_defences (user_id, lineup, rules_version)
    values ('bbbbbbbb-0000-0000-0000-000000000002', '{"slots": [{}, {}, {}]}', 7);
    assert false, 'saving someone else''s squad should fail';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.arena_defences (user_id, lineup, rules_version)
    values (auth.uid(), '{"slots": [{}]}', 7)
    on conflict (user_id) do update set lineup = excluded.lineup;
    assert false, 'a squad is three critters';
  exception when check_violation then null;
  end;
  -- Nobody else has a squad yet, and your own never comes back.
  assert public.arena_opponents(1200, 7) = '[]'::jsonb, 'no opponents yet';
end $$;

select tests.as_user(:bob);
insert into public.arena_defences (user_id, lineup, rules_version, trophies, power)
values (:bob, '{"slots": [{"critter": "laser"}, {"critter": "vampire"}, {"critter": "spiker"}]}', 7, 1500, 9500);
do $$ begin
  assert (select count(*) from public.arena_defences) = 1, 'only your own row is readable';
end $$;

select tests.as_user(:cara);
insert into public.arena_defences (user_id, lineup, rules_version, trophies, power)
values (:cara, '{"slots": [{"critter": "laser"}, {"critter": "vampire"}, {"critter": "spiker"}]}', 6, 1210, 9000);
do $$
declare
  res jsonb := public.arena_opponents(1210, 7, 5);
begin
  assert jsonb_array_length(res) = 2, 'alice and bob on these rules: ' || res::text;
  assert res -> 0 ->> 'name' = (select display_name from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001'), 'nearest first, with a name';
  assert (res -> 0 ->> 'trophies')::int = 1200, 'their trophies';
  assert res -> 0 -> 'lineup' -> 'slots' -> 0 ->> 'critter' = 'vampire', 'their squad';
  assert jsonb_array_length(public.arena_opponents(1210, 7, 1)) = 1, 'count is kept';
end $$;

reset role;
