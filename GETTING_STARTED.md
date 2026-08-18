# BKK Community: Group Quick Start

This is a source-code backup. Downloading or unzipping it does not start every part automatically. Follow the section for the part you need.

## Before you start

- Keep the folder name and structure unchanged after unzipping.
- Do not copy `.env`, database passwords, API keys, Firebase files, signing keys or APK files into Git.
- Do not run anything inside `reference/` unless you specifically need to study the old prototype. It is not the production system.

## Android app

1. Install Android Studio and the Android SDK.
2. Install a JDK compatible with the project (JDK 17 or newer).
3. In Android Studio choose **Open**, then select `apps/android` — not the repository root.
4. Allow Gradle to download its dependencies.
5. Select an emulator or Android phone and press **Run**.

The missing `local.properties` file is normal. Android Studio creates it for each person's own Android SDK location. `google-services.json` is optional in this project; without a real Firebase project the app still builds and uses its normal screens/API, but live FCM push notifications are unavailable.

## iOS app

1. Use a Mac with Xcode installed.
2. Open `apps/ios/BKKCommunity.xcodeproj` in Xcode.
3. Select an iPhone simulator or a connected iPhone, then press **Run**.
4. If Xcode asks to resolve packages or select a development team, allow it and select the group member's own Apple account.

The app can run in the simulator. Sharing a native build with other iPhone owners requires Apple TestFlight/Developer Program distribution; use the website for no-cost iPhone testing.

## Website and canonical API

1. Install PHP 8.3+, Composer and MySQL 8.
2. Open `services/web` in Visual Studio Code.
3. Run `composer install` once to restore the excluded PHP dependencies.
4. For a design/demo review, run:

   ```bash
   php -S 127.0.0.1:8080 -t public public/router.php
   ```

5. Open `http://127.0.0.1:8080`.

Without an `.env` database configuration, the website intentionally opens in labelled demo mode. That is not a crash. Persistent accounts, live admin data, RSVP writes and password-reset delivery require MySQL plus the environment variables described in `services/web/README.md`.

## The easiest testing route

| Person | Recommended way to test |
|---|---|
| Android user | Android Studio emulator/phone, or the shared debug APK |
| iPhone user without TestFlight | Open `https://www.bkkcommunity.online` in Safari and use **Add to Home Screen** |
| Person reviewing the website | Run `services/web` locally, or open the deployed website |

## If something does not start

Check these first:

1. Is the correct folder open (`apps/android`, `apps/ios/BKKCommunity.xcodeproj`, or `services/web`)?
2. Has the required tool downloaded its dependencies?
3. Is the device/emulator connected and selected?
4. Is the internet available for the hosted API?
5. Does `https://www.bkkcommunity.online/api/v1/health` respond before testing mobile live data?

If the app reports an API error, do not change passwords or URLs at random. Capture the exact message and check the backend health/readiness first.
