#!/usr/bin/env bash
set -euo pipefail
trap 'echo "FAIL registered-users integration at line $LINENO" >&2' ERR
base_url="${BKK_BASE_URL:-http://127.0.0.1:8090}"
database_name="${BKK_TEST_DB_NAME:?Use a disposable test database}"
database_user="${BKK_TEST_DB_USER:-root}"
stamp="$(date +%s)"
prefix="directory.${stamp}"
email="${prefix}@example.test"
android_email="${prefix}.android@example.test"
legacy_email="${prefix}.legacy@example.test"
cookie_jar="$(mktemp /tmp/bkk-users-cookie.XXXXXX)"
mysql_test() { mysql -N -B -u "$database_user" -D "$database_name" -e "$1"; }
csrf_from() { sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | sed -n '1p'; }
contains() { grep -F "$1" >/dev/null; }
cleanup() {
  mysql_test "DELETE FROM users WHERE email LIKE '${prefix}%@example.test';" >/dev/null 2>&1 || true
  rm -f "$cookie_jar"
}
trap cleanup EXIT
guest_status="$(curl -sS -o /dev/null -w '%{http_code}' "$base_url/admin/users.php")"
[[ "$guest_status" == 302 ]] || { echo "FAIL guest directory response: $guest_status"; exit 1; }
html="$(curl -fsS -c "$cookie_jar" "$base_url/register.php")"
csrf="$(printf '%s' "$html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=$csrf" --data-urlencode 'action=register' \
  --data-urlencode 'full_name=Directory Test Member' --data-urlencode "email=$email" \
  --data-urlencode 'phone=' --data-urlencode 'password=DirectoryPass26' \
  --data-urlencode 'password_confirmation=DirectoryPass26' --data-urlencode 'privacy_consent=1' "$base_url/actions.php"
origin="$(mysql_test "SELECT signup_platform FROM users WHERE email='$email';")"
[[ "$origin" == website ]] || { echo "FAIL website registration origin: '${origin}'"; exit 1; }
login() {
  local html csrf
  html="$(curl -fsSL -b "$cookie_jar" -c "$cookie_jar" "$base_url/login.php")"
  csrf="$(printf '%s' "$html" | csrf_from)"
  curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
    --data-urlencode "csrf_token=$csrf" --data-urlencode 'action=login' \
    --data-urlencode "email=$email" --data-urlencode 'password=DirectoryPass26' "$base_url/actions.php"
}
login
[[ "$(curl -sS -b "$cookie_jar" -o /dev/null -w '%{http_code}' "$base_url/admin/users.php")" == 403 ]]
echo 'PASS guests and members cannot read registered users'
mysql_test "UPDATE users SET role='admin',auth_version=auth_version+1 WHERE email='$email';" >/dev/null
login
curl -fsS -H 'Content-Type: application/json' \
  -d "{\"full_name\":\"Directory Android\",\"email\":\"$android_email\",\"phone\":\"0715550202\",\"password\":\"DirectoryPass26\",\"platform\":\"android\"}" "$base_url/api/v1/auth/register" >/dev/null
curl -fsS -H 'Content-Type: application/json' \
  -d "{\"full_name\":\"Directory Legacy\",\"email\":\"$legacy_email\",\"password\":\"DirectoryPass26\"}" "$base_url/api/v1/auth/register" >/dev/null
[[ "$(mysql_test "SELECT signup_platform FROM users WHERE email='$android_email';")" == android ]]
[[ "$(mysql_test "SELECT signup_platform FROM users WHERE email='$legacy_email';")" == unknown ]]
[[ "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d '{"platform":"ios"}' "$base_url/api/v1/auth/register")" == 422 ]]
[[ "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d "{\"full_name\":\"Duplicate\",\"email\":\"$android_email\",\"password\":\"DirectoryPass26\",\"platform\":\"website\"}" "$base_url/api/v1/auth/register")" == 409 ]]
curl -fsS -H 'Content-Type: application/json' -d "{\"email\":\"$email\",\"password\":\"DirectoryPass26\"}" "$base_url/api/v1/auth/login" >/dev/null
[[ "$(mysql_test "SELECT signup_platform FROM users WHERE email='$email';")" == website ]]
echo 'PASS website/Android/legacy origins, optional phone, invalid platform, duplicate email and cross-platform login'
html="$(curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search=$stamp")"
printf '%s' "$html" | contains 'Not provided'
printf '%s' "$html" | contains 'Unknown / legacy'
printf '%s' "$html" | contains '0715550202'
printf '%s' "$html" | contains 'Directory Android'
! printf '%s' "$html" | contains 'password_hash'
! printf '%s' "$html" | contains 'DirectoryPass26'
curl -fsSI -b "$cookie_jar" "$base_url/admin/users.php" | contains 'Cache-Control: no-store, private'
html="$(curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search=$stamp&platform=android")"
printf '%s' "$html" | contains 'Directory Android'
! printf '%s' "$html" | contains 'Directory Legacy'
html="$(curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search=0715550202")"
printf '%s' "$html" | contains 'Directory Android'
html="$(curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search=nothingmatches$stamp")"
printf '%s' "$html" | contains 'No registered users match'
for number in {1..26}; do
  mysql_test "INSERT INTO users(full_name,email,password_hash,signup_platform) VALUES ('Directory page $number','${prefix}.page${number}@example.test','not-a-login-hash','android');" >/dev/null
done
html="$(curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search=$stamp&platform=android&page=2")"
[[ "$(printf '%s' "$html" | php -r '$html=stream_get_contents(STDIN);preg_match_all("/<tr><td>/",$html,$m);echo count($m[0]);')" == 2 ]]
printf '%s' "$html" | contains 'platform=android'
curl -fsS -b "$cookie_jar" "$base_url/admin/users.php?search%5B%5D=x&platform%5B%5D=x&page%5B%5D=x" >/dev/null
echo 'PASS directory search, platform filters, empty results, 25-row pagination, malformed queries and private responses'
