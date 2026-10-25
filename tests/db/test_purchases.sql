-- Purchases: recorded once per store transaction, owned by whoever recorded
-- it first, and only through record_purchase.

\set fay '''ffffffff-0000-0000-0000-000000000006'''
\set gus '''99999999-0000-0000-0000-000000000007'''

reset role;
insert into auth.users (id) values (:fay), (:gus);

set role authenticated;
select tests.as_user(:fay);
do $$ begin
  assert public.record_purchase('apple', 'gems_80', 'T1', 'receipt'), 'first record';
  assert public.record_purchase('apple', 'gems_80', 'T1', 'receipt'), 'redelivery is fine';
  assert public.record_purchase('google', 'gems_80', 'T1'), 'same id in the other store is another purchase';
  begin
    perform public.record_purchase('steam', 'gems_80', 'T2');
    assert false, 'unknown store refused';
  exception when check_violation then null;
  end;
  begin
    perform count(*) from public.purchases;
    assert false, 'no direct reads';
  exception when insufficient_privilege then null;
  end;
end $$;

select tests.as_user(:gus);
do $$ begin
  begin
    perform public.record_purchase('apple', 'gems_80', 'T1');
    assert false, 'someone else''s transaction refused';
  exception when insufficient_privilege then null;
  end;
end $$;

select tests.as_user(null);
do $$ begin
  begin
    perform public.record_purchase('apple', 'gems_80', 'T3');
    assert false, 'signed-out refused';
  exception when invalid_authorization_specification then null;
  end;
end $$;

reset role;
do $$ begin
  assert (select count(*) from public.purchases where user_id = 'ffffffff-0000-0000-0000-000000000006') = 2, 'two rows for fay';
end $$;
delete from auth.users where id in (:fay, :gus);
do $$ begin
  assert (select count(*) from public.purchases) = 0, 'rows go with the account';
end $$;
