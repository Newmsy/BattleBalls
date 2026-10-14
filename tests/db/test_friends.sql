-- Friends v1: codes, requests, gifts, pings and rival records.
-- Runs after test_backend.sql, which created alice, bob and cara.

\set alice '''aaaaaaaa-0000-0000-0000-000000000001'''
\set bob   '''bbbbbbbb-0000-0000-0000-000000000002'''
\set cara  '''cccccccc-0000-0000-0000-000000000003'''

-- Everyone has a distinct 8-character code without look-alike characters.
do $$ begin
  assert (select count(distinct friend_code) from public.profiles) = (select count(*) from public.profiles), 'unique codes';
  assert (select bool_and(friend_code ~ '^[A-HJKMNP-Z2-9]{8}$') from public.profiles), 'code alphabet';
end $$;

-- Friend codes are not editable.
set role authenticated;
select tests.as_user(:alice);
do $$ begin
  begin
    update public.profiles set friend_code = 'AAAAAAAA' where id = auth.uid();
    assert false, 'friend code should not be writable';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Alice asks Bob (typed loosely), Bob accepts by adding her back.
do $$
declare
  bob_code text := (select friend_code from public.profiles where id = 'bbbbbbbb-0000-0000-0000-000000000002');
  res jsonb;
begin
  assert public.add_friend('nope') ->> 'status' = 'not_found', 'unknown code';
  assert public.add_friend((select friend_code from public.profiles where id = auth.uid())) ->> 'status' = 'self', 'self';
  res := public.add_friend(lower(left(bob_code, 4) || '-' || right(bob_code, 4)));
  assert res ->> 'status' = 'requested', 'request sent: ' || res::text;
  assert res -> 'friend' ->> 'name' = 'Bobby', 'name comes back';
  assert public.add_friend(bob_code) ->> 'status' = 'already', 'no double request';
  assert (public.friends_overview() -> 'friends' -> 0 ->> 'state') = 'outgoing', 'alice sees outgoing';
  -- Not friends yet: no gifts, pings or records.
  assert not public.send_energy_gift('bbbbbbbb-0000-0000-0000-000000000002'), 'no gift before accepting';
  assert not public.send_friend_ping('bbbbbbbb-0000-0000-0000-000000000002', 1::smallint), 'no ping before accepting';
end $$;

select tests.as_user(:bob);
do $$
declare
  ov jsonb := public.friends_overview();
begin
  assert ov -> 'friends' -> 0 ->> 'state' = 'incoming', 'bob sees incoming';
  assert ov -> 'friends' -> 0 -> 'lineup' = 'null'::jsonb, 'no lineup before accepting';
  assert public.add_friend((select friend_code from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001')) ->> 'status' = 'friends',
    'adding back accepts';
  ov := public.friends_overview();
  assert ov -> 'friends' -> 0 ->> 'state' = 'friends', 'now friends';
  assert ov -> 'friends' -> 0 -> 'lineup' -> 'slots' -> 0 ->> 'critter' = 'vampire', 'friend lineup visible';
  assert ov -> 'me' ->> 'name' = 'Bobby', 'me';
end $$;

-- Gifts: once a day per friend; claimable by the receiver only.
do $$ begin
  assert public.send_energy_gift('aaaaaaaa-0000-0000-0000-000000000001'), 'gift sent';
  assert not public.send_energy_gift('aaaaaaaa-0000-0000-0000-000000000001'), 'one a day';
  assert (public.claim_energy_gifts() ->> 'gifts')::int = 0, 'sender claims nothing';
  assert public.friends_overview() -> 'friends' -> 0 ->> 'gift_sent' = 'true', 'sent shows';
end $$;

select tests.as_user(:alice);
do $$
declare res jsonb;
begin
  assert (public.friends_overview() ->> 'gifts_claimable')::int = 1, 'one waiting';
  assert public.friends_overview() -> 'friends' -> 0 ->> 'gift_waiting' = 'true', 'waiting shows';
  res := public.claim_energy_gifts();
  assert (res ->> 'gifts')::int = 1 and (res ->> 'energy')::int = 2, 'claimed: ' || res::text;
  assert (public.claim_energy_gifts() ->> 'gifts')::int = 0, 'claimed once';
end $$;

-- The daily claim cap is 10, and expired gifts can't be claimed.
reset role;
insert into auth.users (id) select ('dddddddd-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid from generate_series(10, 21) i;
insert into public.friendships (a, b, requested_by, accepted_at)
  select 'aaaaaaaa-0000-0000-0000-000000000001', id, id, now() from auth.users where id::text like 'dddddddd%';
insert into public.energy_gifts (from_id, to_id, day)
  select id, 'aaaaaaaa-0000-0000-0000-000000000001', public.utc_today() from auth.users where id::text like 'dddddddd%';
insert into public.energy_gifts (from_id, to_id, day)
  values ('dddddddd-0000-0000-0000-000000000010', 'aaaaaaaa-0000-0000-0000-000000000001', public.utc_today() - 5);
set role authenticated;
select tests.as_user(:alice);
do $$ begin
  assert (public.claim_energy_gifts() ->> 'gifts')::int = 9, '10 a day, one already claimed today';
  assert (public.claim_energy_gifts() ->> 'gifts')::int = 0, 'cap reached';
  assert (public.friends_overview() ->> 'gifts_claimable')::int = 3, 'the rest wait (old one expired)';
end $$;

-- Pings: preset index only, rate limited, only the latest is kept.
do $$ begin
  assert public.send_friend_ping('bbbbbbbb-0000-0000-0000-000000000002', 2::smallint), 'ping';
  assert not public.send_friend_ping('bbbbbbbb-0000-0000-0000-000000000002', 3::smallint), 'too soon';
  assert not public.send_friend_ping('bbbbbbbb-0000-0000-0000-000000000002', 99::smallint), 'unknown preset';
  assert not public.send_friend_ping('cccccccc-0000-0000-0000-000000000003', 1::smallint), 'not a friend';
end $$;

-- Rival records: only against friends, counted per attacker.
do $$
declare res jsonb;
begin
  perform public.record_rival_fight('bbbbbbbb-0000-0000-0000-000000000002', 0::smallint);
  res := public.record_rival_fight('bbbbbbbb-0000-0000-0000-000000000002', 1::smallint);
  assert res = '{"wins": 1, "losses": 1, "draws": 0}'::jsonb, 'record: ' || res::text;
  assert public.record_rival_fight('cccccccc-0000-0000-0000-000000000003', 0::smallint) is null, 'not a friend';
  begin
    insert into public.rival_records (attacker_id, defender_id, wins) values (auth.uid(), 'bbbbbbbb-0000-0000-0000-000000000002', 99);
    assert false, 'direct record insert should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

select tests.as_user(:bob);
do $$
declare alice jsonb;
begin
  select f into alice from jsonb_array_elements(public.friends_overview() -> 'friends') f
  where f ->> 'id' = 'aaaaaaaa-0000-0000-0000-000000000001';
  assert (alice -> 'ping' ->> 'preset')::int = 2, 'bob sees alice''s ping';
  assert (alice -> 'record' ->> 'wins')::int = 0, 'bob''s own record vs alice is separate';
end $$;

-- Cara sees none of it, and can't write anything directly.
select tests.as_user(:cara);
do $$ begin
  assert (select count(*) from public.friendships) = 0, 'cara sees no friendships';
  assert (select count(*) from public.energy_gifts) = 0, 'cara sees no gifts';
  assert (select count(*) from public.friend_pings) = 0, 'cara sees no pings';
  assert (select count(*) from public.rival_records) = 0, 'cara sees no records';
  begin
    insert into public.friendships (a, b, requested_by) values ('aaaaaaaa-0000-0000-0000-000000000001', 'cccccccc-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000001');
    assert false, 'direct friendship insert should be refused';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.energy_gifts (from_id, to_id, day) values ('bbbbbbbb-0000-0000-0000-000000000002', 'cccccccc-0000-0000-0000-000000000003', current_date);
    assert false, 'direct gift insert should be refused';
  exception when insufficient_privilege then null;
  end;
  assert not public.answer_friend('aaaaaaaa-0000-0000-0000-000000000001', true), 'nothing to accept';
end $$;

-- Declining and unfriending.
do $$ begin
  perform public.add_friend((select friend_code from public.profiles where id = 'bbbbbbbb-0000-0000-0000-000000000002'));
end $$;
select tests.as_user(:bob);
do $$ begin
  assert public.answer_friend('cccccccc-0000-0000-0000-000000000003', false), 'declined';
  assert jsonb_array_length(public.friends_overview() -> 'friends') = 1, 'only alice left';
  assert public.remove_friend('aaaaaaaa-0000-0000-0000-000000000001'), 'unfriended';
  assert jsonb_array_length(public.friends_overview() -> 'friends') = 0, 'nobody left';
  assert not public.send_energy_gift('aaaaaaaa-0000-0000-0000-000000000001'), 'no gifts after unfriending';
end $$;

-- Signed-out callers can't use any of it.
reset role;
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.friends_overview();
    assert false, 'anon cannot list friends';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.add_friend('ABCDEFGH');
    assert false, 'anon cannot add friends';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
