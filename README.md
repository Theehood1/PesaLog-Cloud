# PesaLog Cloud — Multi-device portal

This is the updated static portal for PesaLog V9.02. One Supabase login can display multiple Android installations, each identified by its own Device Name and persistent Device ID.

## Upgrade the existing PesaLog Cloud project

**Do not run the fresh-install SQL against the existing database.** The existing project already has data and RLS policies.

1. In Supabase, open **SQL Editor**.
2. Run `supabase_multi_device_migration.sql` once. It adds `device_id` and `device_name`, changes the transaction and device keys to include the device ID, and preserves existing rows/queued commands under the `legacy` device.
3. Deploy the updated `index.html` to the existing `Theehood1/PesaLog-Cloud` GitHub repository. Keep the current Supabase URL and publishable key in the page.
4. Update **every phone** to PesaLog V9.02 before relying on cloud sync. Older V9.01 apps use the old single-device schema and will not sync after the migration.

For a brand-new Supabase project only, use `supabase_setup.sql` instead of the migration file.

## What changed

- A phone creates a persistent unique Device ID on first Portal Sync setup.
- Each phone has its own editable Device Name (for example, `Main Phone` and `Shop Phone`).
- The dashboard lists each phone separately with online/offline, last seen, app version, airtime and automation status.
- Transactions carry their source device name and ID; the dashboard can filter by device or show all devices.
- Retry commands include the selected transaction's Device ID. Each phone polls only commands addressed to itself.
- Existing single-phone rows and queued commands are retained under Device ID `legacy`; the already-connected V9.01 phone adopts that identity on upgrade.

## Safety and privacy

- One authenticated Supabase account can be used by both phones; each installation has a different Device ID.
- Row Level Security remains owner-scoped and authenticated-only. The page contains only the publishable key, never a service-role key.
- Full customer phone numbers, raw SMS and USSD replies are not uploaded.
- Remote retry still runs on the target phone. That phone checks its own Safaricom inbox and existing transaction state before invoking the existing retry engine.
- A retry attempt is not proof of delivery; wait for Safaricom confirmation.

## V9.04
Adds payment tabs (Completed, Verified, Unverified, Pending), per-phone battery and airtime refresh, commission summaries, a Plans tab (edit prices and commission, request learn-signature, choose which phone runs an offer's USSD). Database changes are in supabase_v9_04_migration.sql (already applied).
