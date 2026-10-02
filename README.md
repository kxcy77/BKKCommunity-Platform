# BKK Community Platform

This is the clean, source-only backup repository for the BKK Community group project. It combines the Android app, canonical website/API, shared documentation and development-reference code in one place.

**New to the project? Start with [START_HERE.md](START_HERE.md).**

The assessed scope is Android plus the website, administrator pages and shared PHP/MySQL API. Older reports in `docs/submission` and dated audit reports describe earlier work and are historical evidence, not the current platform scope.

Read [the latest verification report and screenshot evidence](docs/verification/2026-10-01/REPORT.md) for the checks performed, corrections made and outstanding production/device release gates.

## Start here

| Area | Location | Purpose |
|---|---|---|
| Android app | `apps/android/` | Kotlin and Jetpack Compose member app; open this folder in Android Studio |
| Canonical website and API | `services/web/` | PHP/MySQL website, administration dashboard and deployed `/api/v1` service |
| Documentation | `docs/` | Platform explainer, viva guide, test evidence and release gates |
| Database reference | `database-reference/` | Shared schema reference from the mobile handover |
| Experimental references | `reference/` | Node API and static admin prototypes; not the production backend |

## What is intentionally excluded

This repository does **not** contain generated build output, `node_modules`, Composer vendor packages, SDK paths, `.env` files, API keys, signing keys, Firebase configuration or APK files. Those files make a backup large, unsafe or machine-specific. Install dependencies/build locally after downloading the ZIP.

## Source of truth

The deployed website and mobile JSON API are in `services/web/` and use PHP/MySQL. The code under `reference/` is retained for development comparison only; it must not be deployed to the production hostname.

## Group contribution rule

Every member should use their own GitHub account, work on a branch, make real focused commits, open a pull request, and describe what they changed and tested. Do not rewrite history or use someone else’s identity. The initial commit is a truthful consolidation snapshot, not evidence that one person authored every earlier file.

Read [the platform explainer and viva guide](docs/PLATFORM_EXPLAINER_AND_VIVA.md) before changing the project.

For exact setup steps on another group member's computer, read [GETTING_STARTED.md](GETTING_STARTED.md).

For the shared Visual Studio Code workflow and one-click safety checks, read [docs/VISUAL_STUDIO_CODE_WORKFLOW.md](docs/VISUAL_STUDIO_CODE_WORKFLOW.md) and open `BKKCommunity-Platform.code-workspace`.
