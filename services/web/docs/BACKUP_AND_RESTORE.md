# Production backup and restore runbook

## Required production control

Enable Railway's native backup schedules on the **production MySQL volume**:

- daily backup, retained for the Railway daily retention window;
- weekly backup, retained for the Railway weekly retention window;
- monthly backup, retained for the Railway monthly retention window.

Take a labelled manual backup immediately before a schema migration or major content import. Capture the Backups screen with the project name, schedule and timestamps visible, but hide connection credentials.

Railway native backups are the primary recovery mechanism. The encrypted logical dump below provides a portable second copy and a way to rehearse a restore into an isolated database.

## Create an encrypted logical backup

Set database values through the shell or Railway variables; never put them into source control. `BKK_BACKUP_OUTPUT_DIR` must be a specific absolute path on protected storage. The encryption passphrase must be stored in a password manager shared with the authorised system owner.

```bash
export DB_HOST=...
export DB_PORT=3306
export DB_NAME=bkk_community
export DB_USER=...
export DB_PASSWORD=...
export BKK_BACKUP_OUTPUT_DIR=/absolute/protected/backup/location
export BKK_BACKUP_ENCRYPTION_PASSPHRASE=...
./bin/backup-mysql.sh
```

The command produces an encrypted `.sql.gz.gpg` file and a SHA-256 checksum. Copy both files to storage that is separate from the production service.

## Safe restore rehearsal

Never rehearse against production. Create a new empty MySQL database such as `bkk_restore_verification_YYYYMMDD`, use separate temporary credentials, and set the exact database name as the confirmation value:

```bash
export APP_ENV=staging
export DB_NAME=bkk_restore_verification_YYYYMMDD
export BKK_RESTORE_CONFIRM="$DB_NAME"
./bin/restore-mysql.sh /absolute/path/bkk-backup.sql.gz.gpg
```

Record:

1. backup timestamp and checksum;
2. restoration start and finish time;
3. required-table verification result;
4. row counts for users, events, discounts, local services and schema migrations;
5. the person who executed and independently checked the rehearsal;
6. destruction of the temporary verification database after evidence is captured.

## Production recovery

Production recovery requires client/system-owner approval and a current pre-restore backup. Prefer Railway's staged volume restore. Review the restored volume before applying the staged deployment. The command-line script remains locked in production unless `BKK_ALLOW_PRODUCTION_RESTORE=true` and `BKK_RESTORE_CONFIRM` exactly matches the database name.
