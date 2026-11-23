-- PesaLog Cloud multi-device migration (V9.02)
-- Run once in Supabase SQL Editor BEFORE deploying the V9.02 app or portal.
-- Existing single-phone records and queued commands are preserved as device_id='legacy'.
begin;

alter table public.txn_sync
  add column if not exists device_id text not null default 'legacy',
  add column if not exists device_name text not null default 'Legacy Phone';

alter table public.commands
  add column if not exists device_id text not null default 'legacy';

alter table public.device_state
  add column if not exists device_id text not null default 'legacy',
  add column if not exists device_name text not null default 'Legacy Phone';

-- Change transaction identity from (owner, ref) to (owner, device_id, ref).
do $$
declare pk_name text;
begin
  select conname into pk_name from pg_constraint
    where conrelid = 'public.txn_sync'::regclass and contype = 'p';
  if pk_name is not null then
    execute format('alter table public.txn_sync drop constraint %I', pk_name);
  end if;
  alter table public.txn_sync
    add constraint txn_sync_pkey primary key (owner, device_id, ref);
end $$;

-- A user may now own several phone heartbeat rows.
do $$
declare pk_name text;
begin
  select conname into pk_name from pg_constraint
    where conrelid = 'public.device_state'::regclass and contype = 'p';
  if pk_name is not null then
    execute format('alter table public.device_state drop constraint %I', pk_name);
  end if;
  alter table public.device_state
    add constraint device_state_pkey primary key (owner, device_id);
end $$;

-- Prevent duplicate active retries only for the same device + payment.
drop index if exists public.commands_one_active;
create unique index commands_one_active
  on public.commands (owner, device_id, ref, action)
  where status in ('queued', 'running');

create index if not exists commands_owner_status
  on public.commands (owner, status);
create index if not exists txn_sync_owner_status
  on public.txn_sync (owner, status);
create index if not exists device_state_owner_seen
  on public.device_state (owner, last_seen desc);

-- Keep the existing authenticated-only RLS model.
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

revoke all on table public.txn_sync, public.commands, public.device_state from anon;
grant select, insert, update, delete on table public.txn_sync, public.commands, public.device_state to authenticated;
grant usage, select on sequence public.commands_id_seq to authenticated;

commit;
