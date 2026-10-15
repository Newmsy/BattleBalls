-- Bounce Run rules 2: the tower is 10 floors (sim/bounce_run.gd FLOORS), with
-- foes that start easy and end tougher than you. Rules 1 runs (8 floors) from
-- clients that haven't updated still post.

alter table public.bounce_run_scores drop constraint bounce_run_scores_floors_check;
alter table public.bounce_run_scores add constraint bounce_run_scores_floors_check check (floors between 0 and 10);

create or replace function public.submit_bounce_run(
  p_day integer, p_floors integer, p_lives integer, p_ticks integer, p_log jsonb, p_rules integer
) returns table (rank bigint, total bigint)
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  fights integer := p_floors + 3 - p_lives; -- wins plus losses
  top integer := case when p_rules >= 2 then 10 else 8 end; -- floors in that rules version
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
  if p_floors not between 0 and top or p_lives not between 0 and 3
     or (p_floors < top and p_lives > 0) or (p_floors = top and p_lives = 0)
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
