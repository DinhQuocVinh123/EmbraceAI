# Firebase Hosting

The Flutter web build is deployed as a static single-page application.

## First deployment

```powershell
flutter build web --release
npx firebase-tools login
npx firebase-tools deploy --only hosting
```

The repository is linked to the `embrace-ai-prototype-2026` Firebase project in
`.firebaserc` so later deployments use the same site.

## Later deployments

```powershell
flutter build web --release
npx firebase-tools deploy --only hosting
```

Hosting serves files from `build/web`. All application routes fall back to
`index.html`, while large video and audio assets receive a one-day browser cache.

The public test site must contain demo data only. Journal and settings data are
stored in each browser and are not synchronized between testers.
