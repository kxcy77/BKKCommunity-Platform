# Working Safely in Visual Studio Code

## Use the shared workspace

1. Install **Visual Studio Code**.
2. Open `BKKCommunity-Platform.code-workspace` from the repository root.
3. Install the recommended PHP extensions if Visual Studio Code asks.
4. Use **Terminal > Run Task** or `Command + Shift + B` to choose a BKK task.

The workspace hides generated build folders so group members focus on source code. It includes safe checks for PHP and Android.

## What Visual Studio Code can and cannot do

| Work | Correct tool |
|---|---|
| Edit website, Android, documentation and configuration | Visual Studio Code |
| Run/check the PHP website | Visual Studio Code tasks + PHP |
| Build/run/debug Android on a device/emulator | Android Studio |

Visual Studio Code is the shared editor. It does not replace Android Studio. Full Visual Studio for Mac is retired and is not the correct environment for this PHP/Kotlin project.

## Before every commit

1. Pull the latest branch and create your own feature/fix branch.
2. Change one focused thing.
3. Run the relevant check:
   - Website: **BKK: Check website PHP syntax**, then **BKK: Run website locally**.
   - Android: **BKK: Run Android unit tests**, then **BKK: Check and build Android debug app**.
4. Test the screen or flow you changed.
5. Commit only after the relevant checks pass. State what you tested in the pull request.

## If a task fails

- `php: command not found`: install PHP 8.3 or newer, then reopen Visual Studio Code.
- Gradle/JDK error: install Android Studio's JDK/SDK and open `apps/android` in Android Studio once.
- Database/API error: check the documented environment setup and the live `/health`/`ready` status. Do not hard-code credentials or change production URLs randomly.

No editor can make unsafe code changes harmless. The workspace reduces risk by making checks repeatable before a change reaches the shared branch.
