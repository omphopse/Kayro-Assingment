# Supabase Setup Checkpoint

The user has reported that the Supabase project and email OTP setup are complete. Public project variables were found in `.env` and copied to ignored `.env.local` without displaying them. A read-only REST query returned HTTP 404 for the migration-created `business_settings` table, so the SQL migration appears not to be applied. Auth, RLS, and booking behavior remain unverified. Do not send passwords, OTPs, service-role keys, or secret API keys in chat.

## 1. Create a Supabase project

1. Sign in to the Supabase dashboard and choose **New project** in the organization where you want this assignment hosted.
2. Give it a project name such as `nutritionist-booking`.
3. Create a strong database password and save it in your password manager. Do not paste it into chat or commit it.
4. Choose a region close to the intended users to reduce latency and meet your data-location needs. The user base/location is not specified, so no specific region is prescribed here.
5. Create the project and wait until provisioning finishes.

## 2. Find the project URL and publishable key

1. In the project dashboard, open **Project Settings** → **API** (the dashboard wording may change).
2. Copy the **Project URL** and the **publishable key** (older dashboards may label the client-safe key `anon` / `anon public`). These are intended for client configuration, but access still depends on correct RLS.
3. Add them to the local ignored `.env.local` as `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`. The current file is configured with these public values. Never use a `service_role` or secret key in browser code.

Safe-to-share setup confirmations: project created, selected region, Auth settings configured, migrations applied, seed status, redirect URL set, and whether Vercel is configured. The project URL and publishable key are not privileged secrets, but do not need to be pasted into chat unless a future step specifically requests them. Keep database passwords, SMTP credentials, OTPs, access tokens, service-role keys, and secret API keys private.

## 3. Configure authentication and email OTP

1. Open **Authentication** → **Providers** (or **Sign In / Providers**) and ensure **Email** is enabled.
2. Configure the project for email OTP. Supabase's email template and Auth settings determine whether a request sends a code or a magic link. The application must match the configured behavior; do not enable a magic-link-only flow while expecting a numeric OTP.
3. Inspect the email template and ensure it renders the OTP token/code intended by the app. Keep the default secure expiry/rate-limit behavior unless the assignment's verified needs require a change.
4. In **Authentication** → **URL Configuration**, set the local development URL and later the deployed Vercel URL as allowed site/redirect URLs as appropriate. Use the exact URLs the application will use; do not add broad wildcard origins for production.

## 4. Configure email delivery / SMTP

1. In **Project Settings** → **Auth** / **SMTP Settings** (dashboard wording may change), configure a supported SMTP provider for reliable delivery.
2. Verify the sender domain and sender address with that provider if required.
3. Add SMTP host, port, username, password, and sender details only in the Supabase dashboard's secret configuration. Do not send SMTP credentials through chat or commit them.
4. Confirm provider sending limits and deliverability for OTP and notification email. Until this is configured, delivery may be limited or unsuitable for production.

## 5. Securely provision the initial nutritionist account

Do not create a public sign-up path that grants nutritionist privileges. Create the Auth user using a trusted dashboard invite/admin flow, then run the promotion SQL comment at the end of `supabase/migrations/202610240001_initial_schema.sql` as project owner, substituting the existing Auth UUID. Never expose the service-role key in frontend configuration. The account has not been provisioned yet.

## 6. Edge Function secrets

No Edge Functions exist yet. If later implementation needs SMTP/API credentials or the Supabase service-role key, add those through **Edge Functions → Secrets** or the supported server-side secret store. Do not use `VITE_` variables for secrets; Vite-prefixed values are exposed to the browser.

## 7. Migrations and seed data

The initial version-controlled migration is `supabase/migrations/202610240001_initial_schema.sql`. It creates the schema/RLS/RPCs and inserts the five idempotent assignment sample rows. Apply it once to the intended project in **SQL Editor** (paste/run the file) or with the Supabase CLI after linking the project. See `docs/SETUP.md`. The workspace has no Supabase CLI configuration yet. Review the target project before applying; do not run against production without review. Do not create schema manually based on this guide.

## 8. Vercel environment variables

The frontend exists locally, but no Vercel project is connected. When deployed, add only the client-safe project URL and publishable key to the Vercel project's environment settings for the required environments. Keep any server-only secrets in server-side/Edge Function secret settings. Add the deployed domain to Supabase's allowed site/redirect URL configuration.

## 9. Confirm the test email

The assignment supplied `omphopse96@gmail.com`. It passes basic email syntax validation; inbox control and delivery remain unverified. Do not substitute another address silently or send repeated OTPs. The app does not hardcode the address.

## 10. Verify setup and report back

Before any Supabase-dependent integration or end-to-end testing, make sure that:

1. The Supabase project is provisioned and its region selected (the user reports this is done).
2. Email OTP (numeric code vs. magic link) and SMTP are configured.
3. Local/deployed redirect URLs are configured as applicable.
4. The migration and idempotent sample seed have been applied (instructions are in `docs/SETUP.md`).
5. Vercel setup is complete or not yet applicable.
6. The test inbox is controlled by the user and ready for a deliberate OTP test.

Share statuses and non-secret details only. Never provide passwords, OTPs, SMTP credentials, database credentials, access tokens, or service-role/secret keys. Exact migration commands are in `docs/SETUP.md`.
