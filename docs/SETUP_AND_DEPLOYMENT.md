# Setup and deployment

## Android Studio

1. Open the `apps/android` folder—the one containing `settings.gradle.kts`.
2. Use Android Studio and a JDK matching your computer's CPU architecture. On an Apple Silicon Mac, the embedded runtime must be ARM64, not an Intel-only JBR. The Gradle daemon criteria select Java 25; Android source and Kotlin bytecode target JVM 17 separately. CLI verification on 1 October 2026 used JDK 21 to start Gradle.
3. Let Gradle sync.
4. Android defaults to the verified Railway HTTPS API. For a local API, add this override to user/project Gradle properties outside Git:

   ```properties
   BKK_DEBUG_API_BASE_URL=http://10.0.2.2:8000/api/v1/
   ```

5. To target a different release environment, set its verified HTTPS value:

   ```properties
   BKK_API_BASE_URL=https://api.your-domain.example/api/v1/
   ```

6. Put `google-services.json` in `apps/android/app/` only on authorised developer/build machines. Do not commit it.
7. Run `./gradlew testDebugUnitTest lintDebug assembleDebug` before sharing an APK.

If iCloud creates duplicate/offloaded files inside generated build output, keep the checkout outside a synced folder, or set `BKK_BUILD_ROOT` to an absolute local build-output directory outside iCloud. This optional environment variable changes output locations only; never commit a personal SDK path or local configuration.

## Railway API and verification limits

The Android app defaults to:

```text
https://bkkcommunity-platform-2-production.up.railway.app/api/v1
```

The canonical source is now `services/web` in [BKKCommunity-Platform](https://github.com/kxcy77/BKKCommunity-Platform). On 1 October 2026, production readiness and public content reads were checked separately from the local MySQL integration suites. See `docs/verification/2026-10-01` for the current evidence and its limits. Historical August results do not prove current password-reset email or push delivery; confirm these with a real inbox and device before claiming they work.

## Canonical PHP API with local MySQL

```bash
git clone https://github.com/kxcy77/BKKCommunity-Platform.git
cd BKKCommunity-Platform/services/web
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
cd reference/api
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

Production administration is the same-origin, server-rendered `/admin` area in `services/web`, protected by the PHP session and a database administrator role. The bundled static `reference/admin/` folder is experimental reference code only.

Do not put secrets in `config.js`; browser files are public. The API URL is not a secret.

## Railway + MySQL production checklist

1. Create a Railway MySQL service and API service.
2. Set every required API environment variable; never upload `.env`.
3. Configure SMTP and Firebase only in Railway variables.
4. Deploy the `services/web` Dockerfile, with Railway's service root set to `services/web`. It tracks and applies numbered MySQL migrations before Nginx/PHP-FPM becomes ready.
5. Confirm `/health` and `/ready` over HTTPS.
6. Create the first admin through a controlled one-time operational process. Do not commit a known-password bootstrap script.
7. Test registration, login, logout/revocation, reset email, RSVP duplicate prevention, admin CRUD and fresh read-back.
8. Configure the website and Android app with the confirmed HTTPS hostname.
9. Disable/remove any initializer or demo-seed setting after approved content is loaded.
10. Attach logs/screenshots without credentials or personal information to the test evidence pack.

## Secret generation

Generate independent secrets locally; do not paste them into chat or commit them:

```bash
openssl rand -base64 48
openssl rand -base64 48
```

Any credential previously distributed in an archive must be rotated, even if the file was later deleted.
