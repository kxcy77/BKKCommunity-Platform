# Backup Scope

Created: 18 August 2026

This clean backup includes the current source from:

- `BKKCommunity-Clean/android` → `apps/android`
- `BKKCommunity-Clean/ios` → `apps/ios`
- `BKKCommunity-Web-live` → `services/web`
- `BKKCommunity-Clean/docs` → `docs`
- `BKKCommunity-Clean/database` → `database-reference`
- `BKKCommunity-Clean/api` and `admin` → `reference/`

The separate `BKK-Community-PasswordReset-Fix` folder is an older duplicate/prototype and is intentionally not merged into the clean repository. Keep the original folder separately only if historical recovery is needed.

All generated output, third-party dependency folders, secrets and signing material are excluded by `.gitignore`.
