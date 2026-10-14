-- Game analytics: anonymous play events and a key-gated stats summary.
--
-- Privacy: an event row holds the guest's auth id (no name, email, device id
-- or IP), an event name and a small JSON blob of game facts (critter ids,
-- results, steps). Players can opt out in game, which also calls
-- forget_my_analytics(). Deleting an account cascades to its events.
--
-- Security model: everything lives in the `analytics` schema, which the API
-- roles cannot see at all. The game writes through log_events() as the
-- signed-in guest; the stats screen reads through analytics_dashboard(),
-- which only answers to a dashboard key and only returns aggregates.

create schema analytics;
revoke all on schema analytics from public, anon, authenticated;

create table analytics.events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  session_id text not null default '' check (char_length(session_id) <= 40),
  name text not null check (name ~ '^[a-z][a-z0-9_]{0,39}$'),
  props jsonb not null default '{}' check (jsonb_typeof(props) = 'object' and pg_column_size(props) <= 2048),
  -- When it happened: the client's clock, clamped to the last 7 days before
  -- arrival so a wrong clock can't move events into the future or far past.
  at timestamptz not null,
  received_at timestamptz not null default now(),
  is_test boolean not null default false
);

create index events_at on analytics.events (at);
create index events_name_at on analytics.events (name, at);
create index events_user_received on analytics.events (user_id, received_at);

-- One row per player and per active day, kept by log_events(), so retention
-- and active-player counts never scan the raw events.
create table analytics.players (
  user_id uuid primary key references auth.users (id) on delete cascade,
  first_at timestamptz not null,
  last_at timestamptz not null,
  platform text not null default '',
  app_version text not null default '',
  is_test boolean not null default false
);

create table analytics.player_days (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  primary key (user_id, day)
);

create index player_days_day on analytics.player_days (day);

-- Dashboard keys are stored as SHA-256 hashes; the raw key only ever lives in
-- the owner's dashboard link. Mint another from the Supabase SQL editor with
--   select analytics.new_dashboard_key('phone');
-- and revoke one with
--   delete from analytics.dashboard_keys where label = 'phone';
create table analytics.dashboard_keys (
  key_hash bytea primary key,
  label text not null default '',
  created_at timestamptz not null default now(),
  last_used_at timestamptz
);

insert into analytics.dashboard_keys (key_hash, label)
values (decode('648bb64b97d55e085d658ad9df30a520da3eeb201e1b98355b92379a13f4c475', 'hex'), 'newms');

create function analytics.new_dashboard_key(p_label text default '') returns text
language plpgsql set search_path = '' as $$
declare
  k text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
begin
  insert into analytics.dashboard_keys (key_hash, label) values (sha256(convert_to(k, 'UTF8')), coalesce(p_label, ''));
  return k;
end;
$$;

alter table analytics.events enable row level security;
alter table analytics.players enable row level security;
alter table analytics.player_days enable row level security;
alter table analytics.dashboard_keys enable row level security;
revoke all on all tables in schema analytics from public, anon, authenticated;
revoke all on function analytics.new_dashboard_key(text) from public, anon, authenticated;

-- Writing -------------------------------------------------------------------
-- p_events: [{"name": "fight_end", "props": {...}, "t": <unix ms>}, ...]
-- Malformed events are skipped, not fatal, so one bad event can't wedge a
-- client's queue. Returns how many were stored. A player sending more than
-- 5000 events a day is dropped silently (a bug or abuse, not play).

create function public.log_events(p_events jsonb, p_session text default '', p_app_version text default '',
  p_platform text default '', p_test boolean default false)
returns integer
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  n integer;
  lo timestamptz;
  hi timestamptz;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if jsonb_typeof(p_events) is distinct from 'array' or jsonb_array_length(p_events) > 100 then
    raise exception 'send an array of at most 100 events' using errcode = '22023';
  end if;
  if (select count(*) from analytics.events where user_id = me and received_at > now() - interval '1 day') >= 5000 then
    return 0;
  end if;
  with incoming as (
    select e ->> 'name' as name,
      coalesce(e -> 'props', '{}'::jsonb) as props,
      case when e ->> 't' ~ '^[0-9]{12,14}$'
        then greatest(now() - interval '7 days', least(now(), to_timestamp((e ->> 't')::double precision / 1000)))
        else now() end as at
    from jsonb_array_elements(p_events) e
    where jsonb_typeof(e) = 'object'
  ), ins as (
    insert into analytics.events (user_id, session_id, name, props, at, is_test)
    select me, left(coalesce(p_session, ''), 40), name, props, at, coalesce(p_test, false)
    from incoming
    where name ~ '^[a-z][a-z0-9_]{0,39}$' and jsonb_typeof(props) = 'object' and pg_column_size(props) <= 2048
    returning at
  ), days as (
    insert into analytics.player_days (user_id, day)
    select distinct me, (at at time zone 'UTC')::date from ins
    on conflict do nothing
  )
  select count(*), min(at), max(at) into n, lo, hi from ins;
  if n > 0 then
    insert into analytics.players as p (user_id, first_at, last_at, platform, app_version, is_test)
    values (me, lo, hi, left(coalesce(p_platform, ''), 20), left(coalesce(p_app_version, ''), 20), coalesce(p_test, false))
    on conflict (user_id) do update
      set first_at = least(p.first_at, excluded.first_at), last_at = greatest(p.last_at, excluded.last_at),
          platform = excluded.platform, app_version = excluded.app_version,
          is_test = p.is_test and excluded.is_test; -- one real batch makes a real player
  end if;
  return n;
end;
$$;

-- Opting out deletes everything analytics holds on the caller.
create function public.forget_my_analytics() returns integer
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  n integer;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  delete from analytics.events where user_id = me;
  get diagnostics n = row_count;
  delete from analytics.player_days where user_id = me;
  delete from analytics.players where user_id = me;
  return n;
end;
$$;

revoke all on function public.log_events(jsonb, text, text, text, boolean) from public, anon;
grant execute on function public.log_events(jsonb, text, text, text, boolean) to authenticated;
revoke all on function public.forget_my_analytics() from public, anon;
grant execute on function public.forget_my_analytics() to authenticated;

-- Reading -------------------------------------------------------------------
-- Aggregates for the last p_days days (1 to 90, UTC days), for the stats
-- screen (game/stats/). Test traffic (smoke tests, debug builds) is left out.
-- Event props it reads, written by game/online/analytics.gd:
--   fight_end       {mode, picked, team: [critter], foe: [critter], result: win|loss|draw}
--   onboarding_step {step, ms}
--   energy          {delta, source}
--   screen          {name}

create function public.analytics_dashboard(p_key text, p_days integer default 30)
returns jsonb
language plpgsql security definer set search_path = '' set timezone = 'UTC' as $$
declare
  days integer := least(greatest(coalesce(p_days, 30), 1), 90);
  today date := (now() at time zone 'UTC')::date;
  since date := today - (days - 1);
  since_at timestamptz := since::timestamptz;
  result jsonb;
begin
  update analytics.dashboard_keys set last_used_at = now()
  where key_hash = sha256(convert_to(coalesce(p_key, ''), 'UTF8'));
  if not found then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  with real_players as (
    select user_id, (first_at at time zone 'UTC')::date as d0, platform from analytics.players where not is_test
  ), window_events as (
    select e.user_id, e.name, e.props, (e.at at time zone 'UTC')::date as day
    from analytics.events e
    where e.at >= since_at and not e.is_test and e.user_id in (select user_id from real_players)
  ), active_days as (
    select d.user_id, d.day from analytics.player_days d join real_players r using (user_id) where d.day > today - 90
  )
  select jsonb_build_object(
    'generated_at', now(),
    'days', days,
    'since', since,
    'totals', jsonb_build_object(
      'players', (select count(*) from real_players),
      'new_players', (select count(*) from real_players where d0 >= since),
      'dau', (select count(*) from active_days d where d.day = today),
      'wau', (select count(distinct d.user_id) from active_days d where d.day > today - 7),
      'mau', (select count(distinct d.user_id) from active_days d where d.day > today - 30),
      'fights', (select count(*) from window_events where name = 'fight_end')
    ),
    'daily', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'day', g.day,
        'active', (select count(*) from active_days d where d.day = g.day),
        'new', (select count(*) from real_players r where r.d0 = g.day),
        'fights', (select count(*) from window_events w where w.name = 'fight_end' and w.day = g.day)
      ) order by g.day), '[]'::jsonb)
      from (select generate_series(since, today, interval '1 day')::date as day) g
    ),
    -- Players who started on each day, and how many came back exactly 1, 3
    -- and 7 days later (null until that day has happened).
    'retention', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'day', c.d0,
        'size', c.size,
        'd1', case when c.d0 + 1 <= today then (select count(*) from analytics.player_days d where d.user_id = any (c.ids) and d.day = c.d0 + 1) end,
        'd3', case when c.d0 + 3 <= today then (select count(*) from analytics.player_days d where d.user_id = any (c.ids) and d.day = c.d0 + 3) end,
        'd7', case when c.d0 + 7 <= today then (select count(*) from analytics.player_days d where d.user_id = any (c.ids) and d.day = c.d0 + 7) end
      ) order by c.d0 desc), '[]'::jsonb)
      from (select d0, array_agg(user_id) ids, count(*) size from real_players where d0 >= since group by d0) c
    ),
    -- Tutorial steps reached by players who started in the window, in the
    -- order players usually reach them.
    'onboarding', jsonb_build_object(
      'starters', (select count(*) from real_players where d0 >= since),
      'steps', (
        select coalesce(jsonb_agg(jsonb_build_object('step', s.step, 'players', s.players, 'median_ms', s.median_ms)
          order by s.median_ms nulls last, s.players desc), '[]'::jsonb)
        from (
          select w.props ->> 'step' as step, count(distinct w.user_id) as players,
            round(percentile_cont(0.5) within group (order by case when w.props ->> 'ms' ~ '^[0-9]{1,10}$' then (w.props ->> 'ms')::bigint end)) as median_ms
          from window_events w join real_players r using (user_id)
          where w.name = 'onboarding_step' and r.d0 >= since and coalesce(w.props ->> 'step', '') <> ''
          group by 1
        ) s
      )
    ),
    'energy', (
      select coalesce(jsonb_agg(jsonb_build_object('source', x.source, 'gained', x.gained, 'spent', x.spent, 'players', x.players)
        order by x.gained + x.spent desc), '[]'::jsonb)
      from (
        select coalesce(props ->> 'source', '?') as source,
          sum(greatest(delta, 0)) as gained, sum(greatest(-delta, 0)) as spent, count(distinct user_id) as players
        from (select user_id, props, case when props ->> 'delta' ~ '^-?[0-9]{1,6}$' then (props ->> 'delta')::integer else 0 end as delta
              from window_events where name = 'energy') e
        group by 1
      ) x
    ),
    -- Critters the player chose (picked = true), one count per team slot.
    'critters', jsonb_build_object(
      'fights', (select count(*) from window_events where name = 'fight_end' and props ->> 'picked' = 'true'),
      'rows', (
        select coalesce(jsonb_agg(jsonb_build_object('critter', x.critter, 'picks', x.picks, 'players', x.players,
          'wins', x.wins, 'losses', x.losses, 'draws', x.draws) order by x.picks desc), '[]'::jsonb)
        from (
          select t.critter, count(*) as picks, count(distinct w.user_id) as players,
            count(*) filter (where w.props ->> 'result' = 'win') as wins,
            count(*) filter (where w.props ->> 'result' = 'loss') as losses,
            count(*) filter (where w.props ->> 'result' = 'draw') as draws
          from window_events w,
            jsonb_array_elements_text(case when jsonb_typeof(w.props -> 'team') = 'array' then w.props -> 'team' else '[]'::jsonb end) t (critter)
          where w.name = 'fight_end' and w.props ->> 'picked' = 'true'
          group by 1
        ) x
      )
    ),
    'modes', (
      select coalesce(jsonb_agg(jsonb_build_object('mode', x.mode, 'fights', x.fights, 'players', x.players) order by x.fights desc), '[]'::jsonb)
      from (select coalesce(props ->> 'mode', '?') as mode, count(*) as fights, count(distinct user_id) as players
            from window_events where name = 'fight_end' group by 1) x
    ),
    'screens', (
      select coalesce(jsonb_agg(jsonb_build_object('screen', x.screen, 'views', x.views, 'players', x.players) order by x.views desc), '[]'::jsonb)
      from (select coalesce(props ->> 'name', '?') as screen, count(*) as views, count(distinct user_id) as players
            from window_events where name = 'screen' group by 1) x
    ),
    'platforms', (
      select coalesce(jsonb_agg(jsonb_build_object('platform', x.platform, 'players', x.players) order by x.players desc), '[]'::jsonb)
      from (select coalesce(nullif(r.platform, ''), '?') as platform, count(*) as players
            from real_players r
            where exists (select 1 from active_days d where d.user_id = r.user_id and d.day >= since)
            group by 1) x
    )
  ) into result;
  return result;
end;
$$;

revoke all on function public.analytics_dashboard(text, integer) from public;
grant execute on function public.analytics_dashboard(text, integer) to anon, authenticated;
