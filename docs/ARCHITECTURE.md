# Architecture

## Current shape

The React + Vite + TypeScript SPA has public landing and booking routes, client appointment access, and a separate staff sign-in/dashboard. The UI uses the same Supabase project through the publishable key configured in `.env.local`; no secret/service-role key is read by Vite. Unconfigured backend paths show an explicit error instead of creating fake sessions or bookings.

## Data model

`supabase/migrations/202610240001_initial_schema.sql` creates `user_roles`, `business_settings`, `weekly_availability`, `appointments`, and `appointment_events`. Auth users default to the client role. Staff privileges are assigned by an administrator to an existing Auth user; public signup cannot grant staff status.

Appointments can be linked to an Auth user or remain unlinked staff-managed records. Sample rows have `source='sample'`, stable `sample_key`s, no fabricated auth users, and nullable phone data. RLS only permits clients to read rows whose `client_user_id` matches their session. Staff can read all rows. History is restricted to staff.

## Authorization and mutation

RLS is enabled for all application tables. There are no direct client write policies for appointments. Security-definer RPCs validate the signed-in user, role, ownership, status, configured hours, future start time, and input shape. Cancellation, rescheduling, booking, staff booking, claiming matching staff records, and status changes are distinct operations. The dashboard also checks the role before loading staff data; this route check improves UX but is not the security boundary.

## Availability and conflict prevention

Availability is stored as weekly local hours, a configured IANA timezone, and consultation duration. `available_slots(date)` filters past and occupied slots. `create_booking` validates the requested slot again inside a server-side PostgreSQL function. A partial unique index on active appointment `starts_at` plus an exclusion constraint on active time ranges are the final concurrent booking and overlap guards; cancelled rows release the time. Staff bookings use the same constraints. Rescheduling updates one row transactionally, so a conflict rolls back and retains the old time.

The migration seeds editable **development defaults** of Monday-Friday, 09:00-17:00 Asia/Kolkata with 30-minute slots. These are not claims about real business availability; change the config before using the application for real appointments. Actual concurrent calls have not been tested against a live Supabase project.

## Known architecture gaps

- The dashboard currently has status updates and appointment search/filter, but manual appointment creation and availability editing remain to be built.
- Client reschedule controls exist but the UI does not yet offer new slot selection; the database RPC is implemented.
- Confirmation/notification email delivery beyond Supabase OTP is not implemented.
- Staff authorization/provisioning procedure is documented in the SQL comment and setup guide; no real staff account has been provisioned.
- The migration has not been applied to Supabase, and its SQL has not been executed in a live PostgreSQL environment.
