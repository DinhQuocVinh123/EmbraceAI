# EmbraceAI CRM setup

The CRM uses Supabase Auth, Postgres, Row Level Security, and Edge Functions.
Firebase remains static hosting only, so the Firebase project can stay on the
no-cost Spark plan.

Do not enter patient names, initials, dates of birth, medical record numbers,
phone numbers, personal email addresses, or combinations of fields that can
identify a participant.

## Access model

- Public sign-up is disabled.
- Authorised staff create pseudonymous participant access in the staff portal.
- Participants receive a random Participant ID and 80-bit access key.
- Supabase Auth stores the password verifier; the access key is shown once.
- Staff can also issue a single-use QR sign-in link. Scanning it opens the
  hosted app, activates the participant, and persists the Supabase session on
  that device. No authenticator app is required.
- Staff can reissue a fresh QR from a participant record when a link expires or
  the participant changes device. The manual ID and access key remain a
  fallback.
- Staff accounts are created by a project administrator.
- Journal text remains on the participant device. The backend receives only
  session time, post-session mood score, a reflection-present flag, and counts.
- Postgres RLS isolates participant records and staff roles. Privileged actions
  are checked again in SQL functions or the Edge Function.

## Create the free project

1. Create a project in the Supabase dashboard on the Free plan.
2. In Authentication settings, keep public user sign-up disabled.
3. Copy `config/supabase.example.json` to `config/supabase.json` and replace the
   placeholders with the project URL and publishable key from Connect.
4. Never put a secret key or service-role key in the Flutter configuration.

## Apply the database migrations

Use the Supabase SQL Editor to run:

Run the migrations in timestamp order:

- `supabase/migrations/20260926000100_crm.sql`
- `supabase/migrations/20260928000100_study_measures.sql`
- `supabase/migrations/20260928000200_multidevice_sessions.sql`
- `supabase/migrations/20260928000300_synced_private_session_journal.sql`
- `supabase/migrations/20260928000400_backfill_session_journal.sql`
- `supabase/migrations/20260928000500_participant_informed_consent.sql`

Alternatively, after installing the Supabase CLI:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy create-participant
supabase functions deploy reissue-participant-access
```

The Edge Function automatically receives `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` from the hosted project. Do not export the service
role key to the browser or mobile app.

Set the production app URL for QR redirects, and set the same URL as
`auth.site_url` in `supabase/config.toml`:

```powershell
supabase secrets set PUBLIC_APP_URL=https://YOUR_HOSTED_APP
supabase config push
```

## Provision the first staff account

Create an email/password user under Authentication > Users in the Supabase
dashboard. Use an institutional staff email. Then run this in SQL Editor,
replacing the email:

```sql
insert into public.staff_profiles (user_id, role)
select id, 'admin'
from auth.users
where email = 'researcher@institution.example';
```

Valid roles are `admin`, `coordinator`, and `researcher`. Only admins and
coordinators can create participants or change account and consent status.

## Study measures workflow

- The first participant sign-in opens a versioned informed-consent screen.
  Participants must acknowledge all four statements before continuing. The
  database records the consent version, timestamp and source for auditability.
  This is study consent, not a generic acceptance of application terms.
- A withdrawn participant cannot enter the program. Staff may record a consent
  decision only when it has been documented outside the app.
- Appendix A is required once, after the participant's first sign-in and before
  the program home screen is available.
- Appendix A stores age and study-approved demographic and health categories.
  It does not request a name, personal contact details, date of birth, or
  medical record number.
- Appendices B, C, and D remain closed until an authorised staff member opens
  the final assessment from the participant detail panel.
- An opened final assessment appears before the home screen. A participant may
  choose `Later` and continue the program; the home screen keeps a reminder
  available until submission.
- All final-assessment items are optional. Unanswered ratings are stored as
  `null`, never as zero.
- The seven anxiety items produce both a GAD-2 score from items 1-2 and a GAD-7
  score from items 1-7. A score is shown only when all items needed for that
  score are answered. Scores are research measures and are not diagnoses.
- Staff can review completion status and collected responses in the participant
  detail panel. The participant detail also shows when and how consent was
  recorded. Questionnaire records include the form version and timepoint so
  a future approved baseline assessment can be added without changing old data.

## Journal and multi-device behaviour

- On-device Journal storage is namespaced by the authenticated Supabase user.
  Signing out removes that Journal store from the widget tree, and signing in as
  another participant opens a different local store.
- Guided-session summaries are fetched from Supabase and merged with the local
  Journal. This lets the same participant see session date and mood in Journal
  and Insights on another device.
- Cross-device sessions use a UUID, not a device-local incrementing number, so
  a phone session cannot overwrite a desktop session.
- Free-text reflections and manually created Journal entries remain only on the
  device where they were written. A remote session therefore appears as a
  read-only summary and explains that its private reflection is on the original
  device.
- Journal entries written by older builds used an unscoped browser key. They
  are deliberately not assigned automatically to the next account that signs
  in, because ownership cannot be established safely.
- Participant progress and CRM lists refresh over HTTPS REST polling (15 and 10
  seconds respectively). The app does not depend on a Realtime WebSocket, which
  may be blocked by hospital networks, mobile browsers, or corporate proxies.

## Build and host

```powershell
dart run tools/build_web.dart
firebase deploy --only hosting --project embrace-ai-prototype-2026
```

This deploys two sites from the same code:

- participant app: https://embrace-ai-prototype-2026.web.app
- staff portal: https://embrace-ai-staff.web.app

Staff sign in only on the staff portal. A staff account opened on the
participant app, or a participant account opened on the staff portal, is shown
the correct address instead of being signed in.

Before collecting research data, review the ethics protocol, approved hosting
region, retention schedule, authorised staff list, backup policy, and incident
response process. The research/ethics team must approve the exact consent text,
consent version and withdrawal procedure before participant enrolment.
