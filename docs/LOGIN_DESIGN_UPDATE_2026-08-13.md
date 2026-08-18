# Login design update — 13 August 2026

## What changed

- Replaced the plain Android auth card and stock iOS form with a shared BKK visual direction.
- Added a navy branded welcome area, community identity, clearer heading hierarchy and a focused white form surface.
- Added leading field icons, show/hide password controls, visible validation and large 56–64dp actions.
- Made password recovery and account creation visually distinct without competing with the primary sign-in action.
- Added concise secure-sign-in reassurance and retained scalable typography and screen scrolling.
- Kept all authentication, six-digit password-reset and secure token-storage behavior unchanged.

## Functional correction

The previous iOS sheet dismissed immediately after submission, including when authentication failed. It now disables repeat submission, displays the server error within the sheet and dismisses only after the API returns a successful login or registration.

## Verification

- Android: unit tests, lint and debug APK assembly passed.
- Android 36 emulator: login launched and visually inspected.
- Android login accessibility tree reports a scrollable container.
- Android at 200% font scaling: Sign In, Create Account and security guidance remain reachable by scrolling.
- iOS: every Swift source file passed compiler type-check against the installed iPhoneOS SDK.

Manual TalkBack, VoiceOver, API 26 and physical-device evidence are still required before release.
