-- Ghost Arena defences (Newms 2026-10-26): each player's saved Defence trio
-- and the Arena trophies it was saved at, so other players meet real squads,
-- with their names, mixed in with the seeded teams. Arena trophies live on the
-- device (user://ghost_arena.cfg) and come up with the squad; a fight against
-- a squad replays from the lineup alone, so nothing else is needed to play it.

create table public.arena_defences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  lineup jsonb not null check (
    jsonb_typeof(lineup -> 'slots') = 'array'
    and jsonb_array_length(lineup -> 'slots') = 3
    and pg_column_size(lineup) <= 16384
  ),
  rules_version integer not null,
  trophies integer not null default 0 check (trophies between 0 and 20000),
  power integer not null default 0 check (power between 0 and 1000000),
  updated_at timestamptz not null default now()
);

create index arena_defences_near on public.arena_defences (rules_version, trophies);

alter table public.arena_defences enable row level security;

create policy "players read their own defence"
  on public.arena_defences for select to authenticated using (user_id = auth.uid());
create policy "players set their own defence"
  on public.arena_defences for insert to authenticated with check (user_id = auth.uid());
create policy "players change their own defence"
  on public.arena_defences for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke all on public.arena_defences from anon, authenticated;
grant select, insert, update on public.arena_defences to authenticated;

-- Up to p_count (at most 10) other players' squads nearest p_trophies, with a
-- little jitter so the same few don't always come back, from players seen in
-- the last 30 days on the caller's sim rules:
-- [{id, name, trophies, power, lineup}], nearest first.
create function public.arena_opponents(p_trophies integer, p_rules integer, p_count integer default 5)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', d.user_id, 'name', p.display_name, 'trophies', d.trophies,
      'power', d.power, 'lineup', d.lineup) order by d.gap), '[]'::jsonb)
  from (
    select user_id, lineup, trophies, power,
           abs(trophies - p_trophies) + floor(random() * 150) as gap
    from public.arena_defences
    where user_id is distinct from auth.uid()
      and rules_version = p_rules
      and updated_at > now() - interval '30 days'
    order by gap
    limit least(greatest(p_count, 0), 10)
  ) d
  join public.profiles p on p.id = d.user_id
$$;

revoke all on function public.arena_opponents(integer, integer, integer) from public, anon;
grant execute on function public.arena_opponents(integer, integer, integer) to authenticated;
