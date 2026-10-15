# Staff access and handover

Staff administration is on the website. The Android app remains a member-facing application; an Android rebuild is not required for these website controls.

## Access levels

| Level | Allowed | Not allowed |
| --- | --- | --- |
| Owner | All administration, registered users, staff invitations, access changes, audit history | Removing the final owner |
| Content editor | Dashboard; create, edit, archive and restore events, discounts and local services; public-content overview | Staff permissions, member directory, private messages, attendance roster, audit history |
| Support | Dashboard, contact inbox/status changes, searchable read-only attendance enquiries | Content changes, member directory, staff access, audit history |
| Read-only | Dashboard and read-only public-content overview | All editing, staff access and private member information |

Existing administrators keep their full access under the Owner label. The underlying `member`/`admin` account role is retained for Android and existing integrations. The new `staff_level` is meaningful only for administrator accounts. Public registration always creates a member, regardless of submitted staff fields.

## Invite a staff member

1. Sign in as an Owner. Open **Admin → Staff access**.
2. Enter the staff member's exact email, choose the lowest access level they need, give a reason and enter your current password.
3. Select **Create invitation** and confirm. Copy the one-time invitation code shown on the next page. It is displayed once, expires in 48 hours and is not stored as plain text in the database.
4. Share the code privately with that person, together with the website's `/staff-invitation.php` address. No invitation email is sent automatically by this implementation.
5. The recipient registers or signs in with the invited email and their own password, opens **My profile → Accept staff invitation**, pastes the code and accepts. Acceptance grants access; creating an invitation alone does not.
6. They sign in again to load their new permissions. A code for another email, an expired/cancelled code or a previously used code is rejected.

Creating a replacement invitation for an email cancels its earlier pending codes. The issuing owner must still have Owner access when the invitation is accepted. Pending invitations can be cancelled from Staff access.

## Change or remove staff access

Select the new level next to the person's account, give a reason and confirm with your own current password. **Remove staff access** leaves the account as a normal member; it does not delete their account or attendance history.

Access changes increment the account security version and revoke its API sessions. Old website sessions fail on their next protected request; Android sessions must sign in again. Role changes and invitation actions are recorded in the owner-only audit history. Concurrent or stale edits cannot silently overwrite a newer change.

## Hand over ownership

Invite the client representative as an Owner. Wait until they accept and verify that they can sign in and open Staff access. Only then downgrade/remove the outgoing owner's staff access. Keep at least one active Owner, preferably two authorised client representatives with separate accounts. Never share a password.

The last owner cannot be downgraded or removed. Staff must have their staff access removed before deleting their member account, including through Android. Owner changes and invitation acceptance use a database lock to prevent concurrent requests from removing the final owner.

## Maintenance and recovery

Apply migration `012_staff_permissions.sql` before serving this code. The normal Railway startup migration runner handles it; it is additive and repeatable. Never roll back by dropping the new columns or tables while this version is running. Keep the previous source release available; retaining the additive schema allows a source rollback.

For emergency recovery, the existing protected `services/web/bin/create-admin.php` CLI grants Owner access and invalidates old sessions. It requires trusted server access and must not be exposed as a public endpoint. It is a maintenance escape hatch, not a staff workflow.

Permissions are checked in pages, POST handlers and repository operations. Hidden navigation is only a usability aid, not the security boundary. Production must remain on HTTPS. MFA and automated invitation-email delivery are not implemented by this update.
