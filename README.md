# EmbraceAI

EmbraceAI is the research prototype for the EMBRACE-AI project. It is a guided
relaxation app for adults living with cardiovascular conditions, for use in the
time around appointments and test results. A study portal lets the research
team manage participants.

Each session follows five steps: **check-in → tailoring → practice →
reflection → follow-up**.

**Live prototype**

| | Address | Sign-in |
|---|---|---|
| Participant app | https://embrace-ai-prototype-2026.web.app | Participant ID and access key, or a one-time link or QR code |
| Staff portal | https://embrace-ai-staff.web.app | Staff email and password |

Both are built from the same code. They have separate addresses so that each
keeps its own browser sign-in; a staff member can test a participant link
without being signed out of the portal.

## Features

### Participant app

- **Sign-in.** Participants sign in with a study-issued Participant ID and
  access key, or with a one-time link or QR code. The link is on the app's own
  address (`…web.app/?signin=…`), and the app explains when a link has expired
  or was already used. The app never asks for a name, phone number, email
  address or medical record number.
- **Consent.** Participants give informed consent before first use. The consent
  screen includes the medical disclaimer.
- **Baseline questionnaire (Appendix A).** Participants complete it before
  their first session. It covers demographics and health information.
- **Guided session:**
  1. A medical disclaimer that cannot be skipped.
  2. A safety check.
  3. A check-in: current feeling, stress level (0–10), choice of practice, and
     length (a short 3:20 version or the full practice).
  4. The practice itself. The participant chooses one of two 8-minute scenes:
     Vietnamese countryside, or a beach from dawn to night. Each has spoken
     guidance and optional background sound (countryside, ocean or rain).
  5. Post-session feedback, and an optional question for the care team.
- **Accessibility during a session.** Captions, a breathing guide, an easier
  view, a brighter picture, reduced motion, and support for large text.
- **Journal and insights.** Mood entries with prompts, a 14-day mood trend,
  and the participant's current streak.
- **Final questionnaire (Appendices B–D).** Staff open it at the end of the
  programme. It covers:
  - B: anxiety (GAD-7, which also yields a GAD-2 score) and emotional
    well-being;
  - C: experience measures;
  - D: open-ended feedback.

  Participants can save a draft and return to it later.

### Staff portal

- **Roles.** There are three roles: `admin`, `coordinator` and `researcher`.
  The database enforces them through Row Level Security.
- **Participant accounts.** Staff create pseudonymous participants. Each
  receives a Participant ID, an access key and a one-time sign-in QR code.
  "Copy invitation" produces a ready-to-send message with all three.
- **Reissuing access.** Access keys are stored only as hashes and cannot be
  shown again. Reissuing therefore creates a new QR code **and a new access
  key**; the previous key stops working, and devices already signed in stay
  signed in.
- **Study tracking.** Staff track consent, baseline and final-assessment
  status, and session counts, and open the final questionnaire.
- **Audit log.** Privileged actions are recorded.

## Data and privacy

- Participants are identified only by a random Participant ID.
- **Stored in Supabase:**
  - consent;
  - questionnaire responses, including their free-text answers;
  - every completed session: time, mood after, and whether a reflection was
    written;
  - the note of each session saved to the journal (reflection, question for
    the care team, stress before and after). Row Level Security lets only the
    participant read it, and the staff portal does not show it, but Supabase
    project administrators can see it.
- **Kept only in the participant's browser:**
  - journal entries written with **New entry**;
  - settings.
- Firebase serves static files only. It does not store study data.
- Never commit `config/supabase.json` or any service-role key. The file is
  listed in `.gitignore`.

See [docs/CRM_SETUP.md](docs/CRM_SETUP.md) for the full access model.

## Tech stack

- **App:** Flutter 3.41 (Dart 3.11), `provider`, `video_player`
- **Backend:** Supabase: Auth, Postgres with Row Level Security, and Edge
  Functions
- **Hosting:** Firebase Hosting, two static sites built from the same code
- **Design:** a shadcn-style theme in `lib/core/theme.dart` (neutral surfaces,
  one teal accent, flat bordered cards)
- **Media:** videos and audio stored with Git LFS

## Getting started

### 1. Clone with media

Install [Git LFS](https://git-lfs.com/) first. Then clone:

```bash
git lfs install
git clone https://github.com/DinhQuocVinh123/EmbraceAI.git
```

Check that the files in `assets/video/` and `assets/audio/` are several
megabytes each. If they are about 130 bytes, they are LFS pointer files; run
`git lfs pull` to download the real media.

### 2. Configure Supabase

```bash
cp config/supabase.example.json config/supabase.json
```

Fill in the project URL and the publishable key. Without this file, the app
opens a setup screen instead of the sign-in screen.

### 3. Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/supabase.json
```

To run the staff portal instead, add `--dart-define=APP_SURFACE=staff`.

### 4. Check

```bash
flutter analyze
flutter test
```

### 5. Build and deploy the web apps

```bash
dart run tools/build_web.dart          # builds build/web and build/web_staff
firebase deploy --only hosting --project embrace-ai-prototype-2026
```

`firebase deploy` also rebuilds each app before uploading it. To deploy one
app only, use `--only hosting:participant` or `--only hosting:staff`. The
surface is chosen at build time with `--dart-define=APP_SURFACE=staff`; the
default is the participant app. The staff build leaves out the session videos.

### 6. Deploy database and Edge Function changes

```bash
npx supabase db push
npx supabase functions deploy create-participant reissue-participant-access --use-api
```

Deploy the Edge Functions and the web apps together when a change touches
both, such as the sign-in link format.

## Project structure

```
lib/
├── core/       # Theme, motion settings, backend configuration
├── data/       # Session script, journal repositories, country list
├── models/     # Moods, session beats, consent, questionnaires, participants
├── screens/    # Participant screens and the staff portal
├── services/   # Supabase calls, credential handling, journal prompts
├── state/      # Auth, session playback, journal and settings stores
└── widgets/    # Session UI, prompts, charts, cards
supabase/
├── migrations/ # Database schema, RLS policies, SQL functions
└── functions/  # Edge Functions: create-participant, reissue-participant-access
assets/         # Session videos (8 min each) and ambient audio
tools/          # Voice, video and accessibility scripts, web build helper
test/           # Unit, widget and golden (screenshot) tests
docs/           # Specifications and guides (see below)
.claude/skills/ # UI rules for AI coding assistants (embrace-ui)
```

## Documentation

| Document | Contents |
|---|---|
| [prototype-spec.md](docs/prototype-spec.md) | Prototype scope and requirements |
| [session-flow.md](docs/session-flow.md) | Step-by-step session flow |
| [beat-sheet.md](docs/beat-sheet.md) | Fixed timings for the 8-minute session videos |
| [CRM_SETUP.md](docs/CRM_SETUP.md) | Supabase setup, access model, staff portal |
| [FIREBASE_HOSTING.md](docs/FIREBASE_HOSTING.md) | Web hosting |
| [wcag-audit.md](docs/wcag-audit.md) | WCAG 2.2 colour contrast audit |
| [low-vision-guide.md](docs/low-vision-guide.md) | Guide for participants with low vision |
| [tools/voice/README.md](tools/voice/README.md) | Building the narration track |

## Testing

`flutter test` runs:

- unit tests for models, stores and the session controller;
- widget tests for the session flow, study forms, staff portal, and the
  separation of the two sites, including phone-size layouts;
- WCAG 2.2 contrast checks for light and dark themes;
- design-system rules (`test/design_system_test.dart`): screens take colours
  and corner radii from the theme instead of hard-coding them;
- golden screenshot tests.

The golden images are rendered with Windows system fonts. Regenerate them on
Windows with `--update-goldens`.
