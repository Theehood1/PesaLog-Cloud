# PesaLog Cloud

PesaLog Cloud is the web portal and Supabase backend for PesaLog Android. It preserves the original portal's three-table contract:

- `txn_sync` — transaction status with masked phone numbers only.
- `commands` — queued remote retry requests and phone-side results.
- `device_state` — last phone heartbeat, app version, airtime and automation state.

## Supabase project

- Project URL: `https://oatsttwmekgfoxcpjnin.supabase.co`
- Use the project's **publishable** key (`sb_publishable_...`) in this static portal and in the Android Portal Sync settings.
- Never put a `service_role` / secret key in this repository, website, or Android app.

The current project already has all three tables, RLS enabled, and owner-only policies for the `authenticated` role. Anonymous table privileges have been revoked. The cleanup function can only be executed by `service_role`.

## Supabase Auth

1. Keep public sign-ups disabled.
2. Use the confirmed user created for the owner account.
3. Enable leaked-password protection in Auth security settings.
4. Portal and Android must sign in with the same Supabase user so `auth.uid()` matches the row owner.

## Deploy website with GitHub Pages

This repository includes `.github/workflows/pages.yml`. In GitHub:

1. Open **Theehood1/PesaLog-Cloud → Settings → Pages**.
2. Set **Source** to **GitHub Actions**.
3. Push to `main`; the workflow publishes `index.html`.

Expected site address: `https://theehood1.github.io/PesaLog-Cloud/`.

## Connect Android

In PesaLog Android open **Settings → Portal sync** and enter:

- Project URL: `https://oatsttwmekgfoxcpjnin.supabase.co`
- Project publishable key: copy the active `sb_publishable_...` key from Supabase Project Settings → API Keys.
- Sign in with the same confirmed portal account.

Tap **Sync now**. Keep PesaLog's foreground service enabled for regular heartbeat and remote command polling. The Android app performs the Safaricom inbox verification on-device before a remote retry; the website never runs USSD itself.

## Data and safety

- Full customer phone numbers and raw SMS/USSD content are not uploaded by the supplied Android portal-sync code; only masked phone numbers and transaction metadata are synced.
- Remote retry is a request to the phone, not a direct server-side payment action.
- The phone checks Safaricom confirmation messages and existing transaction state before retrying.
- A phone that is offline or whose PesaLog service is stopped cannot process queued commands until it reconnects.

## Database maintenance

Run `supabase_setup.sql` in Supabase SQL Editor only if you need to provision or re-apply the schema/policies. It is idempotent for the existing schema. `pesalog_cleanup()` is privileged and is not exposed to authenticated/anonymous clients. Schedule it separately through Supabase Cron only if retention cleanup is desired.

## Current verification snapshot

- Supabase project is active and healthy.
- All three expected tables exist and RLS is enabled.
- Owner-only policies are assigned to `authenticated`.
- Anonymous table grants have been revoked.
- No Edge Functions are currently required by this polling design.
- Security Advisor currently reports leaked-password protection disabled; enable it in Supabase Auth settings.
