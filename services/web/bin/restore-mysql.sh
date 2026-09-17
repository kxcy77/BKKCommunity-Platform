#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/backup.sql.gz.gpg" >&2
  exit 2
fi

backup_path="$1"
required=(DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD BKK_BACKUP_ENCRYPTION_PASSPHRASE BKK_RESTORE_CONFIRM)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required restore variable: $name" >&2
    exit 2
  fi
done

if [[ "$backup_path" != /* || ! -f "$backup_path" ]]; then
  echo "The backup must be an existing absolute file path." >&2
  exit 2
fi

if [[ "$BKK_RESTORE_CONFIRM" != "$DB_NAME" ]]; then
  echo "Refusing restore: BKK_RESTORE_CONFIRM must exactly match DB_NAME." >&2
  exit 2
fi

if [[ "${APP_ENV:-development}" == "production" && "${BKK_ALLOW_PRODUCTION_RESTORE:-false}" != "true" ]]; then
  echo "Production restore is locked. Restore into an isolated verification database first." >&2
  exit 2
fi

if [[ -f "$backup_path.sha256" ]]; then
  (cd "$(dirname "$backup_path")" && shasum -a 256 -c "$(basename "$backup_path").sha256")
else
  echo "Refusing restore because the checksum file is missing: $backup_path.sha256" >&2
  exit 2
fi

temporary="$(mktemp /tmp/bkk-restore.XXXXXX.sql.gz)"
trap 'rm -f "$temporary"' EXIT

gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
  --decrypt --output "$temporary" "$backup_path" \
  3<<<"$BKK_BACKUP_ENCRYPTION_PASSPHRASE"

gzip -t "$temporary"
gzip -dc "$temporary" | MYSQL_PWD="$DB_PASSWORD" mysql \
  --protocol=TCP --host="$DB_HOST" --port="$DB_PORT" \
  --user="$DB_USER" --database="$DB_NAME" --default-character-set=utf8mb4

table_count="$(MYSQL_PWD="$DB_PASSWORD" mysql --batch --skip-column-names \
  --protocol=TCP --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --database="$DB_NAME" \
  --execute="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ('users','events','discounts','local_services','schema_migrations');")"

if [[ "$table_count" != "5" ]]; then
  echo "Restore completed but required-table verification failed: found $table_count of 5." >&2
  exit 1
fi

echo "Restore and required-table verification passed for database: $DB_NAME"
