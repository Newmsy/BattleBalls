-- Delete account: a player removes their own user and everything tied to it.
-- Uses its own players and removes them, so test order doesn't matter.

\set dora '''dddddddd-0000-0000-0000-000000000004'''
\set eve  '''eeeeeeee-0000-0000-0000-000000000005'''

reset role;
insert into auth.users (id) values (:dora), (:eve);
insert into public.test_logins (slot, user_id, email, password) values (9, :eve, 'test@example.com', 'x');

set role authenticated;
select tests.as_user(:dora);
select public.push_save(1, '{"wins": 1}');

-- Signed out: refused.
select tests.as_user(null);
do $$ begin
  begin
    perform public.delete_my_account();
    assert false, 'signed-out delete should be refused';
  exception when invalid_authorization_specification then null;
  end;
end $$;

-- The shared test account: refused.
select tests.as_user(:eve);
do $$ begin
  begin
    perform public.delete_my_account();
    assert false, 'test account delete should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Dora deletes herself: her user, profile and save go; nobody else's do.
select tests.as_user(:dora);
select public.delete_my_account();
reset role;
do $$ begin
  assert not exists (select from auth.users where id = 'dddddddd-0000-0000-0000-000000000004'), 'user gone';
  assert not exists (select from public.profiles where id = 'dddddddd-0000-0000-0000-000000000004'), 'profile gone';
  assert not exists (select from public.saves where user_id = 'dddddddd-0000-0000-0000-000000000004'), 'save gone';
  assert exists (select from auth.users where id = 'eeeeeeee-0000-0000-0000-000000000005'), 'test account kept';
  assert (select count(*) from auth.users where id::text like 'aaaaaaaa%' or id::text like 'bbbbbbbb%') = 2, 'others kept';
end $$;

-- Leave the database as the later tests expect it.
delete from public.test_logins where slot = 9;
delete from auth.users where id = :eve;
