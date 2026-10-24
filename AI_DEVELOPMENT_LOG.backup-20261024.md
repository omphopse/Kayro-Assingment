# AI Development Log

This is a supplementary record of work performed in this repository, not a complete transcript of the Codex conversation. See `docs/AI_CHAT_LOG_EXPORT.md` for preserving the original transcript. Sensitive credentials, OTPs, tokens, and private personal information must not be recorded here.

## Initial state

- Date: 2026-10-24 (user-provided client date; timezone Asia/Calcutta).
- User instruction: Begin Phase 0 for the Nutritionist Call Booking Platform assignment. Inspect the repository first, record the initial development log entry, prepare the project and Supabase setup checkpoint, and stop at that checkpoint.
- Repository inspection: `C:\Users\Asus\Documents\AppointmentBooking` contained no files. `git status --short --branch` reported `fatal: not a git repository (or any of the parent directories): .git`.
- No application code, package manifest, tests, Supabase project configuration, service credentials, email configuration, or deployment settings were present.
- User-provided assignment brief was read from the pasted text attachment. Its intended test email, `omphopse96@gmail.com`, appears incomplete or invalid and must be confirmed before authentication testing.
- No clarifying question has been asked; no user answer or correction has been received.
- No tests or application features have been run or implemented at this initial entry.

## Entries

### 2026-10-24 — Phase 0 documentation

- Work: Added `RULES.md`, `IMPLEMENTATION_PLAN.md`, this log, `README.md`, `docs/SUPABASE_SETUP.md`, and `docs/AI_CHAT_LOG_EXPORT.md`.
- Decisions: Preserve the required phase order; stop before Supabase-dependent integration/E2E testing until the user confirms setup. Treat the supplied email as unconfirmed, use a configurable test address, and never hardcode it. All product/backend capabilities described in documentation are planned, not implemented.
- Testing: None run. Phase 0 created documentation only; no feature code exists yet.
- Issues found: Workspace is empty and not a Git repository. This is recorded as initial state; no corrective action was needed.
- Open issues: Supabase setup and user's confirmation; confirm a valid test email before auth testing; later select/provision nutritionist identity and availability without inventing real details.

## Decision register

| Decision | Reason | Status |
| --- | --- | --- |
| Stop at the Phase 0 Supabase setup checkpoint | Explicit assignment requirement | Complete after user's Phase 1 setup confirmation |
| Use configurable test email; do not substitute the supplied address | Keep personal/test address out of source; syntax is valid | Active |
| Do not claim application, backend, email, tests, or deployment are operational | None are present/configured at inspection | Active |
| Keep credentials and OTPs out of chat and logs | Security requirement in assignment | Active |

## Open issues

- User reports Supabase project and email OTP setup are complete; public URL/publishable key are now in local `.env.local`. Apply the migration before backend integration checks.
- Test email syntax passes, but inbox access and delivery are unverified.
- No live migration/OTP/RLS/concurrency result or Vercel deployment is currently available.

### 2026-10-24 — Phase 1 start and MVP work

- User instruction: Continue in this folder; inspect Phase 0 artifacts; build a React/Vite/Tailwind/Supabase MVP with client and nutritionist experiences; preserve and seed the assignment's five sample appointments; use `omphopse96@gmail.com`; implement RLS, role provisioning and race-safe booking; test incrementally; update docs and PDF. User stated the Supabase project and email OTP setup were complete.
- Inspection: Phase 0 files were present; no app scaffold, `.env.local`, Supabase migration, or project credentials were present in the workspace. The project folder remains non-Git.
- Implementation: Added Vite/React/TypeScript/Tailwind app, landing/booking/client appointment/nutritionist screens, Supabase client placeholders, migration with RLS and guarded RPCs, slot conflict indexes/constraints, idempotent sample records, manual staff booking, staff schedule editor, unit/component tests, setup/architecture/testing/project/correction docs, and required PDF/source.
- Correction: Phase 0 said the test email appeared malformed. That statement was too strong: the app's email syntax test accepts `omphopse96@gmail.com`. No inbox control or actual message delivery was tested; no OTP was sent.
- Initial tests: `npm test` passed (2 files, 4 tests). First `npm run build` failed with missing React declaration types (`TS7016` for `react`, `react-dom/client`, `react/jsx-runtime`), missing `ImportMeta.env`/CSS types, and unused imports. Added React types, Vite client declarations, and removed unused imports. Subsequent build passed.
- Final checks before public config was active: `npm test` passed, 2 files / 4 tests; build passed with a 316.43 kB main bundle. After public project config was safely added, final `npm run build` passed with a 533.42 kB main bundle (153.21 kB gzip) and a Vite advisory above its 500 kB threshold. The configured build is the relevant result.
- Browser smoke: Local app rendered at approximately 1265 x 715. Landing screenshot inspected. Accessibility trees for `/book`, `/appointments`, and `/nutritionist` displayed expected route/form content. No OTP, database, or backend request was made. The required mobile/tablet viewport matrix was not tested.
- Open issues: migration not applied; live RLS/OTP/email/concurrency/staff flows unverified; date display assumes browser timezone aligns with configured business timezone; notifications/reminders not implemented; responsive viewport matrix not run; no deployment.
- Decision register update: Use the user's reported project setup, but do not infer live connectivity from that report. Keep public keys in ignored `.env.local`; keep service-role secrets out of client code and chat; treat business hours as editable development defaults.
- Follow-up configuration correction: Later found public project values in `.env`; copied only the URL and publishable key into ignored `.env.local`. The first write accidentally omitted the newline between the two variables; the first read-only query failed URI parsing before an HTTP request. Rewrote two separate lines, then retried. The REST endpoint returned HTTP 404 for `business_settings`; no response body or secrets were logged. Migration is not applied/available through that query.
- Test-email source correction: A requirements review found the supplied test address had been embedded in a validation test. Replaced the test cases with generic sample emails; the address remains configurable and is absent from application/test source. Reran `npm test` (4 passed) and `npm run build` (passed; 533.42 kB main chunk advisory).
- Final documentation update: Added the local config formatting issue and HTTP 404 evidence to the maintainable PDF source, reduced the PDF from two pages to one, rendered and visually inspected it, and checked that all six required headings are present.

### 2026-10-24 — Nutritionist availability save repair

- User report: Saving dashboard availability returned `DELETE requires a WHERE clause`; the manual appointment time selector had no available choices.
- Root cause: `save_business_schedule` deleted every `weekly_availability` row without a predicate, which the configured database safe-update guard rejects. The screenshot's selected date is Sunday while Sunday is unchecked in the schedule, so that date also correctly had no slots.
- Changes: Added forward migration `202610240002_fix_schedule_delete_where.sql` using the constrained weekday range in the delete predicate, preserved the staff-role check and existing RPC grants, and fixed the initial schema definition for fresh installs. Manual appointment slots now refresh after a successful schedule save and when the date/form is opened; the empty selector explains when no slots exist.
- Validation: `npm test` passed (2 files, 4 tests); `npm run build` passed with the existing Vite bundle-size advisory (536.46 kB minified main chunk).
- Remaining verification: The forward migration has not been applied to the connected Supabase project, and no live save/slot/appointment operation was run. For the screenshot's Sunday booking, enable Sunday and save the availability before choosing a time.

### 2026-10-24 — Nutritionist dashboard date filter

- User request: Add a way to show appointments for a particular date alongside the existing Today and All views.
- Changes: Added an accessible date picker to the dashboard filters. Selecting a date filters appointments to that local calendar day; clearing the date shows all, and the existing Today/All toggle clears the specific date filter. Added responsive styling for the control.
- Validation: `npm test` passed (2 files, 4 tests); `npm run build` passed with Vite's existing bundle-size advisory (536.83 kB minified main chunk).

### 2026-10-24 — Responsive alignment and button sizing

- User report: Dashboard controls were misaligned and differently sized across the supplied desktop and narrow-view screenshots.
- Changes: Standardized compact buttons and dashboard date/today controls to consistent touch-friendly heights, centered the desktop filter row, arranged search and filters cleanly at tablet widths, aligned the date and Today/All controls at mobile widths, and increased small appointment action targets.
- Validation: `npm test` passed (2 files, 4 tests); `npm run build` passed with Vite's existing bundle-size advisory (536.83 kB minified main chunk).
