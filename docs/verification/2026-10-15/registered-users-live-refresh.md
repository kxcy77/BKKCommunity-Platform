# Registered users: automatic refresh correction

## Finding

The directory previously rendered only when opened or reloaded. An already-open page did not automatically show later registrations. This is separate from a signup that never reached the current production database.

## Correction

- Check the current directory every 10 seconds while visible, retaining its search, platform and pagination settings.
- Refresh on returning to the page or reconnecting; provide a manual Refresh now button.
- Combine overlapping checks, use a 15-second timeout, retain the displayed list on failure and show a truthful warning.
- Stop checking when the server redirects to login or rejects authentication.
- Do not renew administrator idle time for background checks. Explicit navigation/manual refresh still records activity.
- Avoid replacing the table while a user is editing filters or has keyboard focus within the results.

## Verification performed

- PHP and JavaScript syntax checks: passed.
- Existing web smoke suite: passed, including administrator content workflows and access controls.
- Registered-users database integration suite against disposable local database: passed website/Android/legacy signup tracking, duplicate rejection, optional phones, permissions, filters and pagination.
- New isolated regression test `services/web/tests/admin-poll-activity.php`: passed background-poll versus explicit-activity timeout behaviour. Included in the smoke suite.
- Local browser: left the administrator directory open with three fixture accounts. Registered `Automatic Refresh Verification` through the normal JSON registration endpoint (HTTP 201). Without reloading the page or clicking Refresh, the directory changed to four accounts and displayed the new Android registration with an updated check timestamp.

## Remaining investigation

The reported friend's email and signup platform have not been supplied. A read-only production database check during this investigation found no permanent registrations newer than 13 October. That does not establish where the friend signed up or whether registration completed. Do not claim their specific missing registration is resolved without matching it to a saved account and the endpoint/build used.
