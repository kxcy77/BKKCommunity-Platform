# Registered users and admin-to-Android synchronisation

Verified on 15 October 2026. Supported clients: website and Android.

## Delivered behaviour

- Administrators can open `/admin/users.php` from the sidebar or dashboard user count.
- The read-only directory shows name, email, optional phone, signup platform and registration date, newest first. It supports literal name/email/phone searches, platform filtering and 25-account pages. Deleted accounts are excluded.
- Website registrations record `website`; updated Android registrations submit `platform: "android"`. Missing API platform values and historical accounts remain `unknown`, displayed as **Unknown / legacy**. Login and profile edits do not rewrite the original signup platform. Platform is informational client metadata, not a security credential.
- Migration `011_user_signup_platform.sql` adds the column without guessing old origins or changing existing profile data. Its presence and migration-history entry were checked on Railway.
- Android refreshes on startup, login, content-section entry, resume and at 30-second intervals while authenticated and resumed. Background polling stops when the app is no longer resumed. Concurrent requests for the same session share a refresh; a new login does not reuse an old session's result.
- Events, discounts and services each refresh independently and transactionally. A failed section keeps its saved data and its own last-successful timestamp; other sections can update. A successful empty response removes old records. The screen shows update times and a retry action.
- Successful list refreshes clear corresponding detail fallbacks. A record archived while its details are open becomes unavailable rather than remaining actionable from a stale detail cache.
- A delayed HTTP 401 only clears the token that was rejected, protecting a newer login. This was fixed after repeated live verification exposed the race.
- Admin save confirmations explain publication, expiry and archive visibility. Existing public eligibility rules remain in place.

## Executed checks

- PHP smoke suite passed, including guest protection for the new page and administrator access.
- Disposable MySQL tests passed for website, Android and legacy signup origins; optional phone; duplicate email; invalid platform; cross-platform login; guest/member denial; private responses; search; filters; empty results; malformed queries; and pagination.
- Existing MySQL administrator, member and API integration suites passed. Admin create/edit/archive operations were compared against the website and Android JSON endpoints for events, discounts and services. Expired discounts remained hidden.
- Android unit tests: **13 passed**.
- Android API 26 emulator suite: **15 cases, zero failures/errors, one intentional skip**. The skipped case requires an explicitly supplied temporary administrator and was executed separately against production below. The other 14 cases include independent refresh failure, cache replacement, offline RSVP failure, concurrent refresh coalescing, fresh-token protection, login navigation, and connection-warning/retry rendering.
- Opt-in production test `LiveContentSyncTest`: **passed**, total test duration **82.107 seconds**. It signed in through the real admin website and Android API, created temporary records, observed them in Android, updated all three content types through admin forms, waited for automatic foreground refresh without pressing Refresh, and compared the website results. The update assertion allowed 35 seconds including network time for a 30-second polling interval. Archiving all three records removed them from the website and Android; the event detail already open became unavailable.
- The temporary production administrator and its sessions were removed. Verification records were archived. The verification discount was flagged internally and backdated to exclude it from the notification queue; it was not a real merchant offer.
- The debug APK was built and installed on the API 26 emulator. Its API base is `https://bkkcommunity-platform-2-production.up.railway.app/api/v1/`.

## Screenshot and log evidence

The following saved screenshots were captured from the running Android emulator against Railway:

- [Event before the admin edit](screenshots/android-event-before.png)
- [Updated event after automatic refresh](screenshots/android-event-updated.png)
- [Open event details](screenshots/android-event-detail.png)
- [Open details after the administrator archived the event](screenshots/android-event-withdrawn.png)

[Connection-warning UI](screenshots/connection-warning-controlled-ui.png) is a **controlled UI test**, not a claim that the production network was disconnected. It checks the saved-data warning and functioning Retry action. Repository failure and offline RSVP tests separately exercised failed requests.

Browser screenshots of the registered-user directory, administrator save confirmation and corresponding public event listing were also captured in the working conversation using a disposable **local MySQL environment**. They are local UI evidence, not screenshots of real production members. Local verification accounts contain synthetic `.test` addresses and example phone values.

Logs: [web smoke](web-smoke.log), [Android build](android-build.log), [emulator suite](android-connected.log), [separate live synchronisation test](live-android-sync.log). Build logs include existing Gradle/AGP deprecation warnings; the builds completed successfully.

## Deployment and APK

The production backend was deployed from GitHub and reported healthy with its database connected. Production runtime at commit `1371c53` was compared against the later tested source: backend runtime files matched. The deployment-check workflow now compares backend runtime content rather than falsely demanding that Android-only commits trigger a Railway rebuild.

APK: **BKK Community 1.1.0-debug**, version code **2**, signed with the development key for testing. SHA-256:

```text
803c2670b9912d01a382b65e38942ef8586a89dc568c9b7d108bb1358daede58
```

Install the updated APK to obtain these Android changes. Previously installed builds do not acquire new client code through a backend deployment.

## Limits of this evidence

- Updates are polling-based; slow networks can add delay. The app does not promise instantaneous delivery or successful offline RSVP.
- Older accounts cannot be assigned a reliable historical signup platform. Older Android builds that omit the field continue to register as unknown.
- Current-version Android and a physical handset were not tested during this update; the emulator run used API 26.
- Background/resume lifecycle behaviour is implemented through `repeatOnLifecycle(RESUMED)`; a separate timed background/resume or physical reconnect experiment is not included in the screenshots above.
- This work does not verify merchant permission, authentic BKK content, or previously configured phone-notification delivery. Existing sample records are separate from the synchronisation fix.
- The directory does not provide account editing, deletion or role changes.
