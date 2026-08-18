# Release gates

The release owner must attach evidence and sign each gate. “Implemented in code” is not the same as “verified live”.

| Gate | Required evidence | Current state |
|---|---|---|
| Clean repository | Secret scan; no `.env`, signing keys, Firebase files, build output or nested Git data | Source scan passed for this cleaned tree; scan Git history after publishing |
| Fresh MySQL | Empty MySQL 8 database migrates; approved seed/import; restart; fresh reads | Tracked migrations pass locally and in Railway; destructive empty-database rehearsal outstanding |
| Authentication | Login gate, register, duplicate email, login, throttling, logout revocation, reset and reset-session revocation | Live register/login/revocation/profile/deletion passed; reset lockout/session logic passed locally; real email outstanding |
| Authorisation | Signed-out/member/admin route matrix; last-admin and self-demotion checks | Mobile signed-out gate verified; admin live integration outstanding |
| Android | Unit, lint, assemble, API 26/current emulator and physical device | Unit/lint/assemble and Android 36 live API journey passed; physical device and post-configuration API 26 evidence outstanding |
| iOS | Build/test on current Xcode simulator and physical iPhone | Simulator build/launch and live public-data cache passed; automated UI target and physical iPhone outstanding |
| Admin | Login, every CRUD action and fresh read-back | Canonical PHP admin database integration passed locally; authorised live CRUD outstanding |
| Email | Real six-digit code arrives from verified sender; expiry, wrong-code and resend behaviour | Outstanding |
| Push | Android and iOS device tokens, refresh, permission denial, deep links, stale-token cleanup | Outstanding |
| Offline truth | Public cache readable; auth/RSVP/contact/profile/reset never reports false success | Implemented; device evidence outstanding |
| Accessibility | TalkBack, VoiceOver, 200% text, contrast, focus order and control size | Outstanding |
| Security | Dependency audit, access-control tests, rate-limit tests, log/PII review and external review | Composer audit, access control, body limit, stateless headers and DB rate-limit tests passed; independent external review outstanding |
| UAT | Six elderly BKK participants; ≥80% independent completion; ≥4/5 average; no critical defects | Outstanding |
| Content/legal | Approved logo/data, POPIA/privacy notice, contact retention and client sign-off | Outstanding |

Release is blocked if any row is outstanding, any Must requirement fails, or any critical defect is open.
