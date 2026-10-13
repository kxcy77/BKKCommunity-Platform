# Release gates

The release owner must attach evidence and sign each gate. “Implemented in code” is not the same as “verified live”. The presentation may use clearly marked demonstration records, but that is not a production content sign-off.

| Gate | Required evidence | Current state |
|---|---|---|
| Clean repository | Secret scan; no `.env`, signing keys, Firebase files, build output or nested Git data | Source scan passed for this cleaned tree; scan Git history after publishing |
| Fresh MySQL | Empty MySQL database migrates; approved seed/import; restart; fresh reads | Earlier fresh disposable database initialization passed through migration 009; migration 010 and its session-bound push assertions passed in a disposable database on 12 October. Current production backup/restore rehearsal outstanding |
| Authentication | Login gate, register, duplicate email, login, throttling, logout revocation, reset and reset-session revocation | Live register/login/revocation/profile/deletion passed; reset lockout/session logic passed locally; real email outstanding |
| Authorisation | Signed-out/member/admin route matrix; last-admin and self-demotion checks | Mobile signed-out gate verified; admin live integration outstanding |
| Android | Unit, lint, assemble, API 26/current emulator and physical device | Unit/lint/build and 11 instrumentation tests on both API 26 and API 36 passed on 1 October; physical-device verification outstanding |
| Admin | Login, every CRUD action and fresh read-back | Canonical PHP admin database integration passed locally; authorised live CRUD outstanding |
| Email | Real six-digit code arrives from verified sender; expiry, wrong-code and resend behaviour | Outstanding |
| Push | Android device tokens, refresh, permission denial, deep links, sign-out isolation, stale-token cleanup | The user-provided `google-services.json` contains Firebase project `com-example-myapplicatio-45f5e` and both Android packages. On 13 October, API 26 emulator DNS was repaired and an FCM token was cached for the configured sender; the token value was not exposed. The in-app Firebase Console session for `kingkg256@gmail.com` could not list this project; the user reports access from Chrome, but a matching server credential has not yet been supplied or verified. Railway FCM remains off; delivery and physical-device evidence are outstanding. Local queue tests block demo discounts and cancelled events. |
| Offline truth | Public cache readable; auth/RSVP/contact/profile/reset never reports false success | Room cache and offline RSVP regression tests passed on both emulators; full physical-device offline workflow evidence outstanding |
| Accessibility | TalkBack, 200% text, contrast, focus order and control size | Outstanding |
| Security | Dependency audit, access-control tests, rate-limit tests, log/PII review and external review | Composer audit, access control, body limit, stateless headers and DB rate-limit tests passed; independent external review outstanding |
| UAT | Six elderly BKK participants; ≥80% independent completion; ≥4/5 average; no critical defects | Outstanding |
| Content/legal | BKK-approved events, merchant-authorised discount terms, verified service and public contact details, approved logo, POPIA/privacy notice, retention and client sign-off | Outstanding. Sample offers and services remain visible only as labelled demonstrations for the presentation; they are not claimable/callable and must not generate phone alerts. BKK staff must supply approved records using `docs/BKK_CONTENT_INTAKE.md` before live release |

Release is blocked if any row is outstanding, any Must requirement fails, or any critical defect is open.
