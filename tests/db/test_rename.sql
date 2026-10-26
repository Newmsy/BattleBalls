-- Renaming: players change their own name through set_display_name only.

\set fay '''ffffffff-0000-0000-0000-000000000006'''

reset role;
insert into auth.users (id) values (:fay);

set role authenticated;
select tests.as_user(:fay);

do $$ begin
  assert public.set_display_name('  Bouncy   Bob ') = 'Bouncy Bob', 'trims and collapses spaces';
  assert (select display_name from public.profiles where id = auth.uid()) = 'Bouncy Bob', 'saved';
  assert public.name_problem('Bo') = 'too_short';
  assert public.name_problem('Seventeen letters') = 'too_long';
  assert public.name_problem('Bob!') = 'bad_chars';
  assert public.name_problem('1234') = 'no_letters';
  assert public.name_problem('Sh1t Ball') = 'rude', 'leet';
  assert public.name_problem('f.u.c.k') = 'rude', 'gaps';
  assert public.name_problem('Big Ass') = 'rude', 'whole word';
  assert public.name_problem('Classy Glass') is null, 'innocent words pass';
  assert public.name_problem('Peacock Dickens') is null, 'whole-word list only blocks whole words';
  assert public.name_problem('Mo_the-Ball.2') is null;
end $$;

-- Bad names are refused with the reason.
do $$ begin
  begin
    perform public.set_display_name('no');
    assert false, 'short name should be refused';
  exception when invalid_parameter_value then
    assert sqlerrm = 'name: too_short', sqlerrm;
  end;
end $$;

-- Writing the column directly is no longer allowed.
do $$ begin
  begin
    update public.profiles set display_name = 'Shit' where id = auth.uid();
    assert false, 'direct update should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Signed out: refused.
select tests.as_user(null);
do $$ begin
  begin
    perform public.set_display_name('Somebody');
    assert false, 'signed-out rename should be refused';
  exception when invalid_authorization_specification then null;
  end;
end $$;

reset role;
delete from auth.users where id = :fay;
