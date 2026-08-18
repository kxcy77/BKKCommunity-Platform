# Team sharing guide

Share the root cleaned project, not a copy of only the Android app. It contains the clients, API, MySQL migration, admin dashboard and current documentation.

Recommended workflow:

1. Create one group GitHub repository.
2. Run a secret scan before the first push and after every credential incident.
3. Commit source only; the root `.gitignore` excludes machine files, Firebase files, credentials, build outputs and signing material.
4. Protect `main`, use focused branches and require at least one group review.
5. Track environment setup in `.env.example` files, never in real `.env` files.
6. Share APKs/IPAs separately as labelled development builds; do not commit them to Git.

Each Android developer opens the `android/` folder directly. Each iOS developer opens `ios/BKKCommunity.xcodeproj`.

