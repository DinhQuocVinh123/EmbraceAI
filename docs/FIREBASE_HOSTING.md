# Firebase Hosting

The Flutter web build is deployed as a static single-page application.

## Two sites

The project hosts two sites built from the same code:

| Target | Site | Build output |
|---|---|---|
| `participant` | https://embrace-ai-prototype-2026.web.app | `build/web` |
| `staff` | https://embrace-ai-staff.web.app | `build/web_staff` |

The targets are mapped to sites in `.firebaserc`. Separate addresses give each
app its own browser storage, so staff and participant sign-ins do not replace
each other.

## Deploy

```powershell
dart run tools/build_web.dart
npx firebase-tools deploy --only hosting --project embrace-ai-prototype-2026
```

Each target also rebuilds itself before upload (`predeploy` in
`firebase.json`). Deploy one site with `--only hosting:participant` or
`--only hosting:staff`.

All application routes fall back to `index.html`, while large video and audio
assets on the participant site receive a one-day browser cache. The staff build
leaves out the session videos.

The public test site must contain demo data only. Journal and settings data are
stored in each browser and are not synchronized between testers.
