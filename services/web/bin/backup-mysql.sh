#!/usr/bin/env bash
set -euo pipefail

required=(DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD BKK_BACKUP_OUTPUT_DIR BKK_BACKUP_ENCRYPTION_PASSPHRASE)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required backup variable: $name" >&2
    exit 2
  fi
done

if [[ "$BKK_BACKUP_OUTPUT_DIR" != /* || "$BKK_BACKUP_OUTPUT_DIR" == "/" ]]; then
  echo "BKK_BACKUP_OUTPUT_DIR must be a specific absolute directory." >&2
  exit 2
fi

for command_name in mysqldump gzip gpg shasum; do
  command -v "$command_name" >/dev/null || {
    echo "Required backup command is unavailable: $command_name" >&2
    exit 2
  }
done

umask 077
mkdir -p "$BKK_BACKUP_OUTPUT_DIR"
stamp="$(date -u +'%Y%m%dT%H%M%SZ')"
base="$BKK_BACKUP_OUTPUT_DIR/bkk-${DB_NAME}-${stamp}.sql.gz"
encrypted="$base.gpg"
temporary="$(mktemp "${base}.partial.XXXXXX")"
trap 'rm -f "$temporary" "$base"' EXIT

dump_options=(
  --protocol=TCP \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --user="$DB_USER" \
  --single-transaction \
  --skip-lock-tables \
  --quick \
  --routines \
  --events \
  --triggers \
  --hex-blob \
  --default-character-set=utf8mb4 \
  --no-tablespaces
)

dump_help="$(mysqldump --help 2>/dev/null || true)"
if grep -q -- '--set-gtid-purged' <<<"$dump_help"; then
  dump_options+=(--set-gtid-purged=OFF)
fi
if grep -q -- '--masking-policies' <<<"$dump_help"; then
  dump_options+=(--skip-masking-policies)
fi

MYSQL_PWD="$DB_PASSWORD" mysqldump "${dump_options[@]}" "$DB_NAME" | gzip -9 >"$temporary"

test -s "$temporary"
mv "$temporary" "$base"

gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
  --symmetric --cipher-algo AES256 --output "$encrypted" "$base" \
  3<<<"$BKK_BACKUP_ENCRYPTION_PASSPHRASE"

rm -f "$base"
(cd "$(dirname "$encrypted")" && shasum -a 256 "$(basename "$encrypted")" >"$(basename "$encrypted").sha256")
chmod 600 "$encrypted" "$encrypted.sha256"
trap - EXIT

echo "Encrypted MySQL backup created: $encrypted"
echo "Checksum created: $encrypted.sha256"
