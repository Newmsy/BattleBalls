-- test_login: the shared test account's login (test mode, game/online/test_user.gd).

reset role;
insert into public.test_logins (slot, user_id, email, password)
values (1, '11111111-0000-0000-0000-000000000099', 'test-user-1@example.com', 'pw-from-deploy');

set role anon;
select tests.as_user(null);
do $$
declare r jsonb;
begin
  r := public.test_login(1);
  assert r ->> 'email' = 'test-user-1@example.com' and r ->> 'password' = 'pw-from-deploy', 'any visitor gets the test login';
  assert public.test_login(2) is null, 'unknown slot';
  begin
    perform count(*) from public.test_logins;
    assert false, 'no direct table access';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.test_logins (slot, user_id, email, password) values (2, gen_random_uuid(), 'x@example.com', 'x');
    assert false, 'visitors cannot add logins';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

do $$ begin
  assert to_regclass('public.test_saves') is null, 'old shared save slot is gone';
end $$;

-- The deploy script writes the login as service_role.
set role service_role;
do $$ begin
  insert into public.test_logins (slot, user_id, email, password)
  values (1, '11111111-0000-0000-0000-000000000099', 'test-user-1@example.com', 'next-deploy')
  on conflict (slot) do update set password = excluded.password;
  assert (select password from public.test_logins where slot = 1) = 'next-deploy', 'deploy script can store the login';
end $$;
reset role;
