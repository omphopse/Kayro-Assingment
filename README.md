# Nutritionist Call Booking Platform

**Status: Phase 1 MVP implementation underway.** The frontend and initial Supabase migration are implemented locally. A read-only request reached the configured Supabase REST endpoint but returned HTTP 404 for the migration-created `business_settings` query. The migration has not been applied; live auth, RLS, email, booking, and concurrency behavior have not been verified.

## 1. Project overview and problem

Good Measure is a responsive wellness booking experience for clients and nutritionists. Clients can begin a booking without an account, authenticate by passwordless email code, select an available appointment, and manage their schedule. Nutritionists use a separate staff sign-in and dashboard. Both experiences are designed to share one Supabase/PostgreSQL database.

## 2. Features currently implemented

- Responsive landing page in a warm cream, ink, lime, and orange visual system.
- Accessible email OTP request/verification UI using Supabase Auth.
- Date and time selection backed by an availability RPC, booking details/review, and booking RPC.
- Client appointments with empty state, cancellation confirmation, and reschedule slot picker.
- Nutritionist email/password sign-in, role check, appointment search/today filter, and status updates.
- Nutritionist manual booking and weekly hours/timezone/duration editor.
- SQL migration with role model, RLS, guarded RPCs, appointment event history, active-slot uniqueness, and idempotent sample keys.
- Reduced-motion CSS, keyboard focus states, local unit/component tests.

Known unverified or incomplete functionality is documented in `docs/TESTING.md` and `docs/ARCHITECTURE.md`. Email confirmation/reminders are not implemented. A live backend has not been configured in this workspace.

## 3. Screens and user journeys

- `/`: public landing page with FAQ and booking/appointments actions.
- `/book`: client email OTP → date/slot → name/phone → review → backend booking confirmation.
- `/appointments`: client OTP sign-in → own schedule → cancel/reschedule eligible appointments.
- `/nutritionist`: staff email/password sign-in.
- `/nutritionist/dashboard`: role-gated schedule, search, today/all filter, status, manual appointment, and availability management.

## 4. Technology stack and architecture

- React 19, Vite 8, TypeScript 7, Tailwind CSS 4, React Router 7, Lucide icons, date-fns 4.
- Supabase JS 2 with PostgreSQL, Auth, RLS, and security-definer RPCs.
- Vitest 5, jsdom, Testing Library.
- Vercel is the intended frontend host; no deployment exists.

See `docs/ARCHITECTURE.md` for authorization, data model, and conflict-prevention details.

## 5. Directory structure

```text
src/                    React app, styles, Supabase client, validation and tests
supabase/migrations/    Versioned schema, policies, RPCs and sample records
docs/                   Setup, architecture, testing, project log, corrections and PDF source
AI_DEVELOPMENT_LOG.md   Chronological development record
IMPLEMENTATION_PLAN.md  Phases and acceptance criteria
RULES.md                Project rules
```

## 6. Database schema, security, and booking conflicts

The migration creates `user_roles`, `business_settings`, `weekly_availability`, `appointments`, and `appointment_events`. New Auth users default to client. Nutritionist role assignment is an administrator-only operation for an existing Auth identity; there is no public staff signup. RLS limits client appointment reads to their linked Auth user and permits authorized nutritionists to read/manage appointments. Direct appointment table mutations have no client policies; RPCs perform ownership, role, date, status, and availability checks.

The `available_slots` RPC supplies candidate local times. `create_booking` rechecks configured hours and future time on the database. A partial unique index on active `starts_at` plus an exclusion constraint on appointment time ranges are the authoritative race and overlap guards; cancellation releases the time. Rescheduling is an atomic update and a collision leaves the old start time intact. Live RLS/concurrency tests remain outstanding.

## 7. Authentication, email, and reminders

Client sign-in uses Supabase passwordless email OTP (`signInWithOtp` and `verifyOtp`); nutritionist sign-in uses Supabase Auth password login and database role checks. No OTP is hardcoded or simulated. Supabase's email template, SMTP, rate limits, and allowed redirect URLs must be checked in the configured project. Booking confirmation email and reminders are not implemented. The user supplied `omphopse96@gmail.com`; it passes syntax validation, but inbox control and deliverability have not been checked.

## 8. Sample data and availability assumptions

The SQL migration inserts the five assignment examples with exact given names, dates, times, and statuses, preserving phone formatting and leaving Meera Iyer's phone `NULL`. Rows have stable unique sample keys and `source='sample'`; they do not create fake Auth accounts and are staff-only legacy/demo records. Seed insertion is idempotent by key.

No real business schedule was supplied. Migration defaults are clearly marked editable development defaults: Asia/Kolkata, Monday-Friday 09:00-17:00, 30-minute duration. These are not verified business availability and must be replaced before real bookings. Date/time interpretation in the UI currently assumes the browser's local timezone matches the configured business timezone.

## 9. Installation and local setup

Requirements: Node.js 20.19+ or 22.12+ (Vite 8 compatibility), npm, and a Supabase project.

```powershell
npm install
Copy-Item .env.example .env.local
```

Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` in `.env.local`. Only the publishable key may be exposed to the browser; never put service-role/secret keys in a `VITE_` variable. `.env.local` is ignored by Git.

## 10. Supabase migration and staff provisioning

Apply `supabase/migrations/202610240001_initial_schema.sql` to the intended project using Supabase CLI or the SQL editor. Do not apply against production until reviewed. The migration itself seeds sample rows, so there is no separate seed command. Create the staff Auth identity using a trusted dashboard invite/admin procedure, then run the role promotion SQL comment at the migration end with its Auth UUID as project owner. Do not share the UUID or secrets publicly. Confirm database backup/target before applying.

## 11. Local development and commands

```powershell
npm run dev
npm test
npm run build
npm run preview
```

`npm test` currently passes 4 local unit/component tests. With the configured Supabase client enabled, `npm run build` passes TypeScript and Vite bundling; the main JavaScript chunk is 533.42 kB minified (Vite reports its 500 kB advisory). The compressed bundle is 153.21 kB. These checks do not verify live Supabase workflows.

## 12. Deployment

No Vercel project is connected or deployed. For a future deployment, configure the two public Supabase Vite variables in Vercel, add the deployed domain to Supabase Auth URL configuration, apply reviewed migrations to the target project, provision staff securely, and then verify OTP, RLS, booking conflict, and dashboard flows. Do not claim production readiness until those checks pass.

## 13. Known limitations and future work

- Migration is not applied and SQL has not been executed against PostgreSQL.
- No real OTP, email delivery, RLS, concurrent booking, or staff login has been tested.
- No responsive browser viewport matrix has been run.
- Confirmation/update emails and reminders/no-show notifications are not implemented.
- Browser date display assumes browser and configured business timezone align.
- Supplied availability is absent; current defaults are development-only.
- Workspace is not a Git repository.

Next: configure `.env.local`, review/apply the migration to the intended non-production project, provision staff securely, and run backend-focused tests using the manual procedure in `docs/TESTING.md`.
