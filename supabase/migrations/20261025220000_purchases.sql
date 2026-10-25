-- Real-money purchases (game/glow/apple_store.gd, play_store.gd): the game
-- records each store transaction here before it grants the gems, pass or
-- unlock, so there is a server copy of everything bought.
--
-- record_purchase stores the receipt (Apple) or purchase token (Google) as
-- sent. `verified` stays false until a server-side check against Apple and
-- Google is added (it needs store credentials, which only exist once the
-- store accounts do). A transaction belongs to the first player who records
-- it: another player replaying the same id is refused.
--
-- Rows go with the player when they delete their account (cascade).

create table public.purchases (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  store text not null check (store in ('apple', 'google')),
  product_id text not null check (length(product_id) between 1 and 64),
  txn text not null check (length(txn) between 1 and 200),
  receipt text not null default '' check (length(receipt) <= 65536),
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  unique (store, txn)
);

alter table public.purchases enable row level security;
revoke all on public.purchases from anon, authenticated;

create function public.record_purchase(p_store text, p_product text, p_txn text, p_receipt text default '')
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  owner uuid;
begin
  if me is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  insert into public.purchases (user_id, store, product_id, txn, receipt)
  values (me, p_store, p_product, p_txn, coalesce(p_receipt, ''))
  on conflict (store, txn) do nothing;
  select user_id into owner from public.purchases where store = p_store and txn = p_txn;
  if owner <> me then
    raise exception 'transaction belongs to another player' using errcode = '42501';
  end if;
  return true;
end $$;

revoke all on function public.record_purchase(text, text, text, text) from public, anon;
grant execute on function public.record_purchase(text, text, text, text) to authenticated;
