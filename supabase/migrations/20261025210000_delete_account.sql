-- Delete account (App Store 5.1.1(v), Google Play data deletion): a player
-- removes their own user and everything tied to it from inside the game.
-- Every player table references auth.users with on delete cascade (Ghost
-- Arena fights they defended keep the fight with the defender cleared), so
-- deleting the user row removes their profile, save, lineup, fights,
-- predictions, friends, gifts, pings, rival records, Bounce Run scores and
-- analytics in one go. Guests may delete too.
--
-- The shared test account (public.test_logins) can't be deleted this way:
-- every test-mode device signs in to it.

create function public.delete_my_account()
returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if exists (select from public.test_logins where user_id = me) then
    raise exception 'the shared test account can''t be deleted' using errcode = '42501';
  end if;
  delete from auth.users where id = me;
end $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
