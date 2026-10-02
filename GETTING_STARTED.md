# BKK Community: Group Quick Start

This is a source-code backup. Downloading or unzipping it does not start every part automatically. Follow the section for the part you need.

## Before you start

- Keep the folder name and structure unchanged after unzipping.
- Do not copy `.env`, database passwords, API keys, Firebase files, signing keys or APK files into Git.
- Do not run anything inside `reference/` unless you specifically need to study the old prototype. It is not the production system.

## Android app

1. Install Android Studio and the Android SDK.
2. Use a compatible Gradle runtime (tested from JDK 21, with the project's Java 25 daemon criteria). Android bytecode targets JVM 17; that is separate from the Gradle runtime.
3. In Android Studio choose **Open**, then select `apps/android` — not the repository root.
4. Allow Gradle to download its dependencies.
5. Select an emulator or Android phone and press **Run**.

The missing `local.properties` file is normal. Android Studio creates it for each person's own Android SDK location. `google-services.json` is optional in this project; without a real Firebase project the app still builds and uses its normal screens/API, but live FCM push notifications are unavailable.

## Website and canonical API

1. Install PHP 8.3+, Composer and MySQL 8.
2. Open `services/web` in Visual Studio Code.
3. Run `composer install` once to restore the excluded PHP dependencies.
4. Configure your own local MySQL database and excluded `.env` file using `services/web/README.md`, then run:

   ```bash
   php -S 127.0.0.1:8080 -t public public/router.php
   ```

5. Open `http://127.0.0.1:8080`.

Persistent accounts, shared admin data, RSVP writes and password-reset delivery require MySQL plus the environment variables described in `services/web/README.md`. Without database configuration the server returns 503. For a temporary design preview only, use the VS Code task, which explicitly enables local demo mode; changes made in demo mode are not shared with other users or the Android app.

## The easiest testing route

| Person | Recommended way to test |
|---|---|
| Android user | Android Studio emulator/phone, or the shared debug APK |
| Person reviewing the website | Run `services/web` locally, or open the deployed website |

## If something does not start

Check these first:

1. Is the correct folder open (`apps/android` or `services/web`)?
2. Has the required tool downloaded its dependencies?
3. Is the device/emulator connected and selected?
4. Is the internet available for the hosted API?
5. Does `https://bkkcommunity-platform-2-production.up.railway.app/api/v1/health` respond before testing mobile live data?

If the app reports an API error, do not change passwords or URLs at random. Capture the exact message and check the backend health/readiness first.
