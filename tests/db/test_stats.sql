-- Analytics: event logging, opt-out, privacy of the raw events and the
-- key-gated dashboard. Uses its own players and removes them at the end.

\set dee '''eeeeeeee-0000-0000-0000-000000000001'''
\set eve '''eeeeeeee-0000-0000-0000-000000000002'''
\set bot '''eeeeeeee-0000-0000-0000-000000000003'''

insert into auth.users (id) values (:dee), (:eve), (:bot);

set role authenticated;
select tests.as_user(:dee);
do $$
declare n integer;
begin
  n := public.log_events('[
    {"name": "app_open", "props": {"first": true}, "t": 1700000000000},
    {"name": "fight_end", "props": {"mode": "normal", "picked": true, "team": ["vampire"], "foe": ["laser"], "result": "win"}},
    {"name": "fight_end", "props": {"mode": "normal", "picked": true, "team": ["vampire"], "foe": ["laser"], "result": "loss"}},
    {"name": "onboarding_step", "props": {"step": "cold_open", "ms": 100}},
    {"name": "onboarding_step", "props": {"step": "starter", "ms": 9000}},
    {"name": "energy", "props": {"delta": 30, "source": "pack"}},
    {"name": "Bad Name"},
    {"name": "screen", "props": "not an object"},
    7
  ]', 'sess1', '0.2.0', 'Web', false);
  assert n = 6, 'stores the six good events, got ' || n;
end $$;

-- The raw tables are out of reach of players.
do $$ begin
  begin
    perform count(*) from analytics.events;
    assert false, 'events should be unreadable';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.log_events('[]'::jsonb || (select jsonb_agg(jsonb_build_object('name', 'x')) from generate_series(1, 101)));
    assert false, 'over 100 events should be refused';
  exception when invalid_parameter_value then null;
  end;
end $$;

select tests.as_user(:eve);
do $$ begin
  perform public.log_events('[{"name": "fight_end", "props": {"mode": "normal", "picked": true, "team": ["laser"], "foe": ["vampire"], "result": "win"}},
    {"name": "onboarding_step", "props": {"step": "cold_open", "ms": 200}}]', 'sess2', '0.2.0', 'iOS', false);
end $$;

-- Smoke-test traffic is stored but kept out of the dashboard.
select tests.as_user(:bot);
do $$ begin
  perform public.log_events('[{"name": "fight_end", "props": {"mode": "normal", "picked": true, "team": ["laser"], "result": "loss"}}]',
    'sess3', '0.2.0', 'Web', true);
end $$;

-- Signed-out callers can't log, and the dashboard needs the key.
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.log_events('[{"name": "x"}]');
    assert false, 'anon should not log';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.analytics_dashboard('wrong');
    assert false, 'wrong key should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

-- A minted key opens the dashboard.
reset role;
select analytics.new_dashboard_key('test') as key \gset
select set_config('stats.key', :'key', false);
set role anon;
do $$
declare
  d jsonb := public.analytics_dashboard(current_setting('stats.key'), 30);
  vamp jsonb;
begin
  assert (d -> 'totals' ->> 'players')::int = 2, 'two real players: ' || (d -> 'totals')::text;
  assert (d -> 'totals' ->> 'dau')::int = 2, 'both active today';
  assert (d -> 'totals' ->> 'fights')::int = 3, 'three real fights';
  assert jsonb_array_length(d -> 'daily') = 30, 'one row per day';
  -- Dee's app_open carried a 2023 clock, clamped to 7 days ago: she started
  -- then and came back today (day 7); Eve started today.
  assert (d -> 'daily' -> 29 ->> 'new')::int = 1 and (d -> 'daily' -> 22 ->> 'new')::int = 1, 'new per day: ' || (d -> 'daily')::text;
  assert (d -> 'retention' -> 0 ->> 'size')::int = 1 and d -> 'retention' -> 0 -> 'd1' = 'null'::jsonb, 'today''s cohort has no d1 yet';
  assert (d -> 'retention' -> 1 ->> 'd7')::int = 1 and (d -> 'retention' -> 1 ->> 'd1')::int = 0, 'dee back on day 7: ' || (d -> 'retention')::text;
  assert d -> 'onboarding' -> 'steps' -> 0 ->> 'step' = 'cold_open' and (d -> 'onboarding' -> 'steps' -> 0 ->> 'players')::int = 2, 'funnel order';
  assert (d -> 'onboarding' -> 'steps' -> 1 ->> 'players')::int = 1, 'one reached the starter pick';
  select r into vamp from jsonb_array_elements(d -> 'critters' -> 'rows') r where r ->> 'critter' = 'vampire';
  assert (vamp ->> 'picks')::int = 2 and (vamp ->> 'wins')::int = 1 and (vamp ->> 'losses')::int = 1, 'vampire record: ' || vamp::text;
  assert (d -> 'critters' ->> 'fights')::int = 3, 'test fight left out';
  assert (d -> 'energy' -> 0 ->> 'gained')::int = 30, 'energy gained';
  assert jsonb_array_length(d -> 'platforms') = 2, 'web and ios';
end $$;
reset role;

-- Opting out wipes the caller's analytics.
set role authenticated;
select tests.as_user(:dee);
do $$ begin
  assert public.forget_my_analytics() = 6, 'deleted dee''s events';
end $$;
reset role;
do $$ begin
  assert not exists (select from analytics.events where user_id = 'eeeeeeee-0000-0000-0000-000000000001'), 'events gone';
  assert not exists (select from analytics.players where user_id = 'eeeeeeee-0000-0000-0000-000000000001'), 'player gone';
  assert exists (select from analytics.events where user_id = 'eeeeeeee-0000-0000-0000-000000000002'), 'others kept';
end $$;

delete from analytics.dashboard_keys where label = 'test';
delete from auth.users where id in (:dee, :eve, :bot);
