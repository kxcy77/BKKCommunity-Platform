# Staff access verification — 15 October 2026

## Implemented

Four permission levels retain compatibility with existing member/admin accounts. Staff permissions are refreshed from the database on protected website requests. Pages, direct POST actions and repository methods enforce their permissions. Existing administrators migrate to Owner; a new account defaults to member, with no effective staff permissions.

Owner-only staff management supports private invitation codes, permission changes and staff-access removal. Changes require the owner's current password and a reason, are rate limited and are audited. Codes use 32 cryptographically random bytes, are stored hashed, are bound to the recipient email, expire in 48 hours and are single-use. Invitation creation does not grant access or send an email; the owner shares the code privately.

The last owner cannot be removed. Staff changes and account deletion share a database lock. Access changes invalidate existing web and API sessions. Staff accounts must complete handover/removal before self-deletion.

## Local automated evidence

- PHP syntax, JavaScript syntax and Git whitespace checks passed.
- `tests/smoke.sh`: existing authenticated administrator CRUD/archive workflows and security checks passed; includes the new fail-closed permission matrix test.
- `tests/staff-permissions-integration.sh`: passed four-role/direct-URL matrix; guest/member denials; forged content/inbox/staff POST denials; positive editor creation and Support message resolution; read-only UI checks; owner-password confirmation; hashed/email-bound/single-use invitations; expired and cancelled invitations; web/API session revocation; last-owner removal protection; staff self-deletion protection; persisted audit records; public-registration role/level injection rejection.
- `tests/staff-owner-concurrency.php`: two separate PHP processes attempted owner removal concurrently. Exactly one request changed access and one was refused, leaving one active owner.
- Existing registered-user integration, persistent administrator integration, member integration and API integration suites passed against disposable MySQL databases.
- Migration tested against a legacy users table: existing admin became Owner and member remained a member with an inactive viewer level. Reapplying migration preserved a subsequently assigned Support level.

An initial readiness regression attempt failed because the manually created disposable database lacked the existing `schema_migrations` bookkeeping table. After initializing that test fixture correctly, the API regression suite passed. No production configuration was changed to bypass readiness checks.

## Visual inspection

Opened the Staff access page in the local browser using an existing synthetic verification administrator. Checked the rendered role descriptions, navigation, invitation form, current-staff controls and pending-invitation area. No real staff invitations or production permission changes were submitted through that test page.

## Release boundaries

Authenticated live staff workflows require an owner to sign in; local fixture tests do not prove a particular real staff member has accepted an invitation. No real staff account was invited or downgraded during automated testing. The release must separately confirm Railway deployment version, database migration and guest access protection. MFA and automatic invitation-email delivery are outside this update.

See [staff handover instructions](../../STAFF-ACCESS-HANDOVER.md).
