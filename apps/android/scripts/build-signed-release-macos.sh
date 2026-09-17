#!/usr/bin/env bash
set -euo pipefail

keystore_path="${BKK_RELEASE_STORE_FILE:-/Users/videomacbookpro/Documents/BKKCommunity-Release-Secrets/BKKCommunity-release-v1.keystore}"
key_alias="${BKK_RELEASE_KEY_ALIAS:-bkk-community-release-v1}"
keychain_service="${BKK_RELEASE_KEYCHAIN_SERVICE:-BKKCommunity Release Keystore Password}"

if [[ ! -f "$keystore_path" ]]; then
  echo "Release keystore not found: $keystore_path" >&2
  exit 2
fi

password="$(security find-generic-password -a "$USER" -s "$keychain_service" -w)"
if [[ -z "$password" ]]; then
  echo "The release password was not found in macOS Keychain service: $keychain_service" >&2
  exit 2
fi

export BKK_RELEASE_STORE_FILE="$keystore_path"
export BKK_RELEASE_STORE_PASSWORD="$password"
export BKK_RELEASE_KEY_ALIAS="$key_alias"
export BKK_RELEASE_KEY_PASSWORD="$password"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/Users/videomacbookpro/Library/Android/sdk}"

"$(dirname "$0")/build-signed-release.sh"
