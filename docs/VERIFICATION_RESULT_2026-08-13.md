# Verification result — 13 August 2026

## Passed

- Clean `npm ci --offline --ignore-scripts`: 134 packages installed from the committed lockfile.
- Production dependency audit: 0 reported vulnerabilities.
- Prisma client generation and TypeScript compilation.
- Five API contract/security tests: 5 passed, 0 failed.
- Admin inline JavaScript parse.
- Android `testDebugUnitTest`, `lintDebug` and `assembleDebug` with Gradle 9.6.1 and JDK 21.
- Android 36 emulator launch and rendered login journey.
- Railway PHP/MySQL HTTPS contract: events, discounts, services, registration, session revocation, login, authenticated profile and account deletion.
- Railway `/health` and database-backed `/ready`: 200; tracked migrations applied before readiness.
- Canonical Railway container now runs PHP-FPM behind Nginx; its `/ready` deployment healthcheck passed, unknown routes return 404 and oversized requests return 413.
- Live labelled demonstration event: details, duplicate RSVP prevention, attendance history, cancellation and disposable-account deletion passed.
- Legacy 64-character reset payload rejected; unconfigured SMTP fails closed with HTTP 503 `email_unavailable`.
- Android 36 disposable-account login through the real app, followed by live Checkers/Clicks discounts and all three live local-service records.
- Login page exposes a scrollable accessibility node and keeps Sign In, Create Account and security guidance reachable at 200% font scaling.
- All iOS Swift source type-check against the installed iPhoneOS SDK.
- Full iOS simulator build and launch; the configured Railway URL populated event, discount and service cache keys without falling back to fabricated content.
- Xcode project and Info.plist structural validation.
- Source credential-pattern scan after excluding explicit examples/historical audit evidence.
- False-auth/stale reset contract scan (`-999`, `demo-token`, `not_attending`, global ATS bypass and port 23456 absent from product source).
- Clean-tree scan: no `.env`, Firebase config, signing key, `local.properties`, nested `.git`, dependency folder or generated build output.

## Blocked—not passed

- Android post-configuration API 26 and physical-device journeys: the live integration was exercised on Android 36; API 26, TalkBack and real-device evidence remain outstanding.
- iOS automated UI testing and physical-device testing: simulator build/launch passed, but this project still has no iOS test target.
- Fresh empty-MySQL rehearsal: tracked migrations pass locally against the existing test schema and in Railway, but a destructive clean-room database build has not been performed.
- Live administrator CRUD: local database integration passes, but no authorised production administrator session was used for mutation evidence.
- Live password-reset delivery: source and contract are deployed, but `/auth/forgot-password` correctly returns HTTP 503 `email_unavailable` because Railway SMTP credentials and a verified sender are not configured.
- Live SMTP and FCM: no authorised external credentials or physical devices were supplied.
- Accessibility and elderly-user UAT: human/device evidence is outstanding.

## Important interpretation

The tested canonical Railway contract and both simulator clients now work at the levels listed above. They do not prove live reset-email delivery, Firebase notifications, physical-device accessibility, approved BKK content or real-user UAT. Use `RELEASE_GATES.md` before any release claim.
