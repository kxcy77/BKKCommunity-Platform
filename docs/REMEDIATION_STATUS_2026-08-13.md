# Security remediation status

This maps the 13 August baseline audit to the cleaned source. “Fixed in source” still requires deployment/device evidence.

| Finding | Source remediation | Status |
|---|---|---|
| C-01 secrets/bootstrap in archive | Clean tree excludes `.env`, nested Git, machine files and bootstrap scripts; root ignore policy added | Fixed in source; previously exposed credentials must still be rotated |
| C-02 fail-open JWT | Required 32+ character secret, eight-hour issuer/audience/type/JTI tokens and server-side revocation | Fixed in source |
| C-03 offline fake auth | Removed Android/iOS fake members and demo tokens; private mutations fail honestly | Fixed in source |
| C-04 no canonical live API | `kxcy77/BKKCommunity-Web` is now the named PHP/MySQL release source; both apps use its verified Railway `/api/v1`; the bundled Node API is labelled experimental | Fixed and deployed |
| C-05 broken admin | Production uses the same-origin PHP administrator dashboard with CSRF/session protection; local database admin CRUD integration passes | Fixed in canonical source; live administrator CRUD evidence outstanding |
| C-06 unreproducible API | Composer lock, tracked numbered MySQL migrations, health/readiness checks and a Railway Docker build are now canonical | Fixed and deployed; fresh empty-MySQL rehearsal outstanding |
| C-07 Android reset unreachable | Forgot success navigates to email-bound six-digit reset screen; legacy reset deep link removed | Fixed in source |
| C-08 fake push | Canonical API stores real device tokens/preferences and never claims simulated delivery | Honest failure/data storage fixed; real provider delivery still unimplemented and outstanding |
| H-01 reset not bound to email | HMAC includes member ID, normalised email and code; attempt counter and expiry enforced | Fixed in source |
| H-02 reset enumeration on SMTP outage | Existing/unknown account and delivery failure return the same public response | Fixed in source |
| H-03 async failures | Canonical API uses stable error envelopes and top-level failure handling without logging request bodies | Fixed in source |
| H-04 admin validation/privilege | Same-origin PHP admin routes recheck the database role, validate fields and require CSRF | Fixed for current admin scope; step-up reauthentication remains a release hardening item |
| H-05 contact privacy/spam | PII logging removed and 5/hour dedicated limiter added | Fixed in source; retention/legal policy outstanding |
| H-06 Android plaintext token | Android Keystore AES-GCM token store added | Fixed in source |
| H-07 custom deep links | Sensitive reset secret removed from links; remaining explicit event/deal routes contain public IDs only | Risk reduced; verified HTTPS links require a real domain |
| H-08 iOS HTTP/unsafe state | ATS exception removed, HTTPS config enforced, `@MainActor` client and Keychain added | Fixed in source |
| H-09 iOS cancellation mismatch | iOS sends `cancelled` | Fixed in source |
| H-10 iOS fractional dates | Fractional-seconds parser with fallback used for reminders | Fixed in source |
| H-11 iOS scope gap | Authenticated five-tab UI, profile/preferences/history/contact/deletion and persisted saves added | Largely fixed; remote FCM/APNs integration remains |
| H-12 Android non-atomic refresh | Room transaction now replaces all public tables atomically | Fixed in source |
| H-13 Android token race | Keystore token is loaded synchronously before API client creation; profile without token is rejected | Fixed in source |
| H-14 handoff | One canonical clean tree, setup docs, release gates and ignores added | Fixed in source |

## Current verdict

The cleaned source is materially safer and the original critical code defects have been removed. The deployed PHP/MySQL source is now canonical and passes health/readiness, core HTTPS reads, authentication and RSVP. Release still requires SMTP/provider delivery, approved live content, a fresh empty-database rehearsal, authenticated live admin CRUD, physical-device accessibility testing and signed six-person elderly-user UAT.
