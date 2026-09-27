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

## Apply the database migration

Use the Supabase SQL Editor to run:

`supabase/migrations/20260926000100_crm.sql`

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

## Build and host

```powershell
flutter build web --release --dart-define-from-file=config/supabase.json
firebase deploy --only hosting --project embrace-ai-prototype-2026
```

Before collecting research data, review the ethics protocol, approved hosting
region, retention schedule, authorised staff list, backup policy, and incident
response process.
