# BKK continuation record — 12 October 2026

## What changed

- The existing `kingkg256@gmail.com` production account was granted the admin role after explicit approval. Its password was not changed. Existing API sessions for that account were revoked and an admin audit entry was written. An actual admin website sign-in still requires the account owner to enter the password or finish the emailed reset flow.
- Android now queues token registration and incoming Firebase messages in WorkManager. Before showing a message it checks the active member, intended recipient, notification preferences, and, for events, attendance. Local reminders check attendance and the original event start time before displaying. Signing out or deleting the account clears personal notices and pending work.
- The PHP service now has an FCM HTTP v1 sender, a notification queue worker, bounded retries, provider message IDs, invalid-token handling, and fresh eligibility checks before sending. It leaves cloud delivery disabled by default. The worker preflights its configuration when enabled, so an incomplete Firebase setup fails startup rather than appearing healthy.
- Website public assets use a network-first service-worker policy so an old CSS cache cannot mask a deployed calendar change. Authenticated pages and API responses remain outside that cache.
- Android registration and password reset now explain the server's minimum password rule: at least eight characters with a letter and a number.

## Checks actually completed

- Android: `testDebugUnitTest`, `lintDebug`, and `assembleDebug` passed with JDK 21. Eleven JVM unit tests passed. Lint emitted warnings but no errors. A fresh debug APK was built; it is not a signed release.
- PHP: nine mocked transport assertions passed. Eleven transactional MySQL assertions passed, including a queue of 501 eligible offers; fixtures were rolled back. The full local web smoke suite and separate admin, member, and API integration suites passed against disposable local MySQL.
- Email: a real reset message to `kingkg256@gmail.com` was marked Delivered in Resend, and the account owner confirmed it arrived. Completion of the code, new password, and subsequent sign-in has not yet been observed.
- Production: the Railway `/api/v1/ready` endpoint reported a connected database on the previous deployed commit. The new notification code and cache change are not production evidence until their exact commit is deployed and checked.

## Still required for a live release claim

- The Firebase console is showing “An error occurred while loading the Terms of Service acceptance status”. No BKK Firebase project or `google-services.json` has been created. Register both the release package `za.co.bkkcommunity.app` and debug package `za.co.bkkcommunity.app.debug` in the project. Keep the JSON out of Git.
- Place a Firebase service-account JSON only in secure Railway configuration as `FCM_SERVICE_ACCOUNT_JSON` (or a protected file path in `GOOGLE_APPLICATION_CREDENTIALS`). Set `FCM_ALERTS_SINCE` to the UTC activation timestamp, then set `FCM_ENABLED=true`. The cutover timestamp prevents old demonstration discounts from broadcasting. Do not enable delivery before checking real recipients and content.
- Install the Firebase-configured APK on a physical Android device with Google Play services. Test token registration, permission denial, a genuine new discount, an attending event within 24 hours, a cancelled RSVP, a rescheduled event, sign-out, and tap destinations. A provider HTTP 200 means FCM accepted a message; only on-device receipt proves delivery.
- No Android emulator system image or attached phone was available for this run. API 26, current Android, TalkBack, font scaling, and physical notification checks remain open.
- Actual shop offers, events, and service details must be approved by BKK before replacing demonstration content. The deployed API still reported no events and three sample discounts during this investigation.

## Configuration and release notes

The new queue schema is added by `services/web/database/migrations/008_notification_retries.sql`. The normal web startup runs migrations before serving traffic. `FCM_ENABLED` defaults to `false`, so deployment of this code does not start sending messages. Local or CI tests use fixture credentials and never make a real FCM request. Do not copy Firebase keys, reset codes, or member passwords into this repository or screenshots.
