-- Bracket of Legends picks: one per player per event, changeable, private,
-- and only counted (never listed) for everyone else.

\set dana '''b0b0b0b0-0000-0000-0000-00000000000d'''
\set eli  '''b0b0b0b0-0000-0000-0000-00000000000e'''

insert into auth.users (id) values (:dana), (:eli);

set role authenticated;
select tests.as_user(:dana);
do $$
declare p public.bracket_predictions;
begin
  p := public.predict_bracket('2026-10-19-20261019', 'laser');
  assert p.champion = 'laser', 'pick lands';
  p := public.predict_bracket('2026-10-19-20261019', 'vampire');
  assert p.champion = 'vampire', 'pick changes';
  assert (select count(*) from public.bracket_predictions) = 1, 'one pick per event';
  begin
    perform public.predict_bracket('2026-10-19-20261019', 'Robert''); drop table x;--');
    assert false, 'odd champion ids are refused';
  exception when invalid_parameter_value then null;
  end;
  begin
    insert into public.bracket_predictions (user_id, event_id, champion)
    values ('b0b0b0b0-0000-0000-0000-00000000000d', 'other', 'laser');
    assert false, 'direct insert should be refused';
  exception when insufficient_privilege then null;
  end;
end $$;

select tests.as_user(:eli);
do $$ begin
  perform public.predict_bracket('2026-10-19-20261019', 'vampire');
  assert (select count(*) from public.bracket_predictions) = 1, 'eli sees only his own pick';
  assert (select picks from public.bracket_pick_shares('2026-10-19-20261019') where champion = 'vampire') = 2,
    'shares count everyone';
  assert (select count(*) from public.bracket_pick_shares('another-event')) = 0, 'shares are per event';
end $$;

reset role;
set role anon;
select tests.as_user(null);
do $$ begin
  begin
    perform public.predict_bracket('2026-10-19-20261019', 'laser');
    assert false, 'anon cannot pick';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
