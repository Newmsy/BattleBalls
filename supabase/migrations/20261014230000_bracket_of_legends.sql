-- Bracket of Legends picks (game/legends.gd).
--
-- The bracket itself needs no server: every device works it out from the
-- seed and entrant list in liveops/liveops.json. The server only keeps each
-- player's champion pick, stamped with the server's clock, so picks made
-- after an event locks can be told apart when picks are scored or ranked.

create table public.bracket_predictions (
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id text not null check (char_length(event_id) between 1 and 64),
  champion text not null check (champion ~ '^[a-z_]{1,32}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create index bracket_predictions_event on public.bracket_predictions (event_id, champion);

alter table public.bracket_predictions enable row level security;

create policy "players read their own picks"
  on public.bracket_predictions for select to authenticated using (user_id = auth.uid());

revoke all on public.bracket_predictions from anon, authenticated;
grant select on public.bracket_predictions to authenticated;

-- Picks (or changes) the champion for an event. Times come from the server.
create function public.predict_bracket(p_event text, p_champion text)
returns public.bracket_predictions
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  result public.bracket_predictions;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if p_event is null or char_length(p_event) not between 1 and 64
     or p_champion is null or p_champion !~ '^[a-z_]{1,32}$' then
    raise exception 'bad pick' using errcode = '22023';
  end if;
  insert into public.bracket_predictions as p (user_id, event_id, champion)
  values (me, p_event, p_champion)
  on conflict (user_id, event_id) do update
    set champion = excluded.champion, updated_at = now();
  select * into result from public.bracket_predictions where user_id = me and event_id = p_event;
  return result;
end;
$$;

revoke all on function public.predict_bracket(text, text) from public, anon;
grant execute on function public.predict_bracket(text, text) to authenticated;

-- How many players picked each champion: counts only, never who.
create function public.bracket_pick_shares(p_event text)
returns table (champion text, picks bigint)
language sql stable security definer set search_path = '' as $$
  select p.champion, count(*) from public.bracket_predictions p
  where p.event_id = p_event
  group by p.champion
  order by count(*) desc, p.champion;
$$;

revoke all on function public.bracket_pick_shares(text) from public, anon;
grant execute on function public.bracket_pick_shares(text) to authenticated;
