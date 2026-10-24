# What we were asked

Build a mobile-first nutritionist booking MVP with a client experience and a nutritionist dashboard, backed by Supabase Auth and PostgreSQL. The assignment requires privacy-aware appointment management, concurrency protection, sample data, responsive design, and accurate project documentation.

# Your approach

The previously empty folder's Phase 0 documents were inspected and preserved. Phase 1 added a React/Vite/TypeScript foundation, a shared playful editorial design system, the public landing page, email OTP interface, booking and appointment views, nutritionist sign-in and dashboard workflows, and a version-controlled Supabase migration. Client writes are intended to use guarded database RPCs; a partial unique index prevents two active appointments from taking the same start time.

# Decisions and assumptions (including how you handled the sample data)

No real nutritionist identity or business schedule was supplied. The migration uses clearly labeled editable development defaults of weekdays 09:00-17:00, 30-minute appointments, and Asia/Kolkata. Replace them before real bookings. The five assignment sample records are seeded idempotently with stable keys, their given statuses and contact values, and a null phone for Meera Iyer. They remain staff-managed legacy/demo rows with no fabricated Auth users. The test address is configurable through the project setup; no OTP was sent.

# What you added

The repository now contains the Vite application, responsive cream/lime/ink design, OTP request and verification calls, slot selection and confirmation flow, client appointment list with cancellation/rescheduling controls, password sign-in and role-checked staff dashboard, manual staff appointment entry, editable weekly schedule UI, SQL schema/RLS/RPC migration, sample data, unit/component tests, and setup/architecture/testing/correction docs.

# What the AI got wrong (and how you caught and fixed it)

The Phase 0 log incorrectly described `omphopse96@gmail.com` as malformed. During Phase 1, the address was checked against the app's basic email syntax validator and passes that syntax check. This does not verify that the inbox exists or can receive mail; no OTP was sent. The initial production build also failed because React type declarations were missing and several imports were unused. The compiler output exposed this; the type packages were installed and unused imports removed. While copying public Supabase settings to the ignored local config, I omitted the separating newline; a read-only request caught the malformed URI before transmission. I rewrote the values on separate lines without displaying them. The retry returned HTTP 404 for the not-yet-available application table, so the migration and live workflows remain unverified.

# How to run it

Install Node.js and npm, run `npm install`, copy `.env.example` to `.env.local`, and fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`. Apply `supabase/migrations/202610240001_initial_schema.sql` to the intended Supabase project, securely provision a nutritionist Auth account, and promote its Auth UUID as described in the migration and `docs/SETUP.md`. Run `npm run dev` to start locally, `npm test` for the local Vitest suite, and `npm run build` for TypeScript and production bundle checks. Live Supabase, email delivery, and responsive browser testing have not been verified.
