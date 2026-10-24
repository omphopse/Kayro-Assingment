# Clarifications and Corrections

Chronological record of material user clarifications, assumptions, actual AI mistakes, detection, corrections, and evidence. No unobserved mistake is recorded as fact.

## 2026-10-24 — Phase 1 instructions

- **Requirement:** Continue the existing folder; build the React/Vite/Tailwind/Supabase MVP incrementally; preserve Phase 0 work; keep secrets out of the browser; provide tests and documentation; preserve the provided sample appointments and use current assignment date 24 October 2026.
- **Clarification:** User states Supabase project URL/keys are available and email OTP configuration is complete. They were not present at initial Phase 1 inspection; later the public values were found in `.env` and copied into ignored `.env.local` without displaying them or copying any service secret.
- **Assumptions:** Store public Supabase URL/publishable key in ignored `.env.local`; do not request or record a secret key. Use Asia/Kolkata as the clearly labeled editable development timezone because sample data and user context use that zone; actual nutritionist timezone/hours still need confirmation.
- **Email note:** `omphopse96@gmail.com` passes basic email syntax validation. Phase 0's statement that the address appears incomplete was incorrect; syntax does not prove the inbox exists or is controlled. No OTP request was sent.
- **Actual AI correction:** The Phase 0 note that the test email appears malformed was overly strong and has been corrected here. Its syntax passed a local check; actual mail ownership/delivery remains unverified. A later requirements review found that address embedded in a unit test, contrary to the configurable-test-email rule; the test now uses generic sample addresses and the application source contains no hardcoded test address.
- **Build issue and resolution:** Initial `npm run build` failed because React type declarations were absent and three Lucide/router imports were unused. Added React type packages, added Vite client type declarations, removed unused imports, then reran `npm run build` successfully. `npm test` passed (2 files, 4 tests).
- **Configuration issue and resolution:** The first write to `.env.local` omitted a line break, joining the URL and publishable key. The first read-only request failed URI parsing before transmission. Detected from the error, rewrote the file as two separate lines without displaying either value, then retried.
- **Connectivity evidence:** The corrected read-only request to the configured REST endpoint returned HTTP 404 for `business_settings`; no request body was collected. The migration-created table is not available through that query, so do not claim migration/RLS behavior.
- **Unresolved:** Migration execution, SMTP/email delivery, nutritionist profile/hours, and staff Auth UUID are still outstanding. No OTP was sent.
