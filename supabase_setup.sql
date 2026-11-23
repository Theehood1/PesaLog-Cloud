-- PesaLog portal: run this once in Supabase > SQL Editor.
-- Every table is locked to its owner with Row Level Security: a logged-in user can only ever see and change their own rows.

create table if not exists public.txn_sync (
  owner        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ref          text not null,                 -- M-Pesa code
  name         text,
  phone_masked text,                          -- for example 0712***678 (the full number never leaves the phone)
  amount       numeric,
  plan         text,
  status       text not null,                 -- failed | unconfirmed | received | pending | completed | reversed
  reason       text,
  paid_at      timestamptz,
  updated_at   timestamptz not null default now(),
  primary key (owner, ref)
);

create table if not exists public.commands (
  id          bigint generated always as identity primary key,
  owner       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ref         text not null,
  action      text not null default 'retry',
  status      text not null default 'queued', -- queued | running | done | failed
  result      text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- one waiting retry per payment: tapping Retry twice does not queue it twice
create unique index if not exists commands_one_active
  on public.commands (owner, ref, action) where status in ('queued', 'running');
create index if not exists commands_owner_status on public.commands (owner, status);
create index if not exists txn_sync_owner_status on public.txn_sync (owner, status);

create table if not exists public.device_state (
  owner       uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  last_seen   timestamptz,
  app_version text,
  airtime     numeric,
  automation  boolean
);

alter table public.txn_sync     enable row level security;
alter table public.commands     enable row level security;
alter table public.device_state enable row level security;

drop policy if exists "own txn_sync" on public.txn_sync;
create policy "own txn_sync" on public.txn_sync for all using (owner = auth.uid()) with check (owner = auth.uid());
drop policy if exists "own commands" on public.commands;
create policy "own commands" on public.commands for all using (owner = auth.uid()) with check (owner = auth.uid());
drop policy if exists "own device_state" on public.device_state;
create policy "own device_state" on public.device_state for all using (owner = auth.uid()) with check (owner = auth.uid());

-- clean up: finished retries and old payment rows are not kept for ever
create or replace function public.pesalog_cleanup() returns void language sql security definer as $$
  delete from public.commands where created_at < now() - interval '14 days';
  delete from public.txn_sync where status in ('completed','reversed') and updated_at < now() - interval '3 days';
$$;
