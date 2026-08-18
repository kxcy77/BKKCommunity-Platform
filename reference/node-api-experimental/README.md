# BKK Community API

> Development reference only. The canonical release API is the PHP/MySQL service in [kxcy77/BKKCommunity-Web](https://github.com/kxcy77/BKKCommunity-Web). Do not deploy this Node/Prisma implementation to the mobile apps' production hostname without a planned contract and database migration.

Node 20, Express 4, TypeScript, Prisma 5 and MySQL 8 REST API. All routes are under `/api/v1`.

## Run

```bash
cp .env.example .env
# Fill in local MySQL and independent secrets.
npm ci
npm run db:migrate
npm test
npm run dev
```

`GET /health` reports process health. `GET /ready` also queries MySQL.

## Endpoints

| Method | Route | Access | Request notes |
|---|---|---|---|
| POST | `/auth/register` | Public | name, email, optional phone, strong password |
| POST | `/auth/login` | Public | email and password |
| DELETE | `/auth/session` | Member | revokes the current server session |
| POST | `/auth/forgot-password` | Public | always returns the same account-neutral response |
| POST | `/auth/reset-password` | Public | normalised email, six digits and new password |
| GET/PATCH/DELETE | `/me` | Member | profile/read/update/delete |
| PATCH | `/me/notification-preferences` | Member | three booleans |
| GET | `/me/attendance` | Member | confirmed event history |
| GET | `/events`, `/events/:id` | Public | optional category filter |
| PUT | `/events/:id/attendance` | Member | `attending` or `cancelled` |
| GET | `/discounts`, `/discounts/:id` | Public | optional category filter |
| GET | `/local-services` | Public | optional type filter |
| POST | `/contact` | Public | name, email and 10–3000 character message |
| PUT | `/devices/fcm-token` | Member | token, platform and enabled state |
| POST | `/devices/test-push` | Member | real provider request or honest 503 |
| all | `/admin/*` | Admin | validated CRUD/roles with audit records |

Responses use `{ "data": ... }` or `{ "error": { "message": "..." } }`.

## Security properties

- API refuses to start without MySQL and independent 32+ character JWT/reset secrets.
- Eight-hour HS256 access tokens validate algorithm, issuer, audience, type, subject and JTI.
- Every protected request checks a revocable `auth_sessions` row.
- Password reset codes are random six-digit values; only an email/member-bound HMAC is stored.
- Login lockout, reset attempt counters, rate limits, strict payload validation, request IDs and central error handling are enabled.
- No route logs passwords, tokens, reset codes, contact bodies or email addresses.
- FCM uses HTTP v1 and service-account OAuth. Missing credentials return 503; no simulated success exists.

## Production

Use the Dockerfile. It installs from the lockfile, builds, runs `prisma migrate deploy`, then starts the compiled server. Configure credentials only in the hosting provider. Before release, prove a completely fresh MySQL database can migrate and complete auth/admin CRUD/read-back tests.
