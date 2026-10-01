# Backup Scope

Original consolidation: 18 August 2026. Current scope updated: 1 October 2026.

The active delivery contains Android and the website/admin/API. Native iOS source was removed from the current checkout and retained in a separate local recovery archive. Earlier dated submission documents remain historical evidence and have not been rewritten to invent a different development history.

This clean backup includes the current source from:

- `BKKCommunity-Clean/android` → `apps/android`
- `BKKCommunity-Web-live` → `services/web`
- `BKKCommunity-Clean/docs` → `docs`
- `BKKCommunity-Clean/database` → `database-reference`
- `BKKCommunity-Clean/api` and `admin` → `reference/`

The separate `BKK-Community-PasswordReset-Fix` folder is an older duplicate/prototype and is intentionally not merged into the clean repository. Keep the original folder separately only if historical recovery is needed.

All generated output, third-party dependency folders, secrets and signing material are excluded by `.gitignore`.
