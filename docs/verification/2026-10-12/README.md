# Calendar fix and delivery configuration checks — 12 October 2026

## Implemented calendar change

The website no longer hard-codes August 2026. It defaults to the current month in Africa/Johannesburg and provides Previous month, Current month and Next month links. Weekday alignment and month length come from the selected month, including February in leap years. Event markers match the entire date (year, month and day), and honour the category filter. Event days link to their detailed cards. The detailed list still includes all upcoming events in the selected category, as the page explains.

No database migration, new event or change to attendance safety is required. Demonstration events still cannot accept attendance.

## Executed checks

- PHP 8.5.9 local syntax checks: calendar helper and events page passed.
- 24 calendar regression checks passed: Johannesburg month boundary, weekday alignment, month lengths, leap years, year navigation, input rejection, exact-date matching, multiple events and query encoding.
- Existing local web smoke suite passed, including admin create/edit/archive/restore and member-role protection. These browser-session fixtures are not production MySQL tests.
- Existing Resend configuration/payload test passed with fixture configuration. This does not prove delivery.

Hosted CI and deployed verification are separate from these local checks. The PHP 8.3 CI run is the compatibility check for the production runtime.

## Password reset: current production blocker

A controlled request using a non-deliverable fixture address returned HTTP 503 and `email_unavailable`: “Password reset email is not configured.” The production Railway variable-name inventory has MAIL_FROM and RESET_CODE_SECRET, but no RESEND_API_KEY or SMTP_HOST/SMTP_USER/SMTP_PASSWORD. No real member reset was issued. Restore a valid email transport in secure Railway variables and confirm delivery to a controlled account before claiming reset works.

## Android cloud notifications: what remains

The assessed PHP API registers device tokens and preferences but has no FCM delivery worker. The inspected local Android checkout has no google-services.json. The Android build suffix also means debug requires Firebase registration for za.co.bkkcommunity.app.debug, not only za.co.bkkcommunity.app.

The Android receiver and local reminder worker additionally check POST_NOTIFICATIONS without an API-33 version guard. This should be corrected and tested on API 26 as part of a notification implementation. No Android code was changed by this calendar fix. Local WorkManager reminders are different from server-originated discount alerts and synced reminders.

To complete cloud delivery, supply Firebase configuration securely, implement an authenticated HTTP v1 server sender and scheduled reminder processing, respect user/device preferences, handle invalid tokens and retries, and test receipt/tap behaviour on a Google-Play-services Android device. Never put service-account keys in the APK or public repository.
