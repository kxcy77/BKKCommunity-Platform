# BKK Community Platform — Administrator Audit

**Audit date:** 20 August 2026
**Scope:** PHP administrator pages, authentication/authorization, content-management actions, MySQL repository functions, responsive administration CSS, existing automated tests, and safe unauthenticated checks against `https://www.bkkcommunity.online`.
**Method:** Source review, PHP syntax validation, local smoke tests, isolated-MySQL integration and restore tests, Railway deployment verification, and non-destructive production HTTP checks.
**Production writes performed:** Application revision and database migration deployment only. No event, discount, service, contact-message or user content was created, edited or deleted for this audit.

## Executive decision

**Status: REMEDIATION DEPLOYED AND TECHNICALLY VERIFIED; AUTHENTICATED MANUAL ACCESSIBILITY/UAT AND RETENTION SCHEDULING STILL REQUIRED.**

The original audit identified one Critical, four High and five Medium findings. The remediated revision is now deployed from the combined public GitHub repository. Production fails closed without MySQL, demonstration accounts require explicit local-only environment configuration, administrator roles and session versions are revalidated, content supports edit/archive/restore, changes are audited, and contact messages are paginated and searchable.

Railway reports the combined-repository deployment as successful. Live `/health` and `/ready` checks returned `200`, the protected audit route is present, signed-out administrator routes redirect to login, and the production database records `007_admin_security_and_audit.sql` as applied. A compressed production backup was integrity-checked and successfully restored into a temporary isolated MySQL database before that temporary database was removed. These technical checks do **not** replace authenticated administrator UAT, keyboard/screen-reader evidence, 200% zoom checks or testing by elderly participants.

## Remediation verification added on 20 August 2026

| Area | Source result | Verification |
|---|---|---|
| Production fail-closed | Implemented | Automated HTTP test returned `503` with `APP_ENV=production`, no database and demo disabled. |
| Demo administrator secret removal | Implemented | Credentials are environment-only; login HTML and production failure response are tested for known legacy strings. |
| Administrator authorization | Implemented | Local test proved a signed-in member is redirected away from Admin. Database integration test now covers immediate role-revocation invalidation. |
| Session expiry | Implemented | 30-minute idle and eight-hour absolute defaults are configurable; database `auth_version` invalidates sessions after security changes. |
| Content lifecycle | Implemented | Event, discount and service edit plus audited archive/restore are present. Row-version checks reject stale concurrent edits. Session-only and persistent-MySQL journeys pass. |
| Validation and failure feedback | Implemented | Server maximums, allowlists, dates, phone format and correlation-ID error handling were added. Success is conditional on locating the record. |
| Contact-message privacy | Implemented in source | Bounded search, status filters, 25-row pagination, privacy warning, status audit and configurable resolved-message retention job were added. |
| Mobile administrator navigation | Improved; manual evidence pending | Navigation becomes a two-column grid on small screens and tables include visible swipe guidance. Screen-reader and physical-device testing remain human tasks. |

## Verified strengths

| Control | Result | Evidence |
|---|---|---|
| Signed-out admin protection | PASS | `/admin/`, `index.php`, `events.php`, `discounts.php`, `services.php` and `messages.php` returned `302` to `/login.php` on 20 August 2026. |
| CSRF protection | PASS | All POST actions call `verify_csrf()`; an invalid production CSRF submission returned `419`. |
| HTTP method restriction | PASS | `GET /actions.php` returned `405` with `Allow: POST`. |
| Security headers | PASS | Production returned HSTS, CSP, `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY`. |
| Session cookie flags | PASS | Production cookie was `Secure`, `HttpOnly` and `SameSite=Lax`. |
| Output escaping | PASS in reviewed views | Admin names, content and contact-message fields use the shared HTML escaping helper. Message bodies are escaped before `nl2br`. |
| SQL injection resistance | PASS in reviewed paths | Administrator repository writes use PDO prepared statements with emulated prepares disabled. |
| Login session fixation | PASS | Successful login regenerates the PHP session ID. |
| Local smoke suite | PASS | Public routes, production fail-closed behaviour, guest/member authorization, CSRF, environment-configured admin login, every admin page, event create/edit/archive/restore, discount create/edit/archive, service create/edit/archive, audit visibility and legacy-delete blocking passed. |
| Isolated MySQL administrator integration | PASS | A temporary database verified schema/migration execution, persistent login, paginated inbox status, content lifecycle writes, audit persistence and immediate role-revocation invalidation. The database and test user were removed afterward. |
| PHP syntax | PASS | Admin and supporting PHP files passed PHP 8.5 syntax checks. |

## Findings

### ADM-001 — Production can fail open to a known demo administrator

**Severity:** Critical
**Confidence:** High
**Status:** Fixed, deployed and unauthenticated production smoke verified

When `DB_HOST` is empty, `database()` returns `null`. The application then treats the request as demo mode. `attempt_login()` contains hard-coded member and administrator credentials in the public source code, including `admin@bkk.demo` and its password. `APP_ENV` is loaded but is not used to prohibit demo mode in production.

The live login page did not expose demo markers during the audit, which indicates that the current database configuration is active. The weakness remains dangerous because a missing production variable or incorrect deployment can silently turn the known demo administrator back on.

**Evidence:**

- `services/web/app/repository.php:17–21`
- `services/web/app/auth.php:53–72`
- `services/web/app/config.php:34–40`
- `services/web/app/bootstrap.php:133–136`

**Required remediation:**

1. In production, abort startup or return `503` when database configuration is missing.
2. Permit demo mode only when both `APP_ENV=development` and an explicit `ALLOW_DEMO_MODE=true` flag are present.
3. Remove the built-in administrator password from committed source.
4. Create demo accounts through a development-only seed command.
5. Add a test proving that `APP_ENV=production` plus an empty `DB_HOST` cannot authenticate any demo account.

### ADM-002 — The documented CRUD requirement is incomplete

**Severity:** High
**Confidence:** High
**Status:** Fixed, deployed and isolated MySQL verified; authenticated production lifecycle UAT pending

Events, discounts and local services support Create, Read and Delete only. There are no edit forms, update handlers or update repository functions. An administrator who notices a spelling mistake, changed event time, expired discount or changed service telephone number must delete and recreate the entire record.

This does not satisfy full CRUD and creates avoidable mistakes in a platform designed for elderly users who may rely on accurate times, locations and contact information.

**Evidence:**

- `services/web/public/admin/events.php`
- `services/web/public/admin/discounts.php`
- `services/web/public/admin/services.php`
- `services/web/public/actions.php:257–367`
- No `admin_edit_*` or `admin_update_*` content handler exists.

**Required remediation:**

1. Add Edit actions and pre-populated edit forms.
2. Add server-side update handlers and repository functions.
3. Add optimistic or updated-at conflict protection.
4. Test create, read, update, archive and restore for every content type.

### ADM-003 — Web administrator sessions are not revalidated or explicitly expired

**Severity:** High
**Confidence:** High
**Status:** Fixed and deployed; role revocation verified in isolated MySQL, manual production timing evidence pending

The web application stores the complete user role in `$_SESSION['user']`. `current_user()` returns this cached session record and `is_admin()` trusts the cached `role`. There is no administrator idle timeout, absolute session lifetime, or database revalidation. If an administrator is demoted or deleted in MySQL, an existing PHP session may retain administrator access until it is manually logged out or expires according to server defaults.

**Evidence:**

- `services/web/app/auth.php:5–13`
- `services/web/app/auth.php:24–29`
- No web `last_activity`, administrator expiry or role-refresh implementation was found.

**Required remediation:**

1. Store only the user ID and minimum session metadata.
2. Revalidate active/deleted status and role for every administrator request, or use a short secure cache.
3. Apply a 15–30 minute administrator idle timeout and an absolute session lifetime.
4. Revoke all sessions when a role or password changes.
5. Test demotion, deletion, password change and session expiry.

### ADM-004 — Destructive content actions are irreversible and unaudited

**Severity:** High
**Confidence:** High
**Status:** Fixed, deployed and isolated MySQL verified; authenticated audit-history UAT pending

Delete actions execute permanent SQL `DELETE` statements. Confirmation is a browser `window.confirm` prompt only. There is no archive/restore process, no reason field and no administrator activity log identifying who changed or deleted content. Event deletion can cascade into attendance records, damaging attendance history and evidence.

**Evidence:**

- `services/web/app/repository.php:287–295`
- `services/web/app/repository.php:320–328`
- `services/web/app/repository.php:396–405`
- `services/web/public/assets/js/app.js:45–50`
- No administrator audit table or change-log implementation was found.

**Required remediation:**

1. Replace normal deletion with archive/inactive status.
2. Add restore controls and a separate privileged permanent-delete operation.
3. Record administrator ID, action, entity, entity ID, before/after values, timestamp and reason.
4. Require a stronger confirmation for destructive actions.
5. Preserve attendance and notification history.

### ADM-005 — Server validation does not enforce database maximums or complete allowlists

**Severity:** High
**Confidence:** High
**Status:** Fixed in source; boundary-test expansion pending

Creation handlers enforce useful minimum lengths but omit many maximum lengths. Oversized event titles, locations, category names, business names, addresses or opening hours may reach MySQL and produce an unhandled database exception instead of a clear validation message. Event and discount categories are taken from POST data without a strict server-side allowlist, even though the browser uses fixed select options.

**Evidence:**

- `services/web/public/actions.php:257–310`
- `services/web/public/actions.php:337–354`
- `services/web/database/schema.sql`

**Required remediation:**

1. Match every input limit to its database column.
2. Validate category and colour values with server-side allowlists.
3. Validate telephone format while allowing legitimate South African formats.
4. Catch database exceptions, log a correlation ID and show a safe user message.
5. Add boundary tests for empty, maximum, over-maximum and malformed inputs.

### ADM-006 — Discounts and services cannot be scheduled, deactivated or expired from Admin

**Severity:** Medium
**Confidence:** High
**Status:** Fixed and deployed; authenticated failure-path UAT pending

The database supports discount validity dates and active flags, and local services have an active flag. The admin forms do not expose validity dates, active/inactive status or archive controls. This encourages permanent deletion and makes stale discounts or temporarily unavailable services harder to manage safely.

**Required remediation:** Add valid-from, valid-until, active/inactive, archive and preview controls with clear status labels.

### ADM-007 — Contact-message privacy and scale controls are incomplete

**Severity:** Medium
**Confidence:** High
**Status:** Fixed in source; scheduled-job configuration pending

The message screen loads every contact message and displays personal information including names, email addresses, phone numbers and message text. There is no pagination, search, retention rule, export control, assignment or administrator audit trail. The current output escaping prevents direct stored-XSS in the reviewed view, but privacy and operational controls remain incomplete.

**Evidence:** `services/web/app/repository.php:331–364` and `services/web/public/admin/messages.php`.

**Required remediation:** Add pagination, minimum-data views, retention/deletion rules, access logging, optional assignment and search. Document who is allowed to read contact messages.

### ADM-008 — Successful deletion is reported even when no record was deleted

**Severity:** Medium
**Confidence:** High
**Status:** Fixed by replacing delete with existence-checked archive/restore

The event, discount and service delete functions do not check `rowCount()`. A valid positive but nonexistent ID still produces a success message. This gives administrators false confidence and weakens testability.

**Required remediation:** Return a boolean from repository delete functions and show success only when exactly one intended row was affected.

### ADM-009 — Administrator navigation and mobile tables need usability testing

**Severity:** Medium
**Confidence:** Medium
**Status:** Source layout improved; visual/UAT verification still required

The responsive layout collapses the sidebar into a horizontally scrolling navigation row and keeps data tables at a minimum width of 720px. This prevents layout breakage but may hide actions without an obvious scrolling cue. The sidebar navigation container itself has `tabindex="0"`, adding an extra keyboard stop without an announced purpose. The top navigation does not mark Admin as current because admin pages do not set `$activeNav = 'admin'`.

**Evidence:**

- `services/web/public/assets/css/app.css:304–321` and `374–381`
- `services/web/public/admin/_sidebar.php:1–9`
- Admin page setup does not assign `activeNav`.

**Required remediation:** Test at 375px, 768px and 1440px; provide visible scroll cues or responsive cards; remove unnecessary container tabindex; set the current navigation state; verify keyboard focus and 200% zoom.

### ADM-010 — Existing automated admin coverage is incomplete

**Severity:** Medium
**Confidence:** High
**Status:** Local coverage expanded; isolated MySQL execution still required

The local smoke suite verifies guest protection, CSRF, demo-admin login and admin-page reachability. The MySQL integration script verifies administrator login, create/delete operations and message status. It does not verify edit/update because those features do not exist, and it does not cover member-to-admin authorization, administrator demotion, session expiry, audit logs, archive/restore, oversized inputs or production fail-closed behaviour.

**Required remediation:** Add the missing security, validation and lifecycle cases before production sign-off.

## Live verification record

The following non-destructive checks were performed against the production domain on 20 August 2026:

| Request | Observed result |
|---|---|
| `GET /admin/` | `302 Location: /login.php` |
| `GET /admin/index.php` | `302 Location: /login.php` |
| `GET /admin/events.php` | `302 Location: /login.php` |
| `GET /admin/discounts.php` | `302 Location: /login.php` |
| `GET /admin/services.php` | `302 Location: /login.php` |
| `GET /admin/messages.php` | `302 Location: /login.php` |
| `GET /actions.php` | `405`, `Allow: POST` |
| Invalid-CSRF POST to an admin action | `419`; no action executed |
| Login page demo markers | No demo email, demo password or demonstration-mode marker present |

Every sampled admin response included current HSTS, CSP, nosniff and frame-denial headers and a secure session cookie.

## Remediation order

### Before any production administrator is added

1. Fix ADM-001 so production fails closed and remove committed demo-admin credentials.
2. Fix ADM-003 with administrator role revalidation and explicit session expiry.
3. Fix ADM-004 with archive/restore and an administrator audit trail.
4. Implement full edit/update functionality in ADM-002.
5. Fix input limits and safe error handling in ADM-005.

### Before client acceptance

6. Add scheduling/deactivation controls for discounts and services.
7. Add contact-message pagination and privacy controls.
8. Correct false delete-success feedback.
9. Perform responsive, keyboard, 200% zoom and elderly-user admin testing.
10. Execute the persistent MySQL administrator test against an isolated staging database and attach screenshots/results.

## Audit limitations

- No production administrator credentials were used.
- No production record was created, edited, deleted or viewed.
- Authenticated production admin screens and real database CRUD were not visually inspected.
- The updated MySQL integration script was executed against an isolated temporary local database and passed. It was not executed against production, and no production records were read or changed.
- This is an application review, not a full infrastructure penetration test.
