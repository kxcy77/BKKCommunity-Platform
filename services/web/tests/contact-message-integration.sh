#!/usr/bin/env bash
set -euo pipefail
trap 'echo "FAIL exact contact-message test at line $LINENO" >&2' ERR
base_url="${BKK_BASE_URL:-http://127.0.0.1:8116}"
db_name="${BKK_TEST_DB_NAME:?Use a disposable test database}"
db_user="${BKK_TEST_DB_USER:-root}"
[[ "$db_name" == bkk_staff_* || "$db_name" == bkk_ci_test ]] || { echo 'Refusing non-test database'; exit 1; }
prefix="message.$(date +%s)"
test_dir="$(mktemp -d /tmp/bkk-message-test.XXXXXX)"
fixture="$(dirname "$0")/contact-message-body.txt"
body="$(php -r 'echo trim(file_get_contents($argv[1]));' "$fixture")"
sql() { mysql -N -B -u "$db_user" -D "$db_name" -e "$1"; }
csrf_from() { sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | sed -n '1p'; }
cleanup() {
  sql "DELETE FROM contact_messages WHERE email LIKE '${prefix}.%@example.test'; DELETE FROM users WHERE email='${prefix}.owner@example.test';" >/dev/null 2>&1 || true
  find "$test_dir" -type f -delete; rmdir "$test_dir"
}
trap cleanup EXIT
html="$(curl -fsS -c "$test_dir/cookies" "$base_url/contact.php")"
csrf="$(printf '%s' "$html" | csrf_from)"
curl -fsS -b "$test_dir/cookies" -c "$test_dir/cookies" -o /dev/null \
  --data-urlencode "csrf_token=$csrf" --data-urlencode 'action=contact' \
  --data-urlencode 'name=Website message fixture' --data-urlencode "email=${prefix}.web@example.test" \
  --data-urlencode 'subject=Discount enquiry' --data-urlencode "message=$body" "$base_url/actions.php"
payload="$(php -r 'echo json_encode(["name"=>"Android API message fixture","email"=>$argv[1],"message"=>trim(file_get_contents($argv[2]))],JSON_THROW_ON_ERROR);' "${prefix}.android@example.test" "$fixture")"
[[ "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d "$payload" "$base_url/api/v1/contact")" == 201 ]]
expected_hex="$(php -r 'echo strtoupper(bin2hex(trim(file_get_contents($argv[1]))));' "$fixture")"
for platform in web android; do
  [[ "$(sql "SELECT HEX(message) FROM contact_messages WHERE email='${prefix}.${platform}@example.test';")" == "$expected_hex" ]]
done
echo 'PASS website and Android/API submissions save the original body, punctuation, Unicode and line breaks'
hash="$(php -r 'echo password_hash("MessageFixtureOnly26",PASSWORD_DEFAULT);')"
sql "INSERT INTO users(full_name,email,password_hash,role,staff_level) VALUES ('Message verification owner','${prefix}.owner@example.test','$hash','admin','owner');"
html="$(curl -fsS -b "$test_dir/cookies" -c "$test_dir/cookies" "$base_url/login.php")"
csrf="$(printf '%s' "$html" | csrf_from)"
curl -fsS -b "$test_dir/cookies" -c "$test_dir/cookies" -o /dev/null \
  --data-urlencode "csrf_token=$csrf" --data-urlencode 'action=login' \
  --data-urlencode "email=${prefix}.owner@example.test" --data-urlencode 'password=MessageFixtureOnly26' "$base_url/actions.php"
for platform in web android; do
  id="$(sql "SELECT id FROM contact_messages WHERE email='${prefix}.${platform}@example.test';")"
  curl -fsS -b "$test_dir/cookies" "$base_url/admin/messages.php?search=${prefix}.${platform}" -o "$test_dir/inbox"
  php -r '
    $html=file_get_contents($argv[1]); $expected=trim(file_get_contents($argv[2]));
    if (!preg_match("~<div class=\"message-copy\" data-message-id=\"".(int)$argv[3]."\">(.*?)</div>~s",$html,$m)) exit(1);
    if (html_entity_decode($m[1], ENT_QUOTES | ENT_HTML5,"UTF-8") !== $expected) exit(1);
    if (str_contains($m[1],"<script>") || str_contains($m[1],"<b>") || str_contains($html,"<summary>Read message</summary>")) exit(1);
  ' "$test_dir/inbox" "$fixture" "$id"
done
echo 'PASS full bodies are visible without expanding a control; HTML/script text is escaped, not executed'
curl -fsS -G -b "$test_dir/cookies" --data-urlencode 'search=pharmacy offer' "$base_url/admin/messages.php" -o "$test_dir/search"
grep -F "${prefix}.web@example.test" "$test_dir/search" >/dev/null
grep -F "${prefix}.android@example.test" "$test_dir/search" >/dev/null
curl -fsS -G -b "$test_dir/cookies" --data-urlencode 'search=20%' "$base_url/admin/messages.php" -o "$test_dir/search"
grep -F "${prefix}.web@example.test" "$test_dir/search" >/dev/null
echo 'PASS inbox search finds message-body text and literal percentage symbols'
[[ "$(curl -sS -o /dev/null -w '%{http_code}' "$base_url/admin/messages.php")" == 302 ]]
curl -fsSI -b "$test_dir/cookies" "$base_url/admin/messages.php" | grep -i 'Cache-Control: no-store, private' >/dev/null
echo 'PASS inbox remains private and is not stored in browser caches'
