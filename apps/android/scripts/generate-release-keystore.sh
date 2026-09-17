#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /absolute/path/BKKCommunity-release.keystore key-alias" >&2
  exit 2
fi

keystore_path="$1"
key_alias="$2"

if [[ "$keystore_path" != /* ]]; then
  echo "The keystore path must be absolute and outside the Git repository." >&2
  exit 2
fi

if [[ -e "$keystore_path" ]]; then
  echo "Refusing to overwrite existing signing material: $keystore_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$keystore_path")"
chmod 700 "$(dirname "$keystore_path")"

keytool -genkeypair \
  -v \
  -keystore "$keystore_path" \
  -storetype PKCS12 \
  -alias "$key_alias" \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -dname "CN=BKK Community Platform, OU=WDP371, O=BKK Community, L=Johannesburg, ST=Gauteng, C=ZA"

chmod 600 "$keystore_path"
echo "Created release keystore at $keystore_path"
echo "Back it up securely. Losing it prevents future in-place app updates."
