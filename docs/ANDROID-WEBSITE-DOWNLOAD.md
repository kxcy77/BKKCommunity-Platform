# Android download from the website

The homepage **Get the Android app** button and the footer's **Download Android app** link open `/download.php`. The existing five-choice main navigation is unchanged.

The page is public; no account is needed to download. It explains Android compatibility, installation, how to keep Play Protect enabled and what to do if an existing installation has a signing conflict. iPhone visitors are directed to the website rather than an incompatible APK.

The download button calls `/download-apk.php`, which accepts GET/HEAD and redirects to a fixed, versioned GitHub release asset. Request parameters cannot change the destination. GitHub serves the APK; Railway does not stream a large file through PHP. APK binaries and signing keys remain outside the source repository.

## Published build

- Release tag: `android-test-v1.1.0` (public prerelease).
- Filename: `BKK-Community-1.1.0-testing.apk`.
- Version: `1.1.0-debug`, version code 2; Android 8/API 26 or newer.
- Size: 22,051,897 bytes, approximately 21 MiB.
- SHA-256: `803c2670b9912d01a382b65e38942ef8586a89dc568c9b7d108bb1358daede58`.
- Package: `za.co.bkkcommunity.app.debug`.
- Backend: `https://bkkcommunity-platform-2-production.up.railway.app/api/v1/`.

This is the previously tested debug-signed APK, not a new build or a Play Store production release. A separately managed release-signing key and release process are still needed for a production-signed distribution. Do not describe it as Play Store approved.

## Verification on 16 October 2026

APK archive integrity and signing verification passed. Manifest inspection confirmed the version, package and minimum SDK. Inspection confirmed the intended Railway API URL. The public GitHub asset downloaded without authentication and its SHA-256 matched the local APK.

In the local browser, clicking the actual website button downloaded the APK into Downloads. That downloaded file's SHA-256 also matched. Web smoke tests passed, including guest access, the fixed redirect despite a supplied destination parameter, POST rejection, checksum display and installation guidance. The existing navigation-limit and admin regression checks remain passing.

## Updating the download

The download page also provides a scannable QR image and a printable A4 QR poster under `public/assets/downloads/`. Both encode the stable HTTPS download-page address, not a particular APK version or an external QR tracking service. Scanning opens the page; the visitor then selects Download Android APK. This keeps the same printed code useful after future APK updates and provides compatibility/safety instructions before installation.

Rebuild these assets with `python3 services/web/bin/build-download-qr.py` from the repository root (requires Pillow and ReportLab). An independent ZXing decoder verified both the PNG and a rasterized copy of the PDF against the intended production URL. That is automated scan verification, not a claim of a physical-phone camera test.

1. Build and test the next APK against the intended backend. For updates to an existing installation, preserve the package ID and signing key and increase the version code.
2. Publish the APK as a new versioned GitHub release asset. Do not silently replace bytes under an already advertised filename/checksum.
3. Update `services/web/app/android_download.php` with the version, asset URL, filename and computed SHA-256. Update download-page size/requirements if needed.
4. Update the pinned download assertions in `services/web/tests/smoke.sh`, then run the checks and deploy the website.
5. Test the public website button and verify the downloaded file's hash. Never claim installation/device compatibility from a successful HTTP response alone.
