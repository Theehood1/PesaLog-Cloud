-- PesaLog Cloud V9.04 (already applied to project oatsttwmekgfoxcpjnin). Additive only.
alter table public.txn_sync add column if not exists verified boolean not null default false, add column if not exists no_number boolean not null default false;
alter table public.device_state add column if not exists battery int, add column if not exists charging boolean, add column if not exists airtime_at timestamptz, add column if not exists commission numeric, add column if not exists commission_at timestamptz, add column if not exists summary jsonb, add column if not exists allow_edits boolean not null default false;
alter table public.commands add column if not exists payload jsonb;
-- plans_sync (name, price, cost, commission, enabled, category, hours, sig state, run_on). No USSD codes.
-- remote_jobs: offers handed from the receiving phone to the running phone; the phone column is erased on pickup.
