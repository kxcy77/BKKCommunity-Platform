# Verification matrix

## Automated checks in this handoff

| Component | Check | Result on 13 Aug 2026 |
|---|---|---|
| API | Prisma generation + TypeScript compilation | Pass |
| API | 5 reset/validation/config contract tests | Pass |
| Admin | Inline JavaScript parse | Pass |
| iOS | All Swift source type-check against iPhoneOS SDK | Pass |
| Android | Gradle 9.6.1 launches on embedded JDK 21 with Java 25 daemon criteria | Environment confirmed |
| Android | `testDebugUnitTest`, `lintDebug`, `assembleDebug` with Gradle 9.6.1/JDK 21 | Pass |
| Android UI | Android 36 emulator login launch, scrolling and 200% font reachability | Pass; TalkBack/API 26/physical-device evidence outstanding |
| Xcode | Full asset/application build | Blocked by unavailable CoreSimulator runtime; Swift type-check is the only pass claimed |

## Required scenario coverage

Every major screen must be checked in loading, populated, empty, offline and server-error states. Mutating screens also require validation, working, success and failure states.

### Accounts

- Register valid user; reject duplicate email and weak password.
- Login valid; reject wrong password without revealing account existence.
- Lock after five failures and unlock after the configured period.
- Logout, then prove the old bearer token receives 401.
- Request reset for existing and unknown emails; public responses must match.
- Wrong codes increment attempts; fifth failure invalidates the code.
- Expired/used code fails; successful reset revokes all prior sessions.
- Delete account, then prove profile, attendance, tokens and sessions are gone.

### Content and attendance

- Category filters and detail 404 handling.
- RSVP requires login and live network.
- Repeating RSVP changes updates the existing unique row, never duplicates it.
- Cancellation uses `cancelled` on Android, iOS and API.
- Public cache survives an outage; failed refresh never empties valid Android cache.
- Demo records are visibly labelled and reject RSVP.

### Notifications

- Android 13+ contextual permission allow/deny; earlier Android behaviour.
- FCM token registration and refresh; disabled preference.
- Provider success/failure log; invalid token deletion.
- Event/discount deep links with app cold, warm and backgrounded.
- Local 24-hour reminder schedules only after server RSVP and cancels after cancellation.

### Administration

- Non-admin receives 403 on every admin route.
- Invalid/negative/non-numeric IDs receive 400.
- End-before-start, invalid colour, oversized strings and wrong booleans fail.
- Prevent self-demotion and removal of final admin.
- Create/update/delete each content type and confirm a fresh public read.
- Confirm an audit entry for each mutation without sensitive data.

### Accessibility/UAT

- Screen-reader labels and traversal order.
- 200% font size without clipped content or hidden actions.
- Keyboard/trackpad scrolling and navigation where supported.
- Touch targets, contrast and non-colour status indicators.
- Six elderly participants complete browse, RSVP, directions, reset and contact tasks.
