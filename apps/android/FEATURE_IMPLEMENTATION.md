# Android implementation status

Implemented:

- Documented five-tab Compose navigation and scrollable home/actions/schedule.
- Public events, discounts and services with search, filters, details and atomic Room refresh.
- Clear demo-data/freshness state; demonstration records reject RSVP.
- Online-only authentication, contact, profile, preferences, attendance history, deletion and RSVP.
- Forgot-password success navigates to email-bound six-digit code entry.
- Android Keystore AES-GCM bearer-token storage and server 401 session clearing.
- One RSVP state per event, local 24-hour WorkManager reminder after confirmed RSVP and cancellation cleanup.
- FCM token registration, notification inbox and event/discount deep links when Firebase is configured.
- Saved information, directions, sharing, telephone and calendar actions.
- API base URLs provided by Gradle properties; release placeholder is deliberately non-operational.

Not verified or not supplied:

- Production HTTPS API and authentic approved BKK content/assets.
- `google-services.json` and physical-device FCM delivery.
- Signed release APK.
- Current Android Studio unit/lint/APK execution for this clean tree.
- TalkBack, 200% font scale, current-device matrix and six-person elderly-user UAT.

These are release gates, not claims that can be satisfied by adding placeholder code.

