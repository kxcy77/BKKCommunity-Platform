# Administrator security deployment checklist

Use this checklist when moving the remediated administrator system to staging and production. Source-code tests passing locally do not prove that Railway is running the same revision.

## Before deployment

- Back up the production MySQL database and verify that the backup can be restored.
- Confirm `APP_ENV=production`, `ALLOW_DEMO_MODE=false`, all `DEMO_*` values are absent, and all `DB_*` values point to the managed MySQL service.
- Set `ADMIN_IDLE_TIMEOUT_SECONDS=1800`, `ADMIN_ABSOLUTE_TIMEOUT_SECONDS=28800` and `CONTACT_RETENTION_DAYS=365`, or record approved alternatives.
- Keep `RUN_DATABASE_INITIALIZATION=false` on an existing database.
- Confirm `.env`, Resend/SMTP secrets and database credentials are not committed to Git.

## Database migration

The normal container startup runs numbered migrations. Confirm that `007_admin_security_and_audit.sql` appears in `schema_migrations` and that both of these exist:

- `users.auth_version`
- `events.row_version`, `discounts.row_version` and `local_services.row_version`
- `admin_audit_log`

Do not deploy the new PHP code against a database where migration 007 failed, because login and administrator revalidation depend on `auth_version`.

## Staging verification

Run the persistent test against an isolated staging database:

```bash
BKK_BASE_URL=https://staging.example.test \
BKK_TEST_DB_NAME=bkk_staging_test \
BKK_TEST_DB_USER=test_runner \
./tests/admin-database-integration.sh
```

The script creates and removes its own test records. Never point it at production.

Manually verify at 375px, 768px and 1440px:

- member accounts cannot open any `/admin/` page;
- event, discount and service edit forms retain correct values;
- archive removes content from public pages and restore returns it;
- archive/restore reasons appear in Audit history;
- message search, status filters and pagination work;
- keyboard focus, 200% zoom and a screen reader can reach every administrator control.

## Production smoke check

- `/health` returns `200` and `/ready` returns `200`.
- Signed-out `/admin/` requests redirect to login.
- A real administrator can log in; a member cannot enter Admin.
- No demonstration email or password appears on the login page.
- Create one clearly labelled production verification record, edit it, archive it and confirm its audit entry, then remove it according to the approved content process.
- Configure a protected scheduled job for `./bin/purge-resolved-contact-messages.php` and review its first audit entry.

## Rollback

If verification fails, roll back the application revision but do not drop `auth_version` or `admin_audit_log`. Preserve audit evidence and restore data only from the verified backup. Record the failure, correlation reference and corrective action before retrying.
