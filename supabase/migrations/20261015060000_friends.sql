-- The live project already has this migration's objects: it ran there under
-- its old file name before the rename that unblocked `supabase db push`
-- (PR #64). So it only runs where they're missing (a fresh database).
do $mig$ begin
if to_regclass('public.friendships') is not null then
  return;
end if;
execute $body$
-- Friends v1: friend codes, requests, energy gifts, preset pings and rival
-- records (re-fighting a friend's saved Ghost Arena lineup, unranked).
--
-- Same security model as the first migration: players can read their own rows,
-- and every write goes through a SECURITY DEFINER function that checks the
-- caller is allowed to make it. Chat is preset phrases only (no free text), so
-- there is nothing to moderate. Energy gifts are free and capped, never sold.

-- Friend codes ----------------------------------------------------------------
-- 8 characters without look-alikes (no 0/O, 1/I/L), shown as ABCD-EFGH.

create function public.new_friend_code() returns text
language sql volatile set search_path = '' as $$
  select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + floor(random() * 31)::integer, 1), '')
  from generate_series(1, 8);
$$;

alter table public.profiles add column friend_code text;
update public.profiles set friend_code = public.new_friend_code() where friend_code is null;
alter table public.profiles
  alter column friend_code set default public.new_friend_code(),
  alter column friend_code set not null,
  add constraint profiles_friend_code_key unique (friend_code);

-- Friendships -----------------------------------------------------------------
-- One row per pair, stored with a < b. A request is a row with accepted_at null.

create table public.friendships (
  a uuid not null references auth.users (id) on delete cascade,
  b uuid not null references auth.users (id) on delete cascade,
  requested_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  primary key (a, b),
  check (a < b),
  check (requested_by in (a, b))
);

create index friendships_b on public.friendships (b);

alter table public.friendships enable row level security;
create policy "players see their own friendships"
  on public.friendships for select to authenticated
  using (a = auth.uid() or b = auth.uid());
revoke all on public.friendships from anon, authenticated;
grant select on public.friendships to authenticated;

create function public.are_friends(p_one uuid, p_two uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select from public.friendships
    where a = least(p_one, p_two) and b = greatest(p_one, p_two) and accepted_at is not null);
$$;
revoke all on function public.are_friends(uuid, uuid) from public, anon, authenticated;

create function public.utc_today() returns date
language sql stable set search_path = '' as $$
  select (now() at time zone 'utc')::date;
$$;

-- Energy gifts ----------------------------------------------------------------
-- Each friend can send you one gift a UTC day; you can claim up to 10 a day.
-- Unclaimed gifts last 3 days. The amount is decided here, not by the client.

create table public.energy_gifts (
  from_id uuid not null references auth.users (id) on delete cascade,
  to_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  claimed_at timestamptz,
  primary key (from_id, to_id, day)
);

create index energy_gifts_to on public.energy_gifts (to_id, day);

alter table public.energy_gifts enable row level security;
create policy "players see gifts they sent or got"
  on public.energy_gifts for select to authenticated
  using (from_id = auth.uid() or to_id = auth.uid());
revoke all on public.energy_gifts from anon, authenticated;
grant select on public.energy_gifts to authenticated;

-- Pings: preset phrases ---------------------------------------------------------
-- Only the latest ping per direction is kept. `preset` indexes a fixed list in
-- the game (game/online/friends.gd PRESETS), so no player text is ever stored.

create table public.friend_pings (
  from_id uuid not null references auth.users (id) on delete cascade,
  to_id uuid not null references auth.users (id) on delete cascade,
  preset smallint not null check (preset between 0 and 15),
  sent_at timestamptz not null default now(),
  primary key (from_id, to_id)
);

alter table public.friend_pings enable row level security;
create policy "players see pings they sent or got"
  on public.friend_pings for select to authenticated
  using (from_id = auth.uid() or to_id = auth.uid());
revoke all on public.friend_pings from anon, authenticated;
grant select on public.friend_pings to authenticated;

-- Rival records -------------------------------------------------------------------
-- Your results attacking a friend's saved lineup. Unranked: no trophies or
-- rewards move, so a client-reported result is fine here.

create table public.rival_records (
  attacker_id uuid not null references auth.users (id) on delete cascade,
  defender_id uuid not null references auth.users (id) on delete cascade,
  wins integer not null default 0,
  losses integer not null default 0,
  draws integer not null default 0,
  last_at timestamptz not null default now(),
  primary key (attacker_id, defender_id)
);

alter table public.rival_records enable row level security;
create policy "players see rival records they are in"
  on public.rival_records for select to authenticated
  using (attacker_id = auth.uid() or defender_id = auth.uid());
revoke all on public.rival_records from anon, authenticated;
grant select on public.rival_records to authenticated;

-- RPCs ------------------------------------------------------------------------------

-- Add a friend by code. Sends a request, or accepts theirs if they already
-- asked. Returns {status, friend: {id, name}} where status is one of
-- requested, friends, already, not_found, self, full.
create function public.add_friend(p_code text)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  them public.profiles;
  link public.friendships;
  who jsonb;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  select * into them from public.profiles where friend_code = code;
  if them.id is null then
    return jsonb_build_object('status', 'not_found');
  end if;
  who := jsonb_build_object('id', them.id, 'name', them.display_name);
  if them.id = me then
    return jsonb_build_object('status', 'self', 'friend', who);
  end if;
  select * into link from public.friendships where a = least(me, them.id) and b = greatest(me, them.id) for update;
  if link.a is not null then
    if link.accepted_at is not null or link.requested_by = me then
      return jsonb_build_object('status', 'already', 'friend', who);
    end if;
    update public.friendships set accepted_at = now() where a = link.a and b = link.b;
    return jsonb_build_object('status', 'friends', 'friend', who);
  end if;
  -- Caps keep a spammed code harmless: 100 friends, 30 open requests either way.
  if (select count(*) from public.friendships where (a = me or b = me) and accepted_at is not null) >= 100
     or (select count(*) from public.friendships where requested_by = me and accepted_at is null) >= 30
     or (select count(*) from public.friendships
         where (a = them.id or b = them.id) and requested_by <> them.id and accepted_at is null) >= 30 then
    return jsonb_build_object('status', 'full', 'friend', who);
  end if;
  insert into public.friendships (a, b, requested_by) values (least(me, them.id), greatest(me, them.id), me);
  return jsonb_build_object('status', 'requested', 'friend', who);
end;
$$;
revoke all on function public.add_friend(text) from public, anon;
grant execute on function public.add_friend(text) to authenticated;

-- Accept or decline a request someone sent you.
create function public.answer_friend(p_friend uuid, p_accept boolean)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_accept then
    update public.friendships set accepted_at = now()
    where a = least(me, p_friend) and b = greatest(me, p_friend)
      and requested_by = p_friend and accepted_at is null;
  else
    delete from public.friendships
    where a = least(me, p_friend) and b = greatest(me, p_friend)
      and requested_by = p_friend and accepted_at is null;
  end if;
  return found;
end;
$$;
revoke all on function public.answer_friend(uuid, boolean) from public, anon;
grant execute on function public.answer_friend(uuid, boolean) to authenticated;

-- Unfriend, or cancel a request you sent. Pings go too; records stay.
create function public.remove_friend(p_friend uuid)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  removed boolean;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  delete from public.friendships where a = least(me, p_friend) and b = greatest(me, p_friend);
  removed := found;
  delete from public.friend_pings
  where (from_id = me and to_id = p_friend) or (from_id = p_friend and to_id = me);
  return removed;
end;
$$;
revoke all on function public.remove_friend(uuid) from public, anon;
grant execute on function public.remove_friend(uuid) to authenticated;

-- Everything the Friends screen shows, in one call.
-- {me: {name, code}, gifts_claimable, friends: [{id, name, code, state
-- (friends / incoming / outgoing), trophies, lineup, gift_sent, gift_waiting,
-- ping: {preset, at} | null, record: {wins, losses, draws}}]}
create function public.friends_overview()
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  today date := public.utc_today();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  return jsonb_build_object(
    'me', (select jsonb_build_object('name', display_name, 'code', friend_code) from public.profiles where id = me),
    'gift_energy', 2,
    'gifts_claimable', (select count(*) from public.energy_gifts
                        where to_id = me and claimed_at is null and day > today - 3),
    'friends', coalesce((
      select jsonb_agg(x.item order by x.rank, x.name)
      from (
        select p.display_name as name,
          case when f.accepted_at is null and f.requested_by <> me then 0
               when f.accepted_at is not null then 1 else 2 end as rank,
          jsonb_build_object(
            'id', p.id,
            'name', p.display_name,
            'code', p.friend_code,
            'state', case when f.accepted_at is not null then 'friends'
                          when f.requested_by = me then 'outgoing' else 'incoming' end,
            'trophies', p.trophies,
            'lineup', case when f.accepted_at is not null then
              (select l.lineup from public.ghost_lineups l where l.user_id = p.id) end,
            'gift_sent', exists (select from public.energy_gifts g
                                 where g.from_id = me and g.to_id = p.id and g.day = today),
            'gift_waiting', exists (select from public.energy_gifts g
                                    where g.from_id = p.id and g.to_id = me and g.claimed_at is null and g.day > today - 3),
            'ping', (select jsonb_build_object('preset', fp.preset, 'at', fp.sent_at)
                     from public.friend_pings fp where fp.from_id = p.id and fp.to_id = me),
            'record', coalesce((select jsonb_build_object('wins', r.wins, 'losses', r.losses, 'draws', r.draws)
                                from public.rival_records r where r.attacker_id = me and r.defender_id = p.id),
                               '{"wins": 0, "losses": 0, "draws": 0}'::jsonb)
          ) as item
        from public.friendships f
        join public.profiles p on p.id = case when f.a = me then f.b else f.a end
        where f.a = me or f.b = me
      ) x), '[]'::jsonb));
end;
$$;
revoke all on function public.friends_overview() from public, anon;
grant execute on function public.friends_overview() to authenticated;

-- One gift per friend per UTC day. Returns false if already sent or not friends.
create function public.send_energy_gift(p_friend uuid)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if not public.are_friends(me, p_friend) then
    return false;
  end if;
  insert into public.energy_gifts (from_id, to_id, day) values (me, p_friend, public.utc_today())
  on conflict do nothing;
  return found;
end;
$$;
revoke all on function public.send_energy_gift(uuid) from public, anon;
grant execute on function public.send_energy_gift(uuid) to authenticated;

-- Claims waiting gifts, at most 10 per UTC day. Returns {gifts, energy}: the
-- game adds `energy` to the bar (it may go over the max, like other rewards).
create function public.claim_energy_gifts()
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  today date := public.utc_today();
  room integer;
  n integer;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  room := 10 - (select count(*) from public.energy_gifts
                where to_id = me and (claimed_at at time zone 'utc')::date = today);
  if room <= 0 then
    return jsonb_build_object('gifts', 0, 'energy', 0);
  end if;
  with claimable as (
    select from_id, to_id, day from public.energy_gifts
    where to_id = me and claimed_at is null and day > today - 3
    order by day, from_id
    limit room
    for update
  )
  update public.energy_gifts g set claimed_at = now()
  from claimable c
  where g.from_id = c.from_id and g.to_id = c.to_id and g.day = c.day;
  get diagnostics n = row_count;
  return jsonb_build_object('gifts', n, 'energy', n * 2);
end;
$$;
revoke all on function public.claim_energy_gifts() from public, anon;
grant execute on function public.claim_energy_gifts() to authenticated;

-- Send a preset phrase to a friend. At most one every 10 seconds per friend.
create function public.send_friend_ping(p_friend uuid, p_preset smallint)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_preset not between 0 and 15 or not public.are_friends(me, p_friend) then
    return false;
  end if;
  insert into public.friend_pings as fp (from_id, to_id, preset) values (me, p_friend, p_preset)
  on conflict (from_id, to_id) do update set preset = excluded.preset, sent_at = now()
    where fp.sent_at < now() - interval '10 seconds';
  return found;
end;
$$;
revoke all on function public.send_friend_ping(uuid, smallint) from public, anon;
grant execute on function public.send_friend_ping(uuid, smallint) to authenticated;

-- Record a rival fight against a friend's lineup: p_winner 0 = you won,
-- 1 = they won, -1 = draw. Returns your record against them.
create function public.record_rival_fight(p_friend uuid, p_winner smallint)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  r public.rival_records;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_winner not in (-1, 0, 1) or not public.are_friends(me, p_friend) then
    return null;
  end if;
  insert into public.rival_records as rr (attacker_id, defender_id, wins, losses, draws)
  values (me, p_friend, (p_winner = 0)::integer, (p_winner = 1)::integer, (p_winner = -1)::integer)
  on conflict (attacker_id, defender_id) do update
    set wins = rr.wins + excluded.wins, losses = rr.losses + excluded.losses,
        draws = rr.draws + excluded.draws, last_at = now()
  returning * into r;
  return jsonb_build_object('wins', r.wins, 'losses', r.losses, 'draws', r.draws);
end;
$$;
revoke all on function public.record_rival_fight(uuid, smallint) from public, anon;
grant execute on function public.record_rival_fight(uuid, smallint) to authenticated;

$body$;
end $mig$;
