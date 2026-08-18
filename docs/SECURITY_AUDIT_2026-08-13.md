# BKK Community Full-App Security and Stress Audit

> Historical baseline: this report describes the unsafe source bundle before remediation. See `REMEDIATION_STATUS_2026-08-13.md` for the cleaned handoff status. Old paths and findings below are preserved as audit evidence, not current claims.

Date: 13 August 2026  
Review scope: `BKK-Community-FullBundle.zip`, the latest password-reset handoff, Android, iOS, Node/Express API, HTML admin dashboard, and the deployed Railway PHP website  
Verdict: **NOT RELEASE READY**

## Executive verdict

The project can compile, and the deployed PHP website survived a small read-only load probe. Those facts are real positives. They do not compensate for the release blockers below.

The current bundle is unsafe to distribute and cannot provide a trustworthy end-to-end application:

- Production-class secrets and a known-password admin bootstrap script were included in the shared ZIP.
- Android and iOS can accept arbitrary credentials during a network failure and present the user as signed in.
- None of the Android, iOS, or admin clients points to an operational deployed `/api/v1` service.
- The admin dashboard JavaScript does not parse, so none of its functionality can run.
- The API's database migrations do not match its Prisma schema, and its Docker command skips migration deployment.
- Android's six-digit reset UI is disconnected from the reset screen and still validates a legacy 64-character token in its deep-link path.
- Push delivery is simulated but reported as dispatched.
- Required end-to-end, device, accessibility, notification, and elderly-user UAT evidence does not exist.

This is a functional prototype with good visual and structural work. It is not yet a secure, deployable product.

## Audit boundaries

Reviewed:

- Static code and configuration across all four bundled codebases.
- Secret and archive hygiene without exposing secret values.
- Reproducible builds and the available local tests.
- API production dependency audit.
- Admin JavaScript parsing.
- API/client protocol compatibility.
- Live Railway website availability, headers, and a bounded read-only load probe.

Not performed:

- Destructive or authenticated penetration testing against production.
- Account creation, contact submission, password resets, or database writes on the live site.
- High-volume denial-of-service testing against Railway.
- Real SMTP delivery, Firebase delivery, or token refresh testing because valid external configuration was not supplied.
- Android instrumentation tests because no emulator or physical Android device was attached.
- iOS UI tests because the project has no test target.
- TalkBack, VoiceOver, 200% font scaling, physical-device, or six-person UAT.

These unperformed checks must not be described as passed.

## System and trust-boundary finding

There are currently two unrelated backend tracks:

1. A deployed PHP/MySQL consumer website on Railway.
2. A bundled Node/Express/Prisma/PostgreSQL mobile API that is not exposed at the Railway website URL.

The Android release URL targets `https://bkkcommunity.co.za/api/v1/`, which did not resolve during this audit. iOS and the admin dashboard target local development URLs. The Railway PHP deployment returns `404` for `/api/v1/health`.

The full bundle does not contain the deployed PHP website source. A group member therefore cannot reproduce the complete system from the ZIP.

## Critical release blockers

### C-01 — Shared archive contains live-class secrets and a known admin password

Severity: **Critical**  
OWASP themes: A02 Cryptographic Failures, A05 Security Misconfiguration

Confirmed evidence:

- The ZIP contains `bkk-api/.env` with non-empty `DATABASE_URL` and `JWT_SECRET` values.
- The ZIP contains `bkk-api/scratch.js`, an admin upsert script with a hardcoded email, known password, and `isAdmin: true` (`scratch.js:5-13`).
- The ZIP also contains 3,979 `.git` entries and machine-specific Android `local.properties`.

Impact:

- Anyone who received the ZIP may possess database credentials and the JWT signing key.
- If the bundled JWT key is used by any deployed API, an attacker can forge valid tokens.
- If the bootstrap script was run, the admin account has a password known to every bundle recipient.

Required action before any other release work:

1. Stop sharing the ZIP and remove it from public/shared locations.
2. Rotate the database password and JWT/reset-code secrets.
3. Reset the affected admin account password and review its activity.
4. Invalidate all issued JWTs by rotating the key; introduce server-side session revocation.
5. Delete bootstrap scripts and local configuration from distributable archives.
6. Run secret scanning on Git history and every group member's copy.

Do not merely delete `.env` and keep the old credentials. Once distributed, the values must be treated as compromised.

### C-02 — JWT authentication fails open when configuration is missing

Severity: **Critical**

Evidence: `bkk-api/src/middleware/auth.ts:10-13,22,37`

- The API falls back to the literal signing key `dev-secret`.
- Access tokens last 90 days.
- Tokens have no issuer/audience checks.
- `DELETE /auth/session` only acknowledges logout; it cannot revoke a token (`auth.ts:152-155`).

Impact: a misconfigured deployment has trivially forgeable admin/user tokens, and stolen tokens remain useful for months even after logout.

Required fix:

- Refuse to start in production unless a strong secret is configured.
- Use short-lived access tokens plus rotated refresh sessions stored server-side.
- Validate issuer, audience, algorithm, subject, and token type.
- Revoke all sessions after password reset, account deletion, or security-sensitive profile changes.

### C-03 — Android and iOS authenticate arbitrary users while offline

Severity: **Critical**  
OWASP theme: A07 Identification and Authentication Failures

Android evidence: `BkkRepository.kt:76-117`

- `IOException` during login or registration creates a local member with ID `-999` and token `demo-token`.

iOS evidence: `APIClient.swift:98-170`

- Network failures during login or registration return a member with ID `-999` instead of an error.

Impact:

- Any email/password appears valid whenever the backend is unavailable.
- The UI crosses the authenticated boundary even though no identity was verified.
- Profile and attendance behavior then diverges from server truth.

Required fix:

- Remove every fake-auth fallback from production builds.
- Allow offline access only to explicitly labelled public cached content.
- Auth, RSVP, profile, contact, password reset, and account deletion must fail honestly when the server cannot confirm them.
- If demo mode is needed for presentations, make it a separate non-release flavor with a permanent visible watermark.

### C-04 — No mobile/admin client targets a working deployed API

Severity: **Critical**

Evidence:

- Android release: `app/build.gradle.kts:25` targets `https://bkkcommunity.co.za/api/v1/`; DNS resolution failed on 13 August 2026.
- Android debug: `app/build.gradle.kts:32` targets emulator localhost.
- iOS: `Info.plist:21-28` targets `http://127.0.0.1:23456/api/v1` and permits arbitrary insecure loads.
- Admin: `index.html:437` targets `http://localhost:23456/api/v1`.
- Railway PHP: `/api/v1/health` returned `404`.

Impact: production devices cannot authenticate, reset passwords, RSVP, sync profiles, or receive server data.

Required fix: choose and deploy one canonical API, assign it an HTTPS domain, run a real database migration, then configure all release clients from environment/build configuration—not hardcoded local URLs.

### C-05 — Admin dashboard cannot execute

Severity: **Critical**

Evidence:

- Parsing the inline script with Node's JavaScript parser returned `SyntaxError: Unexpected token '}'`.
- `bkk-admin/index.html:566-575` contains a duplicated orphaned `catch/finally` block.
- Even after syntax repair, `index.html:437` points only to localhost.

Impact: admin login and every CRUD function are unusable.

Required fix: repair the script, add a build/lint/test step that parses JavaScript on every commit, configure the production HTTPS API, and deploy the admin app behind authenticated access.

### C-06 — A clean API deployment is not reproducible

Severity: **Critical**

Confirmed failures:

- The original project failed `npm ci` because `package.json` and `package-lock.json` were out of sync (`dotenv@16.6.1` missing from the lock).
- After regenerating the lock in a temporary audit copy, `npm ci`, Prisma generation, TypeScript compilation, and `npm audit --omit=dev` passed.
- Prisma `Member` uses `is_admin`, `failed_attempts`, and `locked_until` (`prisma/schema.prisma:19,23-24`).
- The sole migration does not create those columns (`prisma/migrations/0_init/migration.sql:2-15`).
- `package.json:9` deploys migrations in `npm start`, but `Dockerfile:22` bypasses that script and directly runs `node dist/index.js`.

Impact: fresh environments can fail at install time or start with a database schema that crashes authentication/admin queries.

Required fix:

- Commit the repaired lockfile.
- Generate a reviewed forward migration for every schema change.
- Make the deployment run `prisma migrate deploy` as a separate release step before starting the app.
- Prove a completely fresh database can migrate, seed approved demo data, start, and answer authenticated requests.

### C-07 — Android password reset cannot complete through the normal UI

Severity: **Critical functionality blocker**

Evidence: `BkkApp.kt:117-125,241-249`

- The Forgot Password screen sends the request but has no success navigation to the reset-code screen.
- The only alternative route is a custom `bkk://reset-password/...` deep link.
- That route accepts a 64-character hexadecimal token, while the API now issues six digits.

Impact: an Android user can request a code but has no valid route to enter it and set a new password.

Required fix: on a successful forgot-password response, navigate directly to an email + six-digit-code + new-password screen. Submit email and code together. Use a verified HTTPS app link only for optional email links.

### C-08 — Push delivery is simulated but reported as successful

Severity: **Critical claim/integrity blocker**

Evidence: `bkk-api/src/routes/devices.ts:16-23,26-42`

- Token registration only stores a token and logs an FCM stub.
- `/devices/test-push` logs a simulated payload and returns `dispatched: true` without Firebase Admin SDK delivery.

Impact: users and testers receive a false success state for a safety-relevant reminder feature.

Required fix: integrate Firebase Admin SDK, record provider message IDs and delivery failures without leaking token data, remove the public test-push endpoint, clean stale tokens, and verify on physical devices.

## High-severity findings

### H-01 — Six-digit reset code is not bound to the submitted email

Evidence: `auth.ts:231-260` and `validate.ts:49-54`

The reset endpoint accepts only `{ token, password }`. A correct code identifies and resets whichever account owns it. The global six-digit space is one million values; per-IP limiting helps but does not make a distributed guessing attack impossible.

Fix: require normalized email + code + password; HMAC the member ID/email together with the code; compare within that member's unused reset records; enforce per-account and per-IP attempt counters; invalidate all sessions on success.

### H-02 — Password-reset outage behavior can enumerate registered accounts

Unknown email returns the generic 200 response, but a known email returns 503 when SMTP is unavailable (`auth.ts:165-173,207-220`). During an outage, an attacker can distinguish existing accounts.

Fix: keep the public response uniform. Record delivery failure internally and surface operational alerts, not account-dependent response differences.

### H-03 — Async API failures are not centrally handled

The Express 4 async handlers await Prisma directly, while `index.ts:65-68` contains only a 404 handler and no final error middleware/async wrapper.

Impact: database and validation-edge failures can produce unhandled rejections, dropped responses, or process instability.

Fix: wrap async routes, add a final error handler, return stable problem responses, attach request IDs, and test database outage/error paths.

### H-04 — Admin mutation validation and privilege controls are weak

Evidence: `admin.ts:7-8,26-50,60-84,94-118,131-135`

- IDs may become `NaN`.
- Dates, ranges, maximum lengths, colors, phone numbers, and start/end ordering are not validated.
- `Boolean("false")` evaluates to `true`.
- An administrator can demote themselves or the last administrator.
- No re-authentication or audit log exists for privileged actions.

Fix: use strict Zod schemas, typed IDs, database constraints, last-admin protection, re-authentication for privilege changes/deletions, and immutable admin audit records.

### H-05 — Contact messages leak personal data to logs and are spam-prone

Evidence: `contact.ts:8-17`

The route stores the message and logs the full name, email, and body. It has only the global 100 requests/15 minutes/IP limiter; admin notification is a stub.

Fix: remove message content/addresses from logs, add a dedicated contact limiter and anti-abuse control, define retention/deletion, and securely notify authorized staff.

### H-06 — Android stores the bearer token in plaintext preferences

Evidence: `SessionStore.kt:19-23,50-61,77-85`

Backups are disabled, which is good, but the JWT is still persisted unencrypted in Preferences DataStore.

Fix: use Android Keystore-backed encrypted storage, shorter-lived access tokens, revocable refresh sessions, and clear all credentials on reset/deletion.

### H-07 — Android custom deep links can be claimed by other apps

Evidence: `AndroidManifest.xml:20-35`

The exported activity accepts an unverified `bkk://` scheme. Another app can register the same scheme and intercept/open sensitive navigation.

Fix: use verified HTTPS App Links with `android:autoVerify="true"`, keep reset secrets out of URLs where possible, and strictly validate every route parameter.

### H-08 — iOS allows cleartext traffic and uses unsafe in-memory auth state

Evidence: `Info.plist:21-28`, `APIClient.swift:11-25`

- App Transport Security is disabled globally.
- The API URL is HTTP localhost.
- `authToken` is mutable `nonisolated(unsafe)` shared state.
- The token is not stored in Keychain and the session disappears on restart.

Fix: release configuration must be HTTPS-only; use an actor-isolated client and Keychain-backed credential store with revocable sessions.

### H-09 — iOS attendance cancellation violates the API contract

Evidence:

- iOS sends `not_attending` (`APIClient.swift:173-184`).
- API accepts only `attending` or `cancelled` (`validate.ts:78-80`).

Impact: cancellation returns validation failure and the UI reverts.

Fix: share an explicit API contract and contract tests; send `cancelled` consistently.

### H-10 — iOS reminders silently reject API timestamps

Evidence: `NotificationManager.swift:24-26`

The API serializes dates with fractional seconds, e.g. `2026-08-14T09:00:00.000Z`. A direct Swift check confirmed the default `ISO8601DateFormatter` returns `nil` for this value; a formatter with `.withFractionalSeconds` parses it.

Impact: RSVP can succeed while the promised local reminder is never scheduled.

Fix: use the existing fractional-seconds fallback consistently and unit-test both date forms.

### H-11 — iOS does not meet the documented functional scope

Evidence: `MainTabView.swift:6-43`, `APIClient.swift`

- Guest browsing is blocked behind login.
- Navigation has six tabs rather than the documented five-tab design.
- No API operations exist for profile update, preferences, attendance history, account deletion, contact submission, FCM token registration, or remote notifications.
- Saved items and notification preferences are memory-only.
- No FCM or deep-link implementation exists.

Fix: establish one parity matrix and do not label the iOS app complete until every Must requirement has code and evidence.

### H-12 — Android cache refresh is not atomic

Evidence: `BkkRepository.kt:55-61`

The app clears three tables and then repopulates them independently. A mid-refresh failure can replace usable cached content with an empty or partially updated state.

Fix: use a Room transaction and update only after all remote payloads validate.

### H-13 — Android token initialization has a race

Evidence: `SessionStore.kt:38-44`

The stored token is collected asynchronously into a volatile snapshot. Requests made immediately at startup may omit a valid existing token.

Fix: make token access suspend/Flow-based or initialize it before constructing authenticated requests.

### H-14 — Source control and handoff are not reproducible

Confirmed evidence from the source repositories:

- API: modified package/schema/auth files and untracked admin/email/bootstrap files; the public origin has only four earlier commits.
- iOS: 13 modified and 10 untracked source entries; no test target.
- Admin: modified `index.html` not committed.
- The bundled Android directory has no repository metadata of its own.
- The deployed PHP website source is missing from the full bundle.

Fix: create one canonical private monorepo or clearly linked repositories, commit reviewed source only, tag releases, protect `main`, require CI, and generate clean release archives from Git—not from scratch folders.

### H-15 — The existing “stress test” is not a stress test and overclaims success

Evidence: `stress_test.py:30-48,63-118`

- It runs only three public requests in parallel.
- It creates accounts and contact messages, assumes event ID `1`, and leaves a lockout test account behind.
- It targets port 8000 while other clients target 23456.
- It prints `ALL ... PASSED PERFECTLY`, a claim unsupported by its coverage.

Fix: replace it with isolated integration tests using an ephemeral database, deterministic fixtures and cleanup, plus a separate k6/Locust load suite with thresholds.

## Medium-severity and engineering findings

1. Public and admin list endpoints are unpaginated, creating response-size and database-load risk.
2. The health endpoint (`index.ts:50-53`) does not test database, SMTP, migration, or Firebase readiness.
3. Device-token records have no created/updated timestamps, platform, last-seen time, or stale-token cleanup. An upsert can transfer a token between accounts (`devices.ts:16-20`).
4. Registration has no email verification, permitting typo accounts and address squatting.
5. Account deletion requires only a bearer token, with no recent-password re-authentication or recovery window (`me.ts:50-53`).
6. Admin stores its bearer token in `localStorage` (`index.html:438,482,588`), increasing token theft impact if an XSS flaw is introduced.
7. The single-file inline admin design makes a strong script CSP and maintainable testing harder.
8. Android lint completed with 34 warnings and deprecated Gradle flags; the build already warns of Gradle 10 incompatibility.
9. Android targets JVM bytecode 17 while forcing the Gradle daemon to JDK 25. This built here but adds a large, slow, unusual toolchain requirement for group members.
10. iOS uses many fixed 13–16 point font sizes and fixed card dimensions; 200% Dynamic Type behavior is unverified and likely to clip in dense layouts.
11. iOS requests notification permission inside scheduling rather than at a contextual, explained user action.
12. API architecture is PostgreSQL/Neon while the existing deployed site is PHP/MySQL, duplicating data, authentication, migrations, hosting and operational work.

## Positive controls confirmed

These are worth preserving:

- Android release disables cleartext traffic and backups (`AndroidManifest.xml:7-18`).
- Android updates RSVP cache only after the API confirms the change (`BkkRepository.kt:148-151`).
- Android uses five documented main tabs and includes 48–56 dp controls/Compose semantics in key components.
- API uses Helmet, a CORS allowlist, a 20 KB JSON limit, bcrypt cost 12, Zod on public mutation routes, rate limits, account lockout, and a unique attendance constraint.
- The revised reset implementation uses cryptographically secure six-digit generation, HMAC storage, expiry, prior-code invalidation, and invalidates a new code if mail sending fails.
- The email service avoids logging reset codes, addresses and provider message identifiers.
- The Railway PHP website returned CSP, HSTS, `X-Content-Type-Options`, clickjacking protection, a permissions policy, and a Secure/HttpOnly/SameSite session cookie.
- Live PHP login, registration and contact forms include CSRF tokens.

## Verification results

| Target | Command/check | Result | Interpretation |
|---|---|---:|---|
| API install | Original `npm ci --ignore-scripts` | **Failed** | Lockfile out of sync |
| API build | Temporary repaired lock + `npm ci` + `npm run build` | **Passed** | Source compiles after dependency metadata repair |
| API dependencies | `npm audit --omit=dev` after temporary lock repair | **0 known vulnerabilities** | Does not cover code/design flaws |
| Android | `./gradlew --no-daemon testDebugUnitTest lintDebug assembleDebug` | **Passed in 3m14s** | Debug APK builds |
| Android unit tests | Local JVM tests | **5 passed** | Only validation/presentation rules |
| Android lint | `lintDebug` | **34 warnings** | No lint errors, but debt remains |
| Android device tests | Instrumentation suite | **Not run** | No ADB device/emulator attached |
| iOS type check | `swiftc -typecheck` for iOS 16 arm64 | **Passed** | Swift sources type-check |
| iOS build | Generic iOS device, Debug, signing disabled | **Passed** | App bundle compiles |
| iOS tests | Xcode targets | **None exist** | No automated iOS behavior evidence |
| Admin | Parse inline JavaScript | **Failed** | SyntaxError prevents runtime |
| Android release API | DNS/health | **Failed** | Host did not resolve |
| Railway PHP API path | `/api/v1/health` | **404** | Deployed site is not the mobile API |

## Bounded live load probe

Target: `https://bkk-community-platform-production.up.railway.app`  
Method: 80 read-only GET requests, concurrency 8, spread evenly over `/`, `/events.php`, `/discounts.php`, and `/contact.php`  
Result:

- 80/80 returned HTTP 200.
- 0 request errors.
- Median: 416.9 ms.
- p95: 821.3 ms.
- Maximum: 1,046.9 ms.

This proves only that a small public read load was handled at one point in time. It does not prove database write safety, authentication stability, mobile API capacity, autoscaling behavior, sustained load, or denial-of-service resistance.

## Required staging stress plan

Run this only against an isolated staging environment with disposable data:

1. Functional API integration suite covering registration, login, lockout, reset, profile, RSVP uniqueness, attendance cancellation/history, contact, preferences, token registration and account deletion.
2. Contract tests shared by Android, iOS, admin and API for every request/response enum and date format.
3. Sustained load: 25 concurrent users for 10 minutes, then 50 for 5 minutes.
4. Spike: 0 to 100 read-only users over 30 seconds, recover to baseline without restart.
5. Soak: realistic mixed traffic for two hours while monitoring memory, event-loop lag, database connections and error rate.
6. Security abuse cases: distributed login/reset guessing, oversized bodies, malformed IDs/dates, privilege escalation, expired/revoked tokens, duplicate RSVP races, contact spam and database outage.
7. Failure injection: SMTP unavailable, Firebase unavailable, database latency/disconnect, expired TLS, client offline/online transitions.

Suggested initial thresholds:

- HTTP error rate below 1% for valid requests.
- Zero false-success responses for writes.
- p95 below 1 second for public reads and below 1.5 seconds for authenticated writes.
- No duplicate attendance records under concurrent RSVP.
- No process crash, unhandled rejection, database pool exhaustion, secret/PII logging, or memory growth after recovery.

## Bulletproof remediation order

### Phase 0 — Emergency containment

- Revoke/rotate every bundled secret and affected admin credential.
- Remove unsafe archives from GitHub, Drive, chat and shared links.
- Invalidate issued JWTs.
- Audit Git history and access logs.

Exit condition: no distributed credential remains valid.

### Phase 1 — One canonical, reproducible backend

- Decide whether the product uses PHP/MySQL or Node/PostgreSQL. Do not maintain two incomplete identity/data systems.
- Commit lockfiles and all migrations.
- Add startup configuration validation and fail closed.
- Add centralized error handling, structured redacted logs, readiness checks and CI.
- Deploy staging and production HTTPS endpoints.

Exit condition: a clean checkout can create a fresh database, build, deploy and pass the integration suite without manual file copying.

### Phase 2 — Restore authentication integrity

- Remove all production demo-auth and false-success fallbacks.
- Add revocable sessions, Keychain/Keystore storage and short-lived access tokens.
- Bind reset code to email/member, keep responses uniform, and revoke sessions on reset.
- Add email verification and recent-auth requirements for destructive changes.

Exit condition: wrong/offline credentials can never enter authenticated state on either platform.

### Phase 3 — Client/API parity

- Point release builds to the real HTTPS API.
- Repair Android reset navigation and verified app links.
- Fix iOS `cancelled` status and fractional timestamp parsing.
- Implement iOS guest browse, profile, attendance history, contact, preferences, account deletion, secure persistence and required five-tab navigation.
- Use atomic cache refreshes and explicit offline states.

Exit condition: the same API contract tests pass for Android, iOS and admin.

### Phase 4 — Real admin and notifications

- Repair, test and deploy the admin dashboard.
- Add strict admin validation, privilege safeguards and audit logs.
- Integrate Firebase Admin, token lifecycle management, reminder scheduling and provider failure handling.

Exit condition: an admin can create content once, both apps receive it, RSVP creates one record, and real physical devices receive/cancel the correct notifications.

### Phase 5 — Release evidence

- CI: clean builds, tests, lint, dependency/secret scans and migration test.
- Android API 26 plus current Android emulator and physical Google Play device.
- iOS supported device plus current simulator/device.
- TalkBack, VoiceOver, 200% font scaling, contrast and touch-target evidence.
- Six elderly BKK participants, 80% independent Must-task completion, average 4/5, no critical defects.

Exit condition: every Must requirement has captured, repeatable evidence. Placeholder screenshots or claims are not evidence.

## Final release gate

Do not distribute a production APK/IPA or call the system complete until all statements below are true:

- [ ] All exposed credentials have been rotated and old tokens invalidated.
- [ ] A clean checkout/build/deploy works without scratch files or local secrets.
- [ ] One canonical HTTPS API is reachable from Android, iOS and admin.
- [ ] Offline login/register/reset/contact/profile/RSVP never shows false success.
- [ ] Database migration equals the current schema on an empty database.
- [ ] Android and iOS password reset works end to end with real email.
- [ ] Admin parses, authenticates and performs validated audited CRUD.
- [ ] Real FCM delivery and cancellation are proven on physical devices.
- [ ] Automated API, Android and iOS tests cover success and failure paths.
- [ ] Staging load/security thresholds pass.
- [ ] Accessibility and elderly-user UAT evidence is complete.

Until then, label builds **development/demo only**.
