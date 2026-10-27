-- Row-level security and RPC behaviour for accounts, saves and Ghost Arena.
-- Each block acts as one player via `set role authenticated` + tests.as_user.

\set alice '''aaaaaaaa-0000-0000-0000-000000000001'''
\set bob   '''bbbbbbbb-0000-0000-0000-000000000002'''
\set cara  '''cccccccc-0000-0000-0000-000000000003'''

insert into auth.users (id) values (:alice), (:bob), (:cara);

-- New users get a guest profile.
do $$ begin
  assert (select count(*) from public.profiles) = 3, 'one profile per user';
  assert (select display_name from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001') = 'Guest-AAAA',
    'guest name from the id';
end $$;

-- Saves: a newer rev lands, an older one is refused and the newer copy comes back.
set role authenticated;
select tests.as_user(:alice);
do $$
declare s public.saves;
begin
  s := public.push_save(3, '{"wins": 3}', '0.1.0');
  assert s.rev = 3 and s.data ->> 'wins' = '3', 'first push lands';
  s := public.push_save(2, '{"wins": 1}');
  assert s.rev = 3 and s.data ->> 'wins' = '3', 'older push is refused';
  s := public.push_save(4, '{"wins": 4}');
  assert s.rev = 4, 'newer push lands';
end $$;

-- Players can't see or write each other's saves, or touch tables directly.
select tests.as_user(:bob);
do $$ begin
  assert (select count(*) from public.saves) = 0, 'bob cannot read alice''s save';
  begin
    insert into public.saves (user_id, rev, data) values ('bbbbbbbb-0000-0000-0000-000000000002', 1, '{}');
    assert false, 'direct save insert should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Profiles: rename yourself (only through set_display_name, see
-- test_rename.sql), never your trophies, never someone else.
do $$ begin
  perform public.set_display_name('Bobby');
  assert (select display_name from public.profiles where id = 'bbbbbbbb-0000-0000-0000-000000000002') = 'Bobby', 'rename';
  begin
    update public.profiles set display_name = 'Hacked' where id = 'aaaaaaaa-0000-0000-0000-000000000001';
    assert false, 'names are not directly writable';
  exception when insufficient_privilege then null;
  end;
  assert (select display_name from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001') = 'Guest-AAAA',
    'cannot rename others';
  begin
    update public.profiles set trophies = 9999 where id = 'bbbbbbbb-0000-0000-0000-000000000002';
    assert false, 'trophies should not be writable';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Ghost Arena: no opponents yet -> null; lineups only for yourself.
select tests.as_user(:alice);
do $$ begin
  assert public.start_ghost_fight('{"v":1,"rules":1,"slots":[{"critter":"vampire"}],"aim":[]}') is null,
    'no opponents yet';
  insert into public.ghost_lineups (user_id, lineup, rules_version)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '{"v":1,"rules":1,"slots":[{"critter":"vampire"}],"aim":[-450]}', 1);
  begin
    insert into public.ghost_lineups (user_id, lineup, rules_version)
      values ('bbbbbbbb-0000-0000-0000-000000000002', '{"v":1,"rules":1,"slots":[{"critter":"laser"}]}', 1);
    assert false, 'cannot set someone else''s lineup';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.start_ghost_fight('{"v":1,"rules":1,"slots":[]}');
    assert false, 'empty lineup should be refused';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Bob attacks Alice and wins; Alice's lineup is frozen into the fight.
select tests.as_user(:bob);
do $$
declare
  fight jsonb;
  done jsonb;
begin
  fight := public.start_ghost_fight('{"v":1,"rules":1,"slots":[{"critter":"laser"}],"aim":[]}');
  assert fight is not null, 'alice is an opponent';
  assert fight -> 'defender' ->> 'name' = 'Guest-AAAA', 'defender card';
  assert (fight ->> 'seed')::int > 0, 'server seed';
  done := public.finish_ghost_fight((fight ->> 'fight_id')::bigint, '{"angles":[-400]}', 0::smallint, 'abc');
  assert (done ->> 'attacker_delta')::int = 30 and (done ->> 'trophies')::int = 30, 'win pays';
  begin
    perform public.finish_ghost_fight((fight ->> 'fight_id')::bigint, '{}', 0::smallint, 'abc');
    assert false, 'a fight finishes once';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Quitting an open fight counts as a loss when the next one starts.
do $$
declare
  first jsonb;
  second jsonb;
begin
  first := public.start_ghost_fight('{"v":1,"rules":1,"slots":[{"critter":"laser"}],"aim":[]}');
  second := public.start_ghost_fight('{"v":1,"rules":1,"slots":[{"critter":"laser"}],"aim":[]}');
  assert (select status from public.ghost_fights where id = (first ->> 'fight_id')::bigint) = 'abandoned',
    'open fight abandoned';
  assert (select trophies from public.profiles where id = 'bbbbbbbb-0000-0000-0000-000000000002') = 10, '30 - 20';
end $$;

-- Cara can't finish Bob's fight, and can't see fights she wasn't in.
select tests.as_user(:cara);
do $$ begin
  assert (select count(*) from public.ghost_fights) = 0, 'cara sees no fights';
  begin
    perform public.finish_ghost_fight((select max(id) from public.ghost_fights), '{}', 0::smallint, '');
    assert false, 'cannot finish another player''s fight';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Signed-out (anon) callers get nothing.
reset role;
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.push_save(1, '{}');
    assert false, 'anon cannot push saves';
  exception when insufficient_privilege then null;
  end;
  begin
    perform count(*) from public.profiles;
    assert false, 'anon cannot read profiles';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
