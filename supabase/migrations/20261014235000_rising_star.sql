-- Rising Star (meta/rising_star.gd): new accounts earn bonus XP until they
-- reach the median level of recently active players. The game asks for that
-- median here; nothing about a player's own XP is decided on the server.
--
-- The level comes from the cloud save (data.profile.account_level), so only
-- signed-in players who played in the last 14 days count. Values are clamped
-- so one tampered save can't move the median, and the median is withheld
-- (null) until enough players are active to mean something; the game then
-- keeps its cached value or its built-in fallback.

create index if not exists saves_updated_at on public.saves (updated_at);

create function public.rising_star_median()
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  min_players constant integer := 20;
  n integer;
  med numeric;
  joined timestamptz;
begin
  select count(*), percentile_cont(0.5) within group (order by lvl)
    into n, med
  from (
    select least(greatest((s.data -> 'profile' ->> 'account_level')::integer, 1), 999) as lvl
    from public.saves s
    where s.updated_at > now() - interval '14 days'
      and jsonb_typeof(s.data -> 'profile' -> 'account_level') = 'number'
  ) levels;
  select p.created_at into joined from public.profiles p where p.id = auth.uid();
  return jsonb_build_object(
    'median', case when n >= min_players then round(med)::integer end,
    'players', n,
    'joined', floor(extract(epoch from joined))::bigint
  );
end;
$$;

revoke all on function public.rising_star_median() from public, anon;
grant execute on function public.rising_star_median() to authenticated;
