# PesaLog portal (Stage 1)

A web page where you log in, see failed / unconfirmed / received / pending payments and tap **Retry**.
The phone does the retry: the page only sends a command, PesaLog on the phone picks it up (Stage 2).

## One-time setup

1. **Create the database (free).** supabase.com > New project. Pick the region nearest Kenya (London or Frankfurt). Save the database password somewhere safe.
2. **Create the tables.** Supabase > SQL Editor > New query > paste all of `supabase_setup.sql` > Run.
3. **Lock the door (important).** Authentication > Sign In / Providers > Email: turn OFF **Allow new users to sign up**. Otherwise anyone could make an account.
4. **Create your login.** Authentication > Users > Add user > Create new user. Enter your email and a strong password and tick **Auto Confirm User**.
5. **Copy two values.** Project Settings > API: the **Project URL** and the **anon public** key. Never copy the `service_role` key anywhere.
6. **Put them in the page.** Open `index.html`, find the block marked `PUT YOUR TWO VALUES HERE` and paste the URL and the anon key between the quotes (Termux: `micro index.html`).
7. **Publish the page** (GitHub Pages needs a public repo; the page holds no data, only the public anon key):

```
cd ~ && rm -rf pesalog-portal && mkdir pesalog-portal && cd pesalog-portal
cp ~/storage/downloads/index.html ~/storage/downloads/supabase_setup.sql ~/storage/downloads/README.md .
git init -q && git branch -M main && git add -A && git commit -qm "PesaLog portal" && gh repo create pesalog-portal --public --source=. --push
gh api -X POST repos/$(gh api user -q .login)/pesalog-portal/pages -f "source[branch]=main" -f "source[path]=/"
```

The portal is then at `https://YOUR-GITHUB-NAME.github.io/pesalog-portal/` (allow a couple of minutes).

## How it is protected
- Every table has Row Level Security: a logged-in user can only read and write their own rows. Without logging in the page shows nothing.
- Sign-ups are off, so only the user you created can log in.
- The full phone number never leaves the phone: the portal only gets a masked number (0712***678), the name, amount, offer, status and time.
- The raw SMS, USSD replies and balances (other than airtime) are never uploaded.

## Stage 2 (the app, next)
PesaLog gets a "Portal sync" screen (Supabase URL, anon key, your email and password), then every minute in the background it:
1. uploads the failed / unconfirmed / received / pending payments and its own status (online, version, airtime, automation on or off);
2. fetches queued Retry commands, checks the inbox for Safaricom's confirmation first (skipping anything already delivered), runs the rest and reports back "retried", "already delivered" or the failure reason.
