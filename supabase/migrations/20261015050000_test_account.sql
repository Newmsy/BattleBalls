-- Test account: while the game's test mode is on (game/online/test_user.gd),
-- every device signs in to one real account instead of its own guest, so its
-- save, trophies, league and friends follow Newms across devices.
--
-- CI's migrate job (tools/supabase_auth_config.mjs) creates the account and
-- gives it a new random password on every deploy, then stores the login
-- here. test_login hands it to any visitor: that is the point of test mode,
-- and the account has only a normal player's rights, so nobody can use it to
-- reach anyone else's data. Drop this once test mode is off for good.

create table public.test_logins (
  slot int primary key check (slot between 1 and 9),
  user_id uuid not null,
  email text not null,
  password text not null,
  updated_at timestamptz not null default now()
);

-- Only the deploy script (service role) writes or reads the table directly.
alter table public.test_logins enable row level security;
revoke all on public.test_logins from anon, authenticated;

create function public.test_login(p_slot int)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('email', email, 'password', password)
  from public.test_logins where slot = p_slot;
$$;

revoke all on function public.test_login(int) from public;
grant execute on function public.test_login(int) to anon, authenticated;

-- The shared test save slot from the first version of test mode is replaced
-- by the test account's own row in public.saves (devices bring their local
-- copy over on their next sync).
drop function public.test_sync_save(int, bigint, jsonb, text);
drop function public.test_load_save(int);
drop table public.test_saves;
