# Setup and deployment

## Android Studio

1. Open the `android` folder—the one containing `settings.gradle.kts`.
2. Choose Android Studio's embedded JDK. The Gradle daemon criteria permit Java 25; Android source and Kotlin bytecode intentionally target JVM 17 because that is the supported Android toolchain target, not an outdated Gradle runtime.
3. Let Gradle sync.
4. Android defaults to the verified Railway HTTPS API. For a local API, add this override to user/project Gradle properties outside Git:

   ```properties
   BKK_DEBUG_API_BASE_URL=http://10.0.2.2:8000/api/v1/
   ```

5. To target a different release environment, set its verified HTTPS value:

   ```properties
   BKK_API_BASE_URL=https://api.your-domain.example/api/v1/
   ```

6. Put `google-services.json` in `android/app/` only on authorised developer/build machines. Do not commit it.
7. Run `./gradlew testDebugUnitTest lintDebug assembleDebug` before sharing an APK.

## iOS

1. Open `ios/BKKCommunity.xcodeproj`.
2. Set an Apple development team and unique bundle identifier if required.
3. Confirm the committed `BKK_API_BASE_URL` Railway endpoint or replace it through an environment-specific Info.plist/build setting with another verified HTTPS API.
4. Add `GoogleService-Info.plist`, APNs capability and remote-notification registration only after creating the authorised Firebase/Apple configuration.
5. Run on a simulator and a physical iPhone.

## Verified Railway API

The mobile clients default to:

```text
https://www.bkkcommunity.online/api/v1
```

On 13 August 2026, `/health`, database-backed `/ready`, public reads, registration, session revocation, login, authenticated profile, labelled event details, duplicate RSVP prevention, attendance history, cancellation and account deletion passed over HTTPS. The canonical source is [kxcy77/BKKCommunity-Web](https://github.com/kxcy77/BKKCommunity-Web). Password-reset requests correctly return HTTP 503 `email_unavailable` until a verified SMTP provider is added; do not claim email delivery before an inbox receives a real code.

## Canonical PHP API with local MySQL

```bash
git clone https://github.com/kxcy77/BKKCommunity-Web.git
cd BKKCommunity-Web
composer install
cp .env.example .env
# Fill in local database values and independent reset/SMTP values outside Git.
php -S 127.0.0.1:8080 -t public public/router.php
```

## Experimental Node API with local MySQL

Option A uses Docker:

```bash
cp .env.compose.example .env
# Replace every placeholder in .env.
docker compose up --build
```

Option B uses an existing MySQL 8 server:

```bash
cd api
cp .env.example .env
# Fill in real local values.
npm ci
npm run db:migrate
npm test
npm run dev
```

The experimental API listens on port 8000 by default. It is not the production deployment source.

The demo seed deletes public content and is therefore refused unless `ALLOW_DEMO_SEED=true`. Use it only against a disposable local database:

```bash
ALLOW_DEMO_SEED=true npm run db:seed
```

## Admin dashboard

Production administration is the same-origin, server-rendered `/admin` area in `BKKCommunity-Web`, protected by the PHP session and a database administrator role. The bundled static `admin/` folder is experimental reference code only.

Do not put secrets in `config.js`; browser files are public. The API URL is not a secret.

## Railway + MySQL production checklist

1. Create a Railway MySQL service and API service.
2. Set every required API environment variable; never upload `.env`.
3. Configure SMTP and Firebase only in Railway variables.
4. Deploy the `BKKCommunity-Web` Dockerfile. It tracks and applies numbered MySQL migrations before Nginx/PHP-FPM becomes ready.
5. Confirm `/health` and `/ready` over HTTPS.
6. Create the first admin through a controlled one-time operational process. Do not commit a known-password bootstrap script.
7. Test registration, login, logout/revocation, reset email, RSVP duplicate prevention, admin CRUD and fresh read-back.
8. Configure all three clients with the confirmed HTTPS hostname.
9. Disable/remove any initializer or demo-seed setting after approved content is loaded.
10. Attach logs/screenshots without credentials or personal information to the test evidence pack.

## Secret generation

Generate independent secrets locally; do not paste them into chat or commit them:

```bash
openssl rand -base64 48
openssl rand -base64 48
```

Any credential previously distributed in an archive must be rotated, even if the file was later deleted.
