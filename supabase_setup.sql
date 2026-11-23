-- PesaLog Cloud schema and security. Safe to run more than once.
-- Uses the original portal's three-table data model.

create table if not exists public.txn_sync (
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ref text not null,
  name text,
  phone_masked text,
  amount numeric,
  plan text,
  status text not null,
  reason text,
  paid_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (owner, ref)
);

create table if not exists public.commands (
  id bigint generated always as identity primary key,
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ref text not null,
  action text not null default 'retry',
  status text not null default 'queued',
  result text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists commands_one_active
  on public.commands (owner, ref, action)
  where status in ('queued', 'running');
create index if not exists commands_owner_status on public.commands (owner, status);
create index if not exists txn_sync_owner_status on public.txn_sync (owner, status);

create table if not exists public.device_state (
  owner uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  last_seen timestamptz,
  app_version text,
  airtime numeric,
  automation boolean
);

alter table public.txn_sync enable row level security;
alter table public.commands enable row level security;
alter table public.device_state enable row level security;

drop policy if exists "own txn_sync" on public.txn_sync;
create policy "own txn_sync" on public.txn_sync for all to authenticated
  using ((select auth.uid()) = owner) with check ((select auth.uid()) = owner);
drop policy if exists "own commands" on public.commands;
create policy "own commands" on public.commands for all to authenticated
  using ((select auth.uid()) = owner) with check ((select auth.uid()) = owner);
drop policy if exists "own device_state" on public.device_state;
create policy "own device_state" on public.device_state for all to authenticated
  using ((select auth.uid()) = owner) with check ((select auth.uid()) = owner);

-- No anonymous table access. Authenticated portal/app sessions are owner-scoped by RLS.
revoke all on table public.txn_sync, public.commands, public.device_state from anon;
grant select, insert, update, delete on table public.txn_sync, public.commands, public.device_state to authenticated;

-- Identity sequence access needed for authenticated inserts into commands.
grant usage, select on sequence public.commands_id_seq to authenticated;

create or replace function public.pesalog_cleanup()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.commands where created_at < now() - interval '14 days';
  delete from public.txn_sync
    where status in ('completed','reversed')
      and updated_at < now() - interval '3 days';
$$;

-- Cleanup is privileged; browser/mobile clients must never invoke it.
revoke all on function public.pesalog_cleanup() from public;
revoke all on function public.pesalog_cleanup() from anon, authenticated;
grant execute on function public.pesalog_cleanup() to service_role;
