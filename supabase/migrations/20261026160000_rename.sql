-- Player names: a player renames themselves from the Account screen. The
-- name goes through set_display_name so the rules below can't be skipped by
-- writing the column directly. Free, no cooldown. Arena opponents, friends
-- and leaderboards read profiles.display_name, so they show it straight away.
--
-- Rules (game/online/account.gd check_name mirrors them for instant feedback):
-- 3-16 characters after trimming and collapsing spaces; letters, digits,
-- spaces, '-', '_' and '.'; at least one letter; no rude words (a light list:
-- substrings that hide inside nothing innocent, whole words for the rest).

revoke update (display_name) on public.profiles from authenticated;

create function public.name_problem(p_name text) returns text
language plpgsql immutable set search_path = '' as $$
declare
  squashed text;
  words text[];
  w text;
begin
  if p_name is null or char_length(p_name) < 3 then
    return 'too_short';
  end if;
  if char_length(p_name) > 16 then
    return 'too_long';
  end if;
  if p_name !~ '^[A-Za-z0-9 ._-]+$' then
    return 'bad_chars';
  end if;
  if p_name !~ '[A-Za-z]' then
    return 'no_letters';
  end if;
  -- Undo the usual l33t swaps, then check with and without the gaps.
  squashed := translate(lower(p_name), '013457$@', 'oieastsa');
  words := regexp_split_to_array(squashed, '[^a-z]+');
  squashed := regexp_replace(squashed, '[^a-z]', '', 'g');
  foreach w in array array['fuck', 'fuk', 'shit', 'cunt', 'nigg', 'nigga', 'fagg', 'bitch', 'whore',
      'slut', 'penis', 'vagina', 'porn', 'pussy', 'twat', 'wank', 'retard', 'kike', 'chink',
      'hitler', 'nazi', 'rapist', 'dildo', 'cumshot', 'jizz', 'boob', 'molest'] loop
    if position(w in squashed) > 0 then
      return 'rude';
    end if;
  end loop;
  foreach w in array words loop
    if w = any (array['ass', 'arse', 'fag', 'cum', 'cock', 'dick', 'tit', 'tits', 'sex', 'rape',
        'spic', 'coon', 'homo', 'anal', 'admin', 'moderator', 'mod', 'staff', 'battleballs', 'official']) then
      return 'rude';
    end if;
  end loop;
  return null;
end;
$$;

grant execute on function public.name_problem(text) to authenticated;

-- Returns the saved name. Errors carry the reason from name_problem in the
-- message ("name: too_short") so the client can explain it.
create function public.set_display_name(p_name text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  clean text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  problem text;
begin
  if me is null then
    raise exception 'signed out' using errcode = '28000';
  end if;
  problem := public.name_problem(clean);
  if problem is not null then
    raise exception 'name: %', problem using errcode = '22023';
  end if;
  update public.profiles set display_name = clean where id = me;
  return clean;
end;
$$;

revoke all on function public.set_display_name(text) from public, anon;
grant execute on function public.set_display_name(text) to authenticated;
