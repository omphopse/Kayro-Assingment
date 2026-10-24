# Project Rules

These rules apply throughout the Nutritionist Call Booking Platform assignment.

## Product and implementation

- Inspect existing files before changing them. Preserve existing user work.
- Follow the phase order in `IMPLEMENTATION_PLAN.md`. The user has confirmed a Supabase project and email OTP setup; before live checks, ensure local public project values are configured and never ask for or expose secret keys.
- Keep client booking and nutritionist management within one coherent, accessible, mobile-first wellness product.
- Do not invent a nutritionist identity, credentials, prices, testimonials, medical claims, or availability. Clearly label editable demo content.
- A slot selection is not a booking. Only an authoritative backend operation may confirm a booking; prevent conflicts in the database/backend.
- Never simulate production OTP verification or expose private client information, credentials, OTPs, API keys, or session tokens.
- Treat date-only values as dates, not UTC timestamps. Display appointment times consistently in the user's local timezone.
- Use configuration placeholders for secrets and never ask for secrets in chat.

## Security and data

- Use Supabase Auth and PostgreSQL Row Level Security for the planned backend.
- Make authorization checks server-side and minimize access to personal data.
- Keep service-role keys and other secret keys on trusted server-side infrastructure only. A publishable/anon key is designed for client use with correct RLS policies.
- Validate all user-provided data on the server, including email, phone, appointment state, and requested slot.
- Do not claim security controls are effective until they are implemented and verified.

## Quality and reporting

- After each implemented feature, run the relevant checks, inspect the result, fix failures, and record actual commands and outcomes in `AI_DEVELOPMENT_LOG.md`.
- Do not run Supabase-dependent integration or end-to-end tests until the user confirms the setup checkpoint.
- Do not add or run tests unless asked by the user or required by the project brief. The project brief explicitly requires tests after implemented features.
- Do not claim that tests, email delivery, deployment, or user interactions succeeded without evidence.
- Maintain an open-issues section and decision register in the development log. Record new issues separately from their resolutions.
- Keep documentation aligned with the actual implementation and clearly mark planned work, assumptions, and limitations.
- Do not include sensitive values in logs, screenshots, documentation, or chat transcripts.

## Design and accessibility

- Use a warm cream background, bold dark typography, vivid lime actions, orange-red accents, thick borders, hard shadows, and restrained hand-drawn decorations.
- Preserve readability, adequate contrast, visible keyboard focus, accessible labels, touch-friendly controls, and `prefers-reduced-motion` support.
- Prefer original lightweight CSS/SVG details over clutter or generic gradients.
