# Testing

## Commands

- `npm test` — Vitest unit/component tests.
- `npm run build` — TypeScript project checks and Vite production bundle.

## Results

This section is updated after real commands are run. No live Supabase test result is inferred from a successful local build or unit test.

| Check | Status | Evidence |
| --- | --- | --- |
| Unit/component | Passed | `npm test` - 2 test files, 4 tests passed |
| Production build | Passed with advisory | `npm run build` - `tsc -b` and Vite v8.3.5 completed; main chunk 533.42 kB minified (153.21 kB gzip), over the 500 kB advisory threshold |
| Supabase migration/RLS | Blocked | Public project config is present in ignored `.env.local`; read-only query returned HTTP 404 for `business_settings`; migration not applied |
| OTP email delivery | Not tested | No OTP sent; supplied address ownership/delivery unverified |
| Booking/concurrency | Not tested | Requires migration on configured PostgreSQL/Supabase |
| Nutritionist auth/workflow | Not tested against backend | Requires a securely provisioned staff Auth identity |
| Browser smoke inspection | Passed (limited) | Local app rendered at approximately 1265 x 715; landing screenshot inspected; `/book`, `/appointments`, and `/nutritionist` accessibility trees showed expected forms. No OTP or backend request was submitted. |
| Responsive viewport matrix | Not tested | No exact 320-1440 width matrix was run; narrow layouts remain visually unverified |

## Manual viewport procedure

When browser automation is available, inspect 320, 360, 375, 390, 414, 768, 1024, 1280, and 1440 CSS-pixel widths. Check horizontal overflow, nav, date/form controls, cards, status control, tables at narrow widths, keyboard focus, and reduced motion. Record only widths actually inspected.

## Backend cases required before claiming verified

Apply the migration to a non-production test project and test signup/OTP, invalid/expired OTP, own-row RLS, another client's row denial, client status mutation denial, staff role checks, slot past/unavailable rejection, duplicate submit, simultaneous same-slot requests, cancel release, reschedule rollback on collision, staff booking collision, legacy sample privacy, and sample seed idempotence.
