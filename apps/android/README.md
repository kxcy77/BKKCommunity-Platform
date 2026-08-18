# BKK Community Android

Jetpack Compose Android app for API 26+. It requires authentication before platform access and implements five-tab navigation, Room public-content caching, accounts, six-digit password reset, online-only RSVP, local reminders, FCM inbox/deep links, profile/preferences/history and account deletion.

Open this folder directly in Android Studio. See `OPEN_IN_ANDROID_STUDIO.md` and the root `docs/SETUP_AND_DEPLOYMENT.md`.

```bash
./gradlew testDebugUnitTest lintDebug assembleDebug
```

Do not distribute a build until it points to the verified HTTPS API and has fresh build, device and accessibility evidence. Negative-ID records are demonstration content and cannot be RSVP'd to.
