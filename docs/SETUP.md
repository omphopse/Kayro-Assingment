# Local Setup

## Requirements

- Node.js compatible with the installed Vite version (Node.js 20.19+ or 22.12+ recommended by Vite 8).
- npm.
- A Supabase project with Email Auth enabled. No credentials are stored in the repository.

## Install and configure

```powershell
npm install
Copy-Item .env.example .env.local
```

Set `VITE_SUPABASE_URL` to the project URL and `VITE_SUPABASE_PUBLISHABLE_KEY` to its publishable key in `.env.local`. Only the publishable key belongs in client configuration. Never put a service-role/secret key in a `VITE_` variable. `.env.local` is ignored by Git.

## Database

Apply the SQL in `supabase/migrations/202610240001_initial_schema.sql` using the Supabase SQL editor or Supabase CLI after linking the intended project. Confirm the Supabase project URL before applying; migrations alter database state. The migration includes idempotent sample rows and development availability defaults. Apply exactly once through migrations; reapplying the SQL as a whole is not supported because types and policies are created without `IF NOT EXISTS`.

Create an authorized staff Auth account through the dashboard's secure invite/admin flow. After the Auth user exists, run the staff promotion statement at the bottom of the migration with that account's Auth UUID as project owner. Do not accept public staff signups or expose a service-role key.

## Run

```powershell
npm run dev
```

Open the URL Vite prints. Routes: `/` landing, `/book`, `/appointments`, `/nutritionist`, and `/nutritionist/dashboard`.

## Checks

```powershell
npm test
npm run build
```

Automated browser/responsive checks and live Supabase checks are not supplied as completed results. See `TESTING.md`.

## Test email

The assignment says to use `omphopse96@gmail.com`. That address is syntactically valid (despite an earlier Phase 0 note that incorrectly questioned it), but no inbox ownership or delivery has been verified. Configure OTP settings for the address you control and use it manually. Avoid repeated OTP requests. The optional `VITE_TEST_EMAIL` variable is documentation/configuration only; application auth does not hardcode it.
