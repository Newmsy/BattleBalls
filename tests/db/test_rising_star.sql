-- Rising Star: the median account level of recently active players.
-- Runs after test_backend.sql and test_friends.sql (alice has a save with no profile).

\set alice '''aaaaaaaa-0000-0000-0000-000000000001'''

reset role;
-- Too few players: the median is withheld.
set role authenticated;
select tests.as_user(:alice);
do $$
declare r jsonb := public.rising_star_median();
begin
  assert r -> 'median' = 'null'::jsonb, 'no median from a handful of players: ' || r::text;
  assert (r ->> 'joined')::bigint > 0, 'the caller''s join date comes back';
end $$;

-- 24 active players at levels 1-24, one tampered save and one stale player.
reset role;
insert into auth.users (id)
  select ('7a7a7a7a-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid from generate_series(1, 26) i;
insert into public.saves (user_id, rev, data, updated_at)
  select ('7a7a7a7a-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid, 1,
         jsonb_build_object('profile', jsonb_build_object('account_level', case when i = 25 then 99999 else i end)),
         case when i = 26 then now() - interval '30 days' else now() end
  from generate_series(1, 26) i;

set role authenticated;
select tests.as_user(:alice);
do $$
declare r jsonb := public.rising_star_median();
begin
  assert (r ->> 'players')::integer = 25, 'only active saves with a level count: ' || r::text;
  assert (r ->> 'median')::integer = 13, 'median of 1-24 plus a clamped outlier: ' || r::text;
end $$;

-- Guests without a session can't call it.
set role anon;
do $$ begin
  begin
    perform public.rising_star_median();
    assert false, 'anon should not call rising_star_median';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
