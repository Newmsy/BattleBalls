-- Bounce Run grows to 25 floors (Newms 2026-10-26, rules 13). A run on
-- rules 13 or later clears on floor 25; older runs keep their own top floor.
-- Everything else is as in 20261025110000_bounce_run_best_of_day.

create or replace function public.submit_bounce_run(
  p_day integer, p_floors integer, p_lives integer, p_ticks integer, p_log jsonb, p_rules integer
) returns table (rank bigint, total bigint)
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  map boolean := p_rules >= 7;
  top integer := case when p_rules >= 13 then 25 when p_rules >= 7 then 20 when p_rules >= 2 then 10 else 8 end; -- floors in that rules version
  fights integer;
  ok boolean;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  -- A run may finish just after midnight UTC, or on a clock a little ahead.
  if p_day not between public.bounce_run_today() - 1 and public.bounce_run_today() + 1 then
    raise exception 'not a current Bounce Run day' using errcode = '22023';
  end if;
  if jsonb_typeof(p_log -> 'fights') <> 'array' then
    raise exception 'impossible Bounce Run score' using errcode = '22023';
  end if;
  if map then
    select count(*) into fights from jsonb_array_elements(p_log -> 'fights') e where e ->> 't' = 'fight';
  else
    fights := jsonb_array_length(p_log -> 'fights');
  end if;
  -- Possible scores only: a run ends with the top floor or with no lives,
  -- every fight takes at least a second and at most the 120s time limit.
  ok := p_floors between 0 and top and p_lives between 0 and 3
    and not (p_floors < top and p_lives > 0) and not (p_floors = top and p_lives = 0)
    and p_ticks between fights * 60 and fights * 7201;
  if map then
    -- At least one loss per critter lost, and at most a few fights a floor.
    ok := ok and fights >= 3 - p_lives and fights <= 3 * p_floors + 6;
  else
    ok := ok and fights = p_floors + 3 - p_lives; -- wins plus losses
  end if;
  if not ok then
    raise exception 'impossible Bounce Run score' using errcode = '22023';
  end if;
  insert into public.bounce_run_scores (day, user_id, floors, lives, ticks, run_log, rules_version)
  values (p_day, me, p_floors, p_lives, p_ticks, p_log, p_rules)
  on conflict (day, user_id) do update
    set floors = excluded.floors, lives = excluded.lives, ticks = excluded.ticks,
        run_log = excluded.run_log, rules_version = excluded.rules_version, status = 'claimed'
    where (excluded.floors, excluded.lives, -excluded.ticks)
      > (public.bounce_run_scores.floors, public.bounce_run_scores.lives, -public.bounce_run_scores.ticks);
  return query
    select count(*) filter (where (s.floors, s.lives, -s.ticks) > (m.floors, m.lives, -m.ticks)) + 1, count(*)
    from public.bounce_run_scores s, public.bounce_run_scores m
    where s.day = p_day and m.day = p_day and m.user_id = me and s.status <> 'rejected';
end;
$$;
