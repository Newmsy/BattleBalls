-- The live project already has this migration's objects: it ran there under
-- its old file name before the rename that unblocked `supabase db push`
-- (PR #64). So it only runs where they're missing (a fresh database).
do $mig$ begin
if to_regclass('public.bounce_run_scores') is not null then
  return;
end if;
execute $body$
-- Bounce Run daily leaderboard (game/online/bounce_board.gd, design/bounce-run.md).
--
-- One score per player per day, posted once at the end of the ranked run and
-- never overwritten. Scores are claims: the sim is deterministic, so the run
-- log (picks, boons, fighter and aim per fight) lets a verifier re-run any
-- score later and mark it verified or rejected. Until then the server only
-- checks that a score is possible.

create table public.bounce_run_scores (
  day integer not null check (day >= 1),
  user_id uuid not null references auth.users (id) on delete cascade,
  floors smallint not null check (floors between 0 and 8),
  lives smallint not null check (lives between 0 and 3),
  ticks integer not null check (ticks >= 0),
  run_log jsonb not null check (pg_column_size(run_log) <= 16384),
  rules_version integer not null,
  status text not null default 'claimed' check (status in ('claimed', 'verified', 'rejected')),
  created_at timestamptz not null default now(),
  primary key (day, user_id)
);

create index bounce_run_scores_board on public.bounce_run_scores (day, floors desc, lives desc, ticks asc, created_at asc);

-- Read and written only through the functions below.
alter table public.bounce_run_scores enable row level security;
revoke all on public.bounce_run_scores from anon, authenticated;

-- Bounce Run #1 is 2026-10-14 (UTC); sim/bounce_run.gd uses the same epoch.
create function public.bounce_run_today() returns integer
language sql stable set search_path = '' as $$
  select floor((extract(epoch from now()) - 1791936000) / 86400)::integer + 1
$$;

-- Posts a finished run. The first post of a day stands; repeats are no-ops.
-- Returns the player's rank that day and how many players have posted.
create function public.submit_bounce_run(
  p_day integer, p_floors integer, p_lives integer, p_ticks integer, p_log jsonb, p_rules integer
) returns table (rank bigint, total bigint)
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  fights integer := p_floors + 3 - p_lives; -- wins plus losses
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  -- A run may finish just after midnight UTC, or on a clock a little ahead.
  if p_day not between public.bounce_run_today() - 1 and public.bounce_run_today() + 1 then
    raise exception 'not a current Bounce Run day' using errcode = '22023';
  end if;
  -- Possible scores only: a run ends with the top floor or with no lives,
  -- every fight takes at least a second and at most the 120s time limit.
  if p_floors not between 0 and 8 or p_lives not between 0 and 3
     or (p_floors < 8 and p_lives > 0) or (p_floors = 8 and p_lives = 0)
     or p_ticks < fights * 60 or p_ticks > fights * 7201
     or jsonb_typeof(p_log -> 'fights') <> 'array' or jsonb_array_length(p_log -> 'fights') <> fights then
    raise exception 'impossible Bounce Run score' using errcode = '22023';
  end if;
  insert into public.bounce_run_scores (day, user_id, floors, lives, ticks, run_log, rules_version)
  values (p_day, me, p_floors, p_lives, p_ticks, p_log, p_rules)
  on conflict (day, user_id) do nothing;
  return query
    select count(*) filter (where (s.floors, s.lives, -s.ticks) > (m.floors, m.lives, -m.ticks)) + 1, count(*)
    from public.bounce_run_scores s, public.bounce_run_scores m
    where s.day = p_day and m.day = p_day and m.user_id = me and s.status <> 'rejected';
end;
$$;

-- The day's top p_limit plus the caller's own row, best first.
create function public.bounce_run_board(p_day integer, p_limit integer default 20)
returns table (rank bigint, display_name text, floors smallint, lives smallint, ticks integer, is_me boolean)
language sql stable security definer set search_path = '' as $$
  with ranked as (
    select rank() over (order by s.floors desc, s.lives desc, s.ticks asc) as rank,
           coalesce(p.display_name, 'Guest') as display_name, s.floors, s.lives, s.ticks,
           s.user_id = auth.uid() as is_me, s.created_at
    from public.bounce_run_scores s
    left join public.profiles p on p.id = s.user_id
    where s.day = p_day and s.status <> 'rejected'
  )
  select r.rank, r.display_name, r.floors, r.lives, r.ticks, r.is_me from ranked r
  where r.rank <= least(greatest(p_limit, 1), 100) or r.is_me
  order by r.rank, r.created_at
$$;

revoke all on function public.bounce_run_today() from public;
revoke all on function public.submit_bounce_run(integer, integer, integer, integer, jsonb, integer) from public, anon;
revoke all on function public.bounce_run_board(integer, integer) from public, anon;
grant execute on function public.bounce_run_today() to authenticated;
grant execute on function public.submit_bounce_run(integer, integer, integer, integer, jsonb, integer) to authenticated;
grant execute on function public.bounce_run_board(integer, integer) to authenticated;

$body$;
end $mig$;
