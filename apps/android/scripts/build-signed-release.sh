#!/usr/bin/env bash
set -euo pipefail

android_dir="$(cd "$(dirname "$0")/.." && pwd)"

required=(
  BKK_RELEASE_STORE_FILE
  BKK_RELEASE_STORE_PASSWORD
  BKK_RELEASE_KEY_ALIAS
  BKK_RELEASE_KEY_PASSWORD
)

for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 2
  fi
done

if [[ "$BKK_RELEASE_STORE_FILE" != /* || ! -f "$BKK_RELEASE_STORE_FILE" ]]; then
  echo "BKK_RELEASE_STORE_FILE must point to an existing absolute keystore path." >&2
  exit 2
fi

cd "$android_dir"
./gradlew --no-daemon clean testDebugUnitTest lintDebug assembleRelease

apk="$android_dir/app/build/outputs/apk/release/app-release.apk"
if [[ ! -f "$apk" ]]; then
  echo "Signed APK was not produced at the expected path: $apk" >&2
  exit 1
fi

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_root" ]]; then
  echo "Set ANDROID_SDK_ROOT or ANDROID_HOME so the signature can be verified." >&2
  exit 2
fi

apksigner="$(find "$sdk_root/build-tools" -type f -name apksigner | sort -V | tail -1)"
if [[ -z "$apksigner" || ! -x "$apksigner" ]]; then
  echo "Android apksigner was not found under $sdk_root/build-tools." >&2
  exit 2
fi

"$apksigner" verify --verbose --print-certs "$apk"
shasum -a 256 "$apk" | tee "$apk.sha256"

echo "Verified signed release APK: $apk"
echo "Checksum file: $apk.sha256"
