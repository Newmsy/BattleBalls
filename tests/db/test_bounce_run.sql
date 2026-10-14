-- Bounce Run leaderboard: possible scores only, one per player per day,
-- ranked floors > lives > time, and no direct table access. Player ids use
-- their own prefixes so other suites' `like 'dddddddd%'` filters miss them.

\set dana '''d5000000-0000-0000-0000-000000000004'''
\set eli  '''e5000000-0000-0000-0000-000000000005'''
\set fay  '''f5000000-0000-0000-0000-000000000006'''

reset role;
insert into auth.users (id) values (:dana), (:eli), (:fay);

set role authenticated;
select tests.as_user(:dana);
do $$
declare
  today integer := public.bounce_run_today();
  r record;
begin
  -- Cleared all 8 floors with 2 left: 8 wins + 1 loss = 9 fights.
  select * into r from public.submit_bounce_run(today, 8, 2, 9 * 1800,
    jsonb_build_object('picks', '[0,1,2]'::jsonb, 'fights', (select jsonb_agg(i) from generate_series(1, 9) i)), 1);
  assert r.rank = 1 and r.total = 1, 'first score ranks first';
  -- A second post the same day changes nothing.
  select * into r from public.submit_bounce_run(today, 0, 0, 3 * 1800,
    jsonb_build_object('fights', (select jsonb_agg(i) from generate_series(1, 3) i)), 1);
  assert (select floors from public.bounce_run_board(today) where is_me) = 8, 'first score stands';
  -- Impossible scores are refused.
  begin
    perform public.submit_bounce_run(today, 5, 2, 9000, '{"fights": [1,2,3,4,5,6]}', 1);
    assert false, 'a run can only end on floor 8 or with no lives';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.submit_bounce_run(today - 5, 0, 0, 9000, '{"fights": [1,2,3]}', 1);
    assert false, 'old days are closed';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.submit_bounce_run(today + 1, 2, 0, 10, '{"fights": [1,2,3,4,5]}', 1);
    assert false, 'too fast to be real';
  exception when invalid_parameter_value then null;
  end;
end $$;

select tests.as_user(:eli);
do $$
declare today integer := public.bounce_run_today();
begin
  -- Floor 3 (3 wins + 3 losses).
  perform public.submit_bounce_run(today, 3, 0, 6 * 1200, '{"fights": [1,2,3,4,5,6]}', 1);
end $$;

select tests.as_user(:fay);
do $$
declare today integer := public.bounce_run_today();
begin
  -- Same floors and lives as eli, faster: ranks above eli.
  perform public.submit_bounce_run(today, 3, 0, 6 * 1000, '{"fights": [1,2,3,4,5,6]}', 1);
  assert (select array_agg(floors::int || ':' || ticks order by rank) from public.bounce_run_board(today))
    = array['8:16200', '3:6000', '3:7200'], 'floors, then lives, then time';
  assert (select rank from public.bounce_run_board(today) where is_me) = 2, 'fay is second';
  assert (select count(*) from public.bounce_run_board(today, 1)) = 2, 'top 1 plus my own row';
  assert (select display_name from public.bounce_run_board(today) where rank = 1) = 'Guest-D500', 'guest names';
  begin
    perform count(*) from public.bounce_run_scores;
    assert false, 'scores are not directly readable';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Not signed in: no access.
reset role;
set role anon;
do $$ begin
  begin
    perform public.bounce_run_board(1);
    assert false, 'anon cannot read the board';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
