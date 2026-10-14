-- Accounts, cloud saves and Ghost Arena (async PvP) storage.
--
-- Security model: the game only ever holds the public anon/publishable key and
-- a player's own session token, so every table has row-level security and
-- anything that decides an outcome (trophies, opponent choice, fight seeds)
-- runs in a SECURITY DEFINER function the client can call but not bypass.

-- Profiles ------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 20),
  trophies integer not null default 0 check (trophies >= 0),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Names and trophies are public (leaderboards, ghost opponent cards).
create policy "profiles are readable by signed-in players"
  on public.profiles for select to authenticated using (true);
create policy "players rename themselves"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Only the name is player-editable; trophies move through ghost fights only.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

-- Every new auth user (guest or linked) gets a profile with a guest name.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, 'Guest-' || upper(substr(replace(new.id::text, '-', ''), 1, 4)));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Cloud saves ---------------------------------------------------------------
-- One save per player. `rev` is the client's save counter: a push only lands
-- if it is newer than what the cloud has, so an old device can't clobber
-- newer progress.

create table public.saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  rev bigint not null check (rev >= 0),
  data jsonb not null check (pg_column_size(data) <= 262144),
  app_version text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.saves enable row level security;

create policy "players read their own save"
  on public.saves for select to authenticated using (user_id = auth.uid());

revoke all on public.saves from anon, authenticated;
grant select on public.saves to authenticated;

-- Returns the cloud save after the push: the pushed one if it was newer,
-- otherwise the newer cloud copy the client should adopt.
create function public.push_save(p_rev bigint, p_data jsonb, p_app_version text default '')
returns public.saves
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  result public.saves;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  insert into public.saves as s (user_id, rev, data, app_version)
  values (me, p_rev, p_data, coalesce(p_app_version, ''))
  on conflict (user_id) do update
    set rev = excluded.rev, data = excluded.data,
        app_version = excluded.app_version, updated_at = now()
    where s.rev < excluded.rev;
  select * into result from public.saves where user_id = me;
  return result;
end;
$$;

revoke all on function public.push_save(bigint, jsonb, text) from public, anon;
grant execute on function public.push_save(bigint, jsonb, text) to authenticated;

-- Ghost Arena ---------------------------------------------------------------
-- Each player has one defence lineup. Attackers fight a frozen copy of it,
-- with a seed the server picks, so a fight can be re-run later from
-- (rules_version, attacker lineup, defender lineup, seed, inputs).
--
-- Lineup JSON (v1), written by game/online/ghost_lineup.gd:
--   {"v": 1, "rules": <MatchSim.RULES_VERSION>,
--    "slots": [{"critter": "vampire", "tier": 1, "level": 1, "gear": []}, ...],  -- 1 to 3
--    "aim": [-450, -420, ...]}  -- the owner's recent launch angles (tenths of a degree)

create table public.ghost_lineups (
  user_id uuid primary key references auth.users (id) on delete cascade,
  lineup jsonb not null check (
    jsonb_typeof(lineup -> 'slots') = 'array'
    and jsonb_array_length(lineup -> 'slots') between 1 and 3
    and pg_column_size(lineup) <= 16384
  ),
  rules_version integer not null,
  updated_at timestamptz not null default now()
);

alter table public.ghost_lineups enable row level security;

create policy "lineups are readable by signed-in players"
  on public.ghost_lineups for select to authenticated using (true);
create policy "players set their own lineup"
  on public.ghost_lineups for insert to authenticated with check (user_id = auth.uid());
create policy "players change their own lineup"
  on public.ghost_lineups for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke all on public.ghost_lineups from anon, authenticated;
grant select, insert, update on public.ghost_lineups to authenticated;

create table public.ghost_fights (
  id bigint generated always as identity primary key,
  attacker_id uuid not null references auth.users (id) on delete cascade,
  defender_id uuid references auth.users (id) on delete set null,
  attacker_lineup jsonb not null,
  defender_lineup jsonb not null,
  rules_version integer not null,
  seed integer not null,
  -- started -> claimed (client reported) -> verified / rejected (server re-run)
  status text not null default 'started'
    check (status in ('started', 'claimed', 'verified', 'rejected', 'abandoned')),
  inputs jsonb,
  claimed_winner smallint check (claimed_winner in (-1, 0, 1)),
  claimed_hash text,
  attacker_delta integer not null default 0,
  defender_delta integer not null default 0,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create index ghost_fights_attacker on public.ghost_fights (attacker_id, started_at desc);
create index ghost_fights_defender on public.ghost_fights (defender_id, started_at desc);

alter table public.ghost_fights enable row level security;

-- Your attacks and the attacks on your defence (the "revenge" list).
create policy "players see fights they were in"
  on public.ghost_fights for select to authenticated
  using (attacker_id = auth.uid() or defender_id = auth.uid());

revoke all on public.ghost_fights from anon, authenticated;
grant select on public.ghost_fights to authenticated;

-- Trophy swing for a result. Placeholder numbers: the Ghost Arena design owns
-- the real curve (see /design/pvp.md); changing them only touches this one.
create function public.ghost_trophy_deltas(p_winner smallint, out attacker integer, out defender integer)
language sql immutable set search_path = '' as $$
  select case p_winner when 0 then 30 when 1 then -20 else 0 end,
         case p_winner when 0 then -15 when 1 then 10 else 0 end;
$$;

-- Applies a fight's result to both players' trophies (never below zero).
create function public.settle_ghost_fight(p_fight_id bigint, p_status text, p_winner smallint)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  f public.ghost_fights;
  d record;
begin
  select * into f from public.ghost_fights where id = p_fight_id for update;
  if f.status <> 'started' then
    return;
  end if;
  select * into d from public.ghost_trophy_deltas(p_winner);
  update public.profiles set trophies = greatest(0, trophies + d.attacker) where id = f.attacker_id;
  update public.profiles set trophies = greatest(0, trophies + d.defender) where id = f.defender_id;
  update public.ghost_fights
    set status = p_status, attacker_delta = d.attacker, defender_delta = d.defender,
        finished_at = now()
    where id = p_fight_id;
end;
$$;

revoke all on function public.settle_ghost_fight(bigint, text, smallint) from public, anon, authenticated;

-- Picks an opponent near the attacker's trophies, freezes both lineups and
-- hands back a server-chosen seed. Any of the attacker's fights still open
-- count as losses first, so quitting a losing fight never pays.
-- Returns null when nobody suitable has a lineup yet (the game then fights a
-- bot ghost offline).
create function public.start_ghost_fight(p_attacker_lineup jsonb)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  my_trophies integer;
  opp record;
  fight_id bigint;
  fight_seed integer := floor(random() * 2147483646)::integer + 1;
  open_fight bigint;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if jsonb_typeof(p_attacker_lineup -> 'rules') is distinct from 'number'
     or jsonb_typeof(p_attacker_lineup -> 'slots') is distinct from 'array'
     or jsonb_array_length(p_attacker_lineup -> 'slots') not between 1 and 3
     or pg_column_size(p_attacker_lineup) > 16384 then
    raise exception 'bad lineup' using errcode = '22023';
  end if;

  for open_fight in
    select id from public.ghost_fights where attacker_id = me and status = 'started'
  loop
    perform public.settle_ghost_fight(open_fight, 'abandoned', 1::smallint);
  end loop;

  select trophies into my_trophies from public.profiles where id = me;

  -- Nearest trophies first, with some jitter. Anyone fought in the last five
  -- fights goes to the back of the queue (not out of it: early on there may
  -- only be a handful of lineups).
  select l.user_id, l.lineup, p.display_name, p.trophies into opp
  from public.ghost_lineups l
  join public.profiles p on p.id = l.user_id
  where l.user_id <> me
    and l.rules_version = (p_attacker_lineup ->> 'rules')::integer
  order by
    l.user_id in (
      select defender_id from public.ghost_fights
      where attacker_id = me and defender_id is not null
      order by started_at desc limit 5),
    abs(p.trophies - coalesce(my_trophies, 0)) + floor(random() * 100)
  limit 1;

  if not found then
    return null;
  end if;

  insert into public.ghost_fights
    (attacker_id, defender_id, attacker_lineup, defender_lineup, rules_version, seed)
  values (me, opp.user_id, p_attacker_lineup, opp.lineup,
          (p_attacker_lineup ->> 'rules')::integer, fight_seed)
  returning id into fight_id;

  return jsonb_build_object(
    'fight_id', fight_id, 'seed', fight_seed,
    'defender', jsonb_build_object('name', opp.display_name, 'trophies', opp.trophies, 'lineup', opp.lineup));
end;
$$;

revoke all on function public.start_ghost_fight(jsonb) from public, anon;
grant execute on function public.start_ghost_fight(jsonb) to authenticated;

-- The client reports its inputs and result. Trophies move now; a later
-- server re-run of the sim can mark the fight verified or rejected.
create function public.finish_ghost_fight(p_fight_id bigint, p_inputs jsonb, p_winner smallint, p_hash text)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  f public.ghost_fights;
begin
  select * into f from public.ghost_fights where id = p_fight_id and attacker_id = me;
  if f.id is null or f.status <> 'started' then
    raise exception 'no open fight with that id' using errcode = '22023';
  end if;
  if p_winner not in (-1, 0, 1) then
    raise exception 'bad winner' using errcode = '22023';
  end if;
  update public.ghost_fights
    set inputs = p_inputs, claimed_winner = p_winner, claimed_hash = left(p_hash, 64)
    where id = p_fight_id;
  perform public.settle_ghost_fight(p_fight_id, 'claimed', p_winner);
  select * into f from public.ghost_fights where id = p_fight_id;
  return jsonb_build_object(
    'attacker_delta', f.attacker_delta,
    'trophies', (select trophies from public.profiles where id = me));
end;
$$;

revoke all on function public.finish_ghost_fight(bigint, jsonb, smallint, text) from public, anon;
grant execute on function public.finish_ghost_fight(bigint, jsonb, smallint, text) to authenticated;
