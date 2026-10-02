#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_port="${BKK_TEST_PORT:-8091}"
base_url="http://127.0.0.1:${test_port}"
php "${project_dir}/tests/static-assets.php"
server_log="$(mktemp /tmp/bkk-web-server.XXXXXX)"
cookie_jar="$(mktemp /tmp/bkk-web-cookie.XXXXXX)"

APP_ENV=development \
ALLOW_DEMO_MODE=true \
DB_HOST= \
DEMO_MEMBER_EMAIL=member@bkk.test \
DEMO_MEMBER_PASSWORD='MemberTest!26' \
DEMO_MEMBER_NAME='Test Member' \
DEMO_ADMIN_EMAIL=admin@bkk.test \
DEMO_ADMIN_PASSWORD='AdminTest!26' \
DEMO_ADMIN_NAME='Test Administrator' \
php -S "127.0.0.1:${test_port}" -t "${project_dir}/public" "${project_dir}/public/router.php" >"${server_log}" 2>&1 &
server_pid=$!
prod_pid=""
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  if [[ -n "$prod_pid" ]]; then kill "$prod_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT

for attempt in {1..20}; do
  if curl -fsS "${base_url}/index.php" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

for route in index.php events.php discounts.php info.php contact.php login.php register.php reset-password.php new-password.php offline.html manifest.webmanifest service-worker.js; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "${base_url}/${route}")"
  [[ "$code" == "200" ]] || { echo "FAIL ${route}: HTTP ${code}"; exit 1; }
  echo "PASS ${route}: HTTP ${code}"
done

manifest_file="$(mktemp /tmp/bkk-manifest.XXXXXX)"
php "${project_dir}/tests/static-assets.php" "$base_url"
curl -fsS "${base_url}/manifest.webmanifest" >"${manifest_file}"
php -r '$manifest=json_decode(file_get_contents($argv[1]), true, 512, JSON_THROW_ON_ERROR); if (($manifest["display"] ?? null) !== "standalone" || count($manifest["icons"] ?? []) < 2) exit(1);' "${manifest_file}"
grep -q 'rel="manifest"' <(curl -fsS "${base_url}/index.php") || { echo 'FAIL web app manifest link'; exit 1; }
for private_path in /api/ /admin/ /actions.php /login.php /register.php /reset-password.php /new-password.php /profile.php; do
  grep -q "'${private_path}'" "${project_dir}/public/service-worker.js" || { echo "FAIL service worker private-path exclusion ${private_path}"; exit 1; }
done
echo 'PASS installable web app metadata and private-route cache exclusions'

home_html="$(curl -fsS "${base_url}/index.php")"
nav_count="$(printf '%s' "$home_html" | php -r '$html=stream_get_contents(STDIN); preg_match("/<div class=\"nav-links\">(.*?)<\\/div>/s", $html, $match); preg_match_all("/<a\\s/i", $match[1] ?? "", $links); echo count($links[0]);')"
[[ "$nav_count" == "5" ]] || { echo "FAIL primary navigation has ${nav_count} choices"; exit 1; }
printf '%s' "$home_html" | grep -q 'What would you like to do today?' || { echo 'FAIL simplified home task prompt'; exit 1; }
echo 'PASS primary navigation is limited to five choices and Home has a single task prompt'

(cd "$project_dir" && php -r 'require "app/repository.php"; $demo=["category"=>"Demonstration","title"=>"BKK App Demonstration Event - Not a Real Event","description"=>"TEST CONTENT ONLY","location"=>"Demonstration only - do not travel"]; if (!is_demonstration_event($demo)) exit(1); if (is_demonstration_event(["category"=>"Social","title"=>"Community lunch","description"=>"Meet neighbours","location"=>"BKK Hall"])) exit(1);') \
  || { echo 'FAIL demonstration event safety rule'; exit 1; }
echo 'PASS demonstration events are identified independently of their database ID'

(cd "$project_dir" && php -r 'require "app/auth.php"; if (!administrator_session_expired(2000, 1000, 1900, 50, 5000)) exit(1); if (!administrator_session_expired(7000, 1000, 6990, 50, 5000)) exit(1); if (administrator_session_expired(2000, 1000, 1900, 150, 5000)) exit(1);') \
  || { echo 'FAIL administrator session expiry rules'; exit 1; }
echo 'PASS administrator idle and absolute session-expiry rules'

health_code="$(curl -sS -o /tmp/bkk-health.json -w '%{http_code}' "${base_url}/health")"
[[ "$health_code" == "200" ]] || { echo "FAIL health: HTTP ${health_code}"; exit 1; }
php -r '$json=json_decode(file_get_contents("/tmp/bkk-health.json"), true); if (($json["data"]["status"] ?? null) !== "ok") exit(1);'
echo 'PASS health reports the running service'

ready_code="$(curl -sS -o /tmp/bkk-ready.json -w '%{http_code}' "${base_url}/ready")"
[[ "$ready_code" == "503" ]] || { echo "FAIL unconfigured readiness: HTTP ${ready_code}"; exit 1; }
php -r '$json=json_decode(file_get_contents("/tmp/bkk-ready.json"), true); if (($json["error"]["code"] ?? null) !== "database_unavailable") exit(1);'
echo 'PASS readiness fails closed without a database'

prod_port=$((test_port + 1))
prod_log="$(mktemp /tmp/bkk-web-production.XXXXXX)"
APP_ENV=production ALLOW_DEMO_MODE=false DB_HOST= php -S "127.0.0.1:${prod_port}" -t "${project_dir}/public" "${project_dir}/public/router.php" >"${prod_log}" 2>&1 &
prod_pid=$!
for attempt in {1..20}; do
  prod_code="$(curl -sS -o /tmp/bkk-production-body.txt -w '%{http_code}' "http://127.0.0.1:${prod_port}/index.php" 2>/dev/null || true)"
  [[ "$prod_code" != "000" ]] && break
  sleep 0.2
done
[[ "$prod_code" == "503" ]] || { echo "FAIL production fail-closed mode: HTTP ${prod_code}"; exit 1; }
if grep -Eq 'member@bkk\.demo|admin@bkk\.demo' /tmp/bkk-production-body.txt; then
  echo 'FAIL production response exposed demonstration credentials'
  exit 1
fi
kill "$prod_pid" 2>/dev/null || true
wait "$prod_pid" 2>/dev/null || true
prod_pid=""
echo 'PASS production fails closed when database configuration is absent'

unknown_code="$(curl -sS -o /dev/null -w '%{http_code}' "${base_url}/not-a-real-route")"
[[ "$unknown_code" == "404" ]] || { echo "FAIL unknown route: HTTP ${unknown_code}"; exit 1; }
echo 'PASS unknown routes return 404'

large_body_code="$(php -r 'echo str_repeat("x", 33000);' | curl -sS -o /tmp/bkk-large-body.json -w '%{http_code}' -H 'Content-Type: application/json' --data-binary @- "${base_url}/api/v1/auth/login")"
[[ "$large_body_code" == "413" ]] || { echo "FAIL oversized API body: HTTP ${large_body_code}"; exit 1; }
php -r '$json=json_decode(file_get_contents("/tmp/bkk-large-body.json"), true); if (($json["error"]["code"] ?? null) !== "payload_too_large") exit(1);'
echo 'PASS oversized API bodies are rejected'

for route in profile.php admin/index.php admin/events.php admin/discounts.php admin/services.php admin/messages.php admin/audit.php; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "${base_url}/${route}")"
  [[ "$code" == "302" ]] || { echo "FAIL guest protection ${route}: HTTP ${code}"; exit 1; }
  echo "PASS guest protection ${route}: HTTP ${code}"
done

csrf_code="$(curl -sS -o /dev/null -w '%{http_code}' --data 'action=logout&csrf_token=invalid' "${base_url}/actions.php")"
[[ "$csrf_code" == "419" ]] || { echo "FAIL CSRF protection: HTTP ${csrf_code}"; exit 1; }
echo "PASS CSRF protection: HTTP ${csrf_code}"

login_html="$(curl -sS -c "$cookie_jar" "${base_url}/login.php")"
if printf '%s' "$login_html" | grep -Eq 'member@bkk\.demo|admin@bkk\.demo'; then
  echo 'FAIL login page exposes demonstration credentials'
  exit 1
fi
echo 'PASS login page does not expose demonstration credentials'
csrf="$(printf '%s' "$login_html" | sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" \
  --data-urlencode 'action=login' \
  --data-urlencode 'email=member@bkk.test' \
  --data-urlencode 'password=MemberTest!26' \
  "${base_url}/actions.php"

profile_html="$(curl -fsS -b "$cookie_jar" "${base_url}/profile.php")"
printf '%s' "$profile_html" | grep -q 'Test Member' || { echo 'FAIL member login'; exit 1; }
echo 'PASS member login and protected profile'

member_admin_location="$(curl -sS -b "$cookie_jar" -o /dev/null -w '%{redirect_url}' "${base_url}/admin/index.php")"
[[ "$member_admin_location" == "${base_url}/profile.php" ]] || { echo "FAIL non-admin authorization redirected to ${member_admin_location}"; exit 1; }
echo 'PASS signed-in members cannot enter administrator pages'

admin_cookie="$(mktemp /tmp/bkk-web-admin-cookie.XXXXXX)"
admin_login_html="$(curl -sS -c "$admin_cookie" "${base_url}/login.php")"
admin_csrf="$(printf '%s' "$admin_login_html" | sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${admin_csrf}" \
  --data-urlencode 'action=login' \
  --data-urlencode 'email=admin@bkk.test' \
  --data-urlencode 'password=AdminTest!26' \
  "${base_url}/actions.php"
admin_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/index.php")"
printf '%s' "$admin_html" | grep -q 'Dashboard overview' || { echo 'FAIL admin login'; exit 1; }
echo 'PASS admin login and protected dashboard'

for route in admin/events.php admin/discounts.php admin/services.php admin/messages.php admin/audit.php; do
  code="$(curl -sS -b "$admin_cookie" -o /dev/null -w '%{http_code}' "${base_url}/${route}")"
  [[ "$code" == "200" ]] || { echo "FAIL authenticated ${route}: HTTP ${code}"; exit 1; }
  echo "PASS authenticated ${route}: HTTP ${code}"
done

events_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
events_csrf="$(printf '%s' "$events_html" | sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_create_event' \
  --data-urlencode 'title=Smoke Test Community Event' --data-urlencode 'date=2099-08-20' \
  --data-urlencode 'time=10:00' --data-urlencode 'end_time=11:00' \
  --data-urlencode 'location=BKK Test Hall' --data-urlencode 'category=Community' \
  --data-urlencode 'tone=blue' --data-urlencode 'description=Automated administrator workflow verification event.' \
  --data-urlencode 'directions=Use the main entrance.' "${base_url}/actions.php"
events_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
printf '%s' "$events_html" | grep -q 'Smoke Test Community Event' || { echo 'FAIL administrator event create'; exit 1; }
event_id="$(printf '%s' "$events_html" | php -r '$h=stream_get_contents(STDIN); preg_match("/Smoke Test Community Event.*?edit=([0-9]+)/s", $h, $m); echo $m[1] ?? "";')"
[[ -n "$event_id" ]] || { echo 'FAIL event identifier lookup'; exit 1; }
event_edit_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php?edit=${event_id}")"
event_version="$(printf '%s' "$event_edit_html" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_update_event' --data-urlencode "id=${event_id}" --data-urlencode "version=${event_version}" \
  --data-urlencode 'title=Updated Smoke Test Event' --data-urlencode 'date=2099-08-21' \
  --data-urlencode 'time=10:30' --data-urlencode 'end_time=11:30' --data-urlencode 'location=Updated BKK Test Hall' \
  --data-urlencode 'category=Support' --data-urlencode 'tone=teal' \
  --data-urlencode 'description=Updated automated administrator workflow verification event.' \
  --data-urlencode 'directions=Use the accessible side entrance.' "${base_url}/actions.php"
updated_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
printf '%s' "$updated_html" | grep -q 'Updated Smoke Test Event' || { echo 'FAIL administrator event update'; exit 1; }
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_update_event' --data-urlencode "id=${event_id}" --data-urlencode "version=${event_version}" \
  --data-urlencode 'title=Stale Overwrite Must Not Win' --data-urlencode 'date=2099-08-22' \
  --data-urlencode 'time=10:30' --data-urlencode 'end_time=11:30' --data-urlencode 'location=Stale Test Hall' \
  --data-urlencode 'category=Support' --data-urlencode 'tone=teal' \
  --data-urlencode 'description=This stale concurrent update must be rejected by the repository.' \
  --data-urlencode 'directions=This change must not be saved.' "${base_url}/actions.php"
conflict_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
if printf '%s' "$conflict_html" | grep -q 'Stale Overwrite Must Not Win'; then echo 'FAIL stale administrator overwrite protection'; exit 1; fi
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_set_event_archived' \
  --data-urlencode "id=${event_id}" --data-urlencode 'archived=1' --data-urlencode 'reason=Automated archive verification' \
  "${base_url}/actions.php"
archived_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
printf '%s' "$archived_html" | grep -q 'Updated Smoke Test Event' || { echo 'FAIL archived event retention'; exit 1; }
printf '%s' "$archived_html" | grep -q 'Archived' || { echo 'FAIL event archive state'; exit 1; }
audit_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/audit.php")"
printf '%s' "$audit_html" | grep -q 'Automated archive verification' || { echo 'FAIL administrator audit history'; exit 1; }
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_set_event_archived' \
  --data-urlencode "id=${event_id}" --data-urlencode 'archived=0' --data-urlencode 'reason=Automated restore verification' \
  "${base_url}/actions.php"
restored_public_html="$(curl -fsS -b "$admin_cookie" "${base_url}/events.php")"
printf '%s' "$restored_public_html" | grep -q 'Updated Smoke Test Event' || { echo 'FAIL restored event public visibility'; exit 1; }
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${events_csrf}" --data-urlencode 'action=admin_delete_event' --data-urlencode "id=${event_id}" \
  "${base_url}/actions.php"
legacy_delete_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/events.php")"
printf '%s' "$legacy_delete_html" | grep -q 'Updated Smoke Test Event' || { echo 'FAIL legacy delete action removed content'; exit 1; }
echo 'PASS administrator event create, edit, archive, restore, audit and delete blocking'

discounts_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/discounts.php")"
discounts_csrf="$(printf '%s' "$discounts_html" | sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${discounts_csrf}" --data-urlencode 'action=admin_create_discount' \
  --data-urlencode 'store_name=Smoke Test Pharmacy' --data-urlencode 'category=Pharmacy' \
  --data-urlencode 'deal=Fifteen percent off selected wellness items.' --data-urlencode 'eligibility=Members aged sixty and older' \
  --data-urlencode 'claim_instructions=Show a valid membership card at checkout.' --data-urlencode 'tone=blue' \
  --data-urlencode 'valid_from=2099-08-01' --data-urlencode 'valid_until=2099-09-01' "${base_url}/actions.php"
discounts_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/discounts.php")"
discount_id="$(printf '%s' "$discounts_html" | php -r '$h=stream_get_contents(STDIN); preg_match("/Smoke Test Pharmacy.*?edit=([0-9]+)/s", $h, $m); echo $m[1] ?? "";')"
[[ -n "$discount_id" ]] || { echo 'FAIL administrator discount create'; exit 1; }
discount_edit_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/discounts.php?edit=${discount_id}")"
discount_version="$(printf '%s' "$discount_edit_html" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${discounts_csrf}" --data-urlencode 'action=admin_update_discount' --data-urlencode "id=${discount_id}" --data-urlencode "version=${discount_version}" \
  --data-urlencode 'store_name=Updated Smoke Pharmacy' --data-urlencode 'category=Pharmacy' \
  --data-urlencode 'deal=Twenty percent off selected wellness items.' --data-urlencode 'eligibility=Verified BKK members' \
  --data-urlencode 'claim_instructions=Show a valid membership card before payment.' --data-urlencode 'tone=blue' \
  --data-urlencode 'valid_from=2099-08-01' --data-urlencode 'valid_until=2099-09-30' "${base_url}/actions.php"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${discounts_csrf}" --data-urlencode 'action=admin_set_discount_archived' --data-urlencode "id=${discount_id}" \
  --data-urlencode 'archived=1' --data-urlencode 'reason=Automated discount archive' "${base_url}/actions.php"
discounts_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/discounts.php")"
printf '%s' "$discounts_html" | grep -q 'Updated Smoke Pharmacy' || { echo 'FAIL administrator discount update/archive'; exit 1; }
echo 'PASS administrator discount create, edit and archive workflow'

services_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/services.php")"
services_csrf="$(printf '%s' "$services_html" | sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${services_csrf}" --data-urlencode 'action=admin_create_service' \
  --data-urlencode 'type=support' --data-urlencode 'name=Smoke Test Support Desk' --data-urlencode 'address=1 Test Road' \
  --data-urlencode 'phone=071 555 0101' --data-urlencode 'opening_hours=Weekdays, 08:00-17:00' \
  --data-urlencode 'directions=Ask at the accessible community reception desk.' "${base_url}/actions.php"
services_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/services.php")"
service_id="$(printf '%s' "$services_html" | php -r '$h=stream_get_contents(STDIN); preg_match("/Smoke Test Support Desk.*?edit=([0-9]+)/s", $h, $m); echo $m[1] ?? "";')"
[[ -n "$service_id" ]] || { echo 'FAIL administrator service create'; exit 1; }
service_edit_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/services.php?edit=${service_id}")"
service_version="$(printf '%s' "$service_edit_html" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${services_csrf}" --data-urlencode 'action=admin_update_service' --data-urlencode "id=${service_id}" --data-urlencode "version=${service_version}" \
  --data-urlencode 'type=support' --data-urlencode 'name=Updated Smoke Support Desk' --data-urlencode 'address=2 Test Road' \
  --data-urlencode 'phone=071 555 0102' --data-urlencode 'opening_hours=Weekdays, 09:00-16:00' \
  --data-urlencode 'directions=Ask at the updated accessible reception desk.' "${base_url}/actions.php"
curl -fsS -b "$admin_cookie" -c "$admin_cookie" -o /dev/null \
  --data-urlencode "csrf_token=${services_csrf}" --data-urlencode 'action=admin_set_service_archived' --data-urlencode "id=${service_id}" \
  --data-urlencode 'archived=1' --data-urlencode 'reason=Automated service archive' "${base_url}/actions.php"
services_html="$(curl -fsS -b "$admin_cookie" "${base_url}/admin/services.php")"
printf '%s' "$services_html" | grep -q 'Updated Smoke Support Desk' || { echo 'FAIL administrator service update/archive'; exit 1; }
echo 'PASS administrator local-service create, edit and archive workflow'
