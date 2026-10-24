# Implementation Plan

The requested product is a client booking experience and a nutritionist dashboard backed by the same persistent Supabase database. This plan follows the assignment's required order. The repository was empty at inspection, so no existing code, tests, credentials, or deployment configuration were available.

## Phase 0 — Repository inspection and setup checkpoint

**Status: Complete.** Created project rules, this plan, the development log, README, Supabase setup guide, and chat-log export instructions. The user confirmed Supabase project and Auth email OTP setup. Public project values were found in `.env` and copied to ignored `.env.local` without displaying them.

**Acceptance criteria:** Repository state inspected; no existing work overwritten; required Phase 0 documents present; setup requirements and secret handling explained; initial log entry recorded; numbered user setup checkpoint provided.

## Phase 1 — Foundation and MVP (in progress)

React, Vite, TypeScript, Tailwind CSS, React Router, Lucide icons, shared layout, responsive navigation, public landing page, client OTP/booking and appointment views, nutritionist login/dashboard, manual staff booking, and schedule configuration. Initial SQL migration includes roles, RLS, sample appointments, slot availability, and mutation RPCs.

**Current status:** Local foundation and build are complete. Tests pass. Supabase migration has not been applied; live OTP/RLS/concurrency checks and browser viewport checks remain outstanding. Remaining product gaps and evidence are listed in `docs/TESTING.md` and `docs/ARCHITECTURE.md`.

**Acceptance criteria:** Application builds; shared design system and navigation work at mobile and desktop sizes; keyboard focus and reduced-motion behavior are supported; relevant checks are recorded; live backend flows are verified before calling the MVP complete.

## Phase 2 — Landing page

Responsive wellness landing page with hero, booking and appointment CTAs, benefits, process, trust details, FAQ, footer, and original doodles.

**Acceptance criteria:** All sections render and navigate correctly; editable demo copy is clearly labeled; layout and interactions are inspected across the target viewports.

## Phase 3 — Database and access policies

Supabase migrations for profiles/roles, appointments, availability, and required supporting data; RLS policies; safe seed strategy; database-level conflict prevention.

**Acceptance criteria:** Migrations apply; access policies restrict data appropriately; conflict-prevention behavior is verified against the configured backend; sample data assumptions are documented.

## Phase 4 — Client authentication

Passwordless email OTP sign-in, session handling, login/logout, and client empty state.

**Acceptance criteria:** Supabase's configured OTP flow matches the UI; valid and invalid cases behave correctly; no-appointment state offers booking; no OTP bypass exists.

## Phase 5 — Booking flow

Date and availability selection, client details, review, email verification, and authoritative booking confirmation with conflict handling.

**Acceptance criteria:** Validation and errors are clear; selecting a slot does not reserve it; duplicate submissions and concurrent booking conflicts are handled by the backend.

## Phase 6 — Client appointments

Upcoming and past appointments, details, status, next appointment, reschedule, cancel, loading, empty, and error states.

**Acceptance criteria:** Only eligible appointments can be changed; rescheduling revalidates availability server-side; local timezone display is consistent.

## Phase 7 — Nutritionist dashboard

Secure nutritionist access, appointment list/cards, today's filter, search, status changes, and manual booking.

**Acceptance criteria:** Nutritionist-only operations are authorized on the backend; dashboard data is the same persistent appointment data used by clients.

## Phase 8 — Notifications and reminders

Booking, reschedule, and cancellation email notifications, plus an appropriate reminder mechanism.

**Acceptance criteria:** Email delivery is configured and verified in the target environment; notification failures are handled; no-show prevention behavior is documented.

## Phase 9 — Full QA

Unit, integration, end-to-end, responsive, accessibility, concurrency, and security checks.

**Acceptance criteria:** Report exact commands and results; inspect the specified viewports; fix and re-run failures. Supabase integration/E2E work requires the setup checkpoint confirmation.

## Phase 10 — Documentation and submission artifacts

Complete README, maintainable PDF source and generated PDF, accurate test report, and final setup/deployment guide.

**Acceptance criteria:** PDF uses exactly the six headings required in the assignment and reflects observed events only; no fabricated results.

## Phase 11 — Deployment and final verification

Vercel frontend deployment and configured Supabase production environment, followed by production verification.

**Acceptance criteria:** Deployment and live workflows are verified with evidence; provide final submission checklist and accurately state remaining limitations.

## Configuration and external services

- Supabase project URL and publishable key are expected in frontend configuration. The publishable key is safe to use in a browser only alongside correctly configured RLS.
- Supabase database migrations, Auth email OTP settings, SMTP/email delivery, authorized redirect URLs, and a securely provisioned nutritionist user are required for backend workflows.
- Any Supabase secret/service-role key or Edge Function secret must remain server-side and must never be committed or pasted into chat.
- Vercel needs the frontend's public environment variables and production URL/redirect configuration.
- The supplied intended test address `omphopse96@gmail.com` passes syntax validation, but inbox ownership and delivery are not verified. Do not send OTPs without a working configured project and controlled inbox. Use configurable test setup, never hardcode the personal address.
- User reports a Supabase project and email OTP configuration are ready. A read-only REST request reached the project but returned HTTP 404 for the not-yet-applied `business_settings` table query. Auth, RLS, and booking behavior remain unverified.
