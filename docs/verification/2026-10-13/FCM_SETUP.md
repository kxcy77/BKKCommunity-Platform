# Android cloud-notification verification — 13 October 2026

## Confirmed

- The user-supplied Android `google-services.json` matches both Android package names and Firebase project `com-example-myapplicatio-45f5e`. The file is local and Git-ignored.
- The API 26 Google-services emulator initially could not resolve Firebase hosts. Restarting that test emulator with explicit DNS restored validated internet access. This was an emulator-network repair, not an Android app code fix.
- After restart, Firebase initialized and the emulator cached an FCM token for the configured sender. The token value was not printed or saved in this report.
- A service-account JSON downloaded by the project owner matched the Android project. Its file permissions were restricted to the local user. Google's OAuth endpoint accepted a messaging-scoped access-token request.
- One test data message was sent directly to that emulator token. FCM accepted it, and Android logcat showed `PushWorker` starting and completing successfully. The app was signed out, so the worker appropriately did not display a member notification. This is transport and receipt evidence, **not** signed-in display evidence.
- The web smoke suite, PHP syntax checks, and GitHub PHP/MySQL/Android/secret-scan jobs passed for the project-matching server guard. Pull request [#11](https://github.com/kxcy77/BKKCommunity-Platform/pull/11) was merged.
- Railway stores `FCM_PROJECT_ID` and `FCM_SERVICE_ACCOUNT_JSON` as private variables, with `FCM_ENABLED=false`. The guarded web build deployed successfully; public `/health` reported `ok` and `/ready` reported a connected database.

## Not yet proved or released

- No signed-in Android phone has shown an actual BKK notification from the server queue. The direct emulator test did not exercise a logged-in session, member preferences, the queue, or notification-permission denial.
- The current downloaded key is a long-lived Firebase Admin SDK service-account key. Before enabling production pushes, replace it with a dedicated account limited to the Firebase Cloud Messaging API Admin role, rotate the broader key, and keep both files out of Git and screenshots.
- Do not set `FCM_ENABLED=true` or a cutover time until approved non-demo content and a controlled device/permission/sign-out/cancellation test are complete. Sample discounts and demonstration events must never trigger member alerts.
- A signed Android release build and physical-device evidence remain separate release gates.
