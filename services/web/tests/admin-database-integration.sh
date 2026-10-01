#!/usr/bin/env bash
set -euo pipefail

base_url="${BKK_BASE_URL:-http://127.0.0.1:8090}"
database_name="${BKK_TEST_DB_NAME:-bkk_community}"
database_user="${BKK_TEST_DB_USER:-root}"
stamp="$(date +%s)"
test_email="codex.admin.${stamp}@example.test"
test_name="Integration Admin ${stamp}"
event_title="Integration Event ${stamp}"
updated_event_title="Updated Integration Event ${stamp}"
discount_store="Integration Store ${stamp}"
service_name="Integration Service ${stamp}"
cookie_jar="$(mktemp /tmp/bkk-admin-integration.XXXXXX)"

mysql_test() { mysql -N -B -u "$database_user" -D "$database_name" -e "$1"; }
csrf_from() { sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | head -1; }

assert_api_field() {
  curl -fsS "${base_url}/api/v1/$1" | php -r '
    $rows=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR)["data"];
    foreach ($rows as $row) if ((int)$row["id"] === (int)$argv[1]) {
      if ((string)($row[$argv[2]] ?? "") !== $argv[3]) exit(1);
      exit(0);
    }
    exit(1);' "$2" "$3" "$4"
}

assert_api_absent() {
  curl -fsS "${base_url}/api/v1/$1" | php -r '
    $rows=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR)["data"];
    foreach ($rows as $row) if ((int)$row["id"] === (int)$argv[1]) exit(1);' "$2"
}

cleanup() {
  mysql_test "DELETE FROM contact_messages WHERE email='${test_email}'; DELETE FROM local_services WHERE name='${service_name}'; DELETE FROM discounts WHERE store_name='${discount_store}'; DELETE FROM events WHERE title IN ('${event_title}','${updated_event_title}'); DELETE FROM admin_audit_log WHERE admin_user_id=(SELECT id FROM users WHERE email='${test_email}' LIMIT 1); DELETE FROM users WHERE email='${test_email}'; DELETE FROM api_rate_limits WHERE scope LIKE 'web-%';" >/dev/null 2>&1 || true
  rm -f "$cookie_jar"
}
trap cleanup EXIT

register_html="$(curl -fsS -c "$cookie_jar" "${base_url}/register.php")"
csrf="$(printf '%s' "$register_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=register' \
  --data-urlencode "full_name=${test_name}" --data-urlencode "email=${test_email}" \
  --data-urlencode 'phone=071 555 0201' --data-urlencode 'password=StrongAdmin26' \
  --data-urlencode 'password_confirmation=StrongAdmin26' --data-urlencode 'privacy_consent=1' \
  "${base_url}/actions.php"
mysql_test "UPDATE users SET role='admin', auth_version=auth_version+1 WHERE email='${test_email}';" >/dev/null

login_html="$(curl -fsS -b "$cookie_jar" -c "$cookie_jar" "${base_url}/login.php")"
csrf="$(printf '%s' "$login_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=login' \
  --data-urlencode "email=${test_email}" --data-urlencode 'password=StrongAdmin26' "${base_url}/actions.php"
admin_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/index.php")"
printf '%s' "$admin_html" | grep -q 'Dashboard overview'
echo 'PASS database administrator login'

contact_html="$(curl -fsS -b "$cookie_jar" "${base_url}/contact.php")"
csrf="$(printf '%s' "$contact_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=contact' \
  --data-urlencode "name=${test_name}" --data-urlencode "email=${test_email}" \
  --data-urlencode 'phone=071 555 0201' --data-urlencode 'subject=General enquiry' \
  --data-urlencode "message=Admin inbox integration message ${stamp}." "${base_url}/actions.php"
message_id="$(mysql_test "SELECT id FROM contact_messages WHERE email='${test_email}' ORDER BY id DESC LIMIT 1;")"
messages_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/messages.php?search=${stamp}")"
printf '%s' "$messages_html" | grep -q "Admin inbox integration message ${stamp}"
csrf="$(printf '%s' "$messages_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_update_message' \
  --data-urlencode "id=${message_id}" --data-urlencode 'status=resolved' "${base_url}/actions.php"
[[ "$(mysql_test "SELECT status FROM contact_messages WHERE id=${message_id};")" == 'resolved' ]]
echo 'PASS paginated contact inbox and audited status management'

events_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/events.php")"
csrf="$(printf '%s' "$events_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_create_event' \
  --data-urlencode "title=${event_title}" --data-urlencode 'date=2099-08-10' \
  --data-urlencode 'time=10:00' --data-urlencode 'end_time=11:30' --data-urlencode 'location=Integration Hall' \
  --data-urlencode 'category=Community' --data-urlencode 'tone=teal' \
  --data-urlencode 'description=Integration event created by the automated administrator test.' \
  --data-urlencode 'directions=Use the accessible main entrance.' "${base_url}/actions.php"
event_id="$(mysql_test "SELECT id FROM events WHERE title='${event_title}' LIMIT 1;")"
[[ -n "$event_id" ]]
event_edit_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/events.php?edit=${event_id}")"
event_version="$(printf '%s' "$event_edit_html" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_update_event' --data-urlencode "id=${event_id}" --data-urlencode "version=${event_version}" \
  --data-urlencode "title=${updated_event_title}" --data-urlencode 'date=2099-08-11' \
  --data-urlencode 'time=10:30' --data-urlencode 'end_time=12:00' --data-urlencode 'location=Updated Integration Hall' \
  --data-urlencode 'category=Support' --data-urlencode 'tone=blue' \
  --data-urlencode 'description=Updated integration event from the automated administrator test.' \
  --data-urlencode 'directions=Use the side entrance.' "${base_url}/actions.php"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_update_event' --data-urlencode "id=${event_id}" --data-urlencode "version=${event_version}" \
  --data-urlencode 'title=Stale Database Overwrite' --data-urlencode 'date=2099-08-12' \
  --data-urlencode 'time=10:30' --data-urlencode 'end_time=12:00' --data-urlencode 'location=Stale Integration Hall' \
  --data-urlencode 'category=Support' --data-urlencode 'tone=blue' \
  --data-urlencode 'description=This stale database update must be rejected by row-version protection.' \
  --data-urlencode 'directions=This stale value must not persist.' "${base_url}/actions.php"
[[ "$(mysql_test "SELECT title FROM events WHERE id=${event_id};")" == "$updated_event_title" ]]
curl -fsS "${base_url}/events.php" | grep -q "$updated_event_title"
assert_api_field events "$event_id" title "$updated_event_title"
assert_api_field events "$event_id" location 'Updated Integration Hall'
echo 'PASS admin event edit reflected on website and Android API'
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_set_event_archived' \
  --data-urlencode "id=${event_id}" --data-urlencode 'archived=1' --data-urlencode 'reason=Integration archive test' "${base_url}/actions.php"
[[ "$(mysql_test "SELECT status FROM events WHERE id=${event_id};")" == 'cancelled' ]]
assert_api_absent events "$event_id"
if curl -fsS "${base_url}/events.php" | grep -q "$updated_event_title"; then exit 1; fi
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_set_event_archived' \
  --data-urlencode "id=${event_id}" --data-urlencode 'archived=0' --data-urlencode 'reason=Integration restore test' "${base_url}/actions.php"
assert_api_field events "$event_id" title "$updated_event_title"
echo 'PASS administrator event create, edit, stale-update rejection and archive'

discounts_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/discounts.php")"
csrf="$(printf '%s' "$discounts_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_create_discount' \
  --data-urlencode "store_name=${discount_store}" --data-urlencode 'category=Pharmacy' \
  --data-urlencode 'title=Senior savings' --data-urlencode 'deal=Integration discount offer' --data-urlencode 'eligibility=BKK members' \
  --data-urlencode 'claim_instructions=Show your membership card.' --data-urlencode 'tone=blue' \
  --data-urlencode 'valid_from=2020-08-01' --data-urlencode 'valid_until=2099-09-01' "${base_url}/actions.php"
discount_id="$(mysql_test "SELECT id FROM discounts WHERE store_name='${discount_store}' LIMIT 1;")"
[[ -n "$discount_id" ]]
assert_api_field discounts "$discount_id" title 'Senior savings'
assert_api_field discounts "$discount_id" details 'Integration discount offer'
discount_edit="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/discounts.php?edit=${discount_id}")"
discount_version="$(printf '%s' "$discount_edit" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_update_discount' \
  --data-urlencode "id=${discount_id}" --data-urlencode "version=${discount_version}" \
  --data-urlencode "store_name=${discount_store}" --data-urlencode 'category=Restaurant' \
  --data-urlencode 'title=Updated senior savings' --data-urlencode 'deal=Updated offer details without repeated title' \
  --data-urlencode 'eligibility=BKK members aged 60+' --data-urlencode 'claim_instructions=Show the updated membership card.' \
  --data-urlencode 'tone=red' --data-urlencode 'valid_from=2020-08-01' --data-urlencode 'valid_until=2099-09-01' "${base_url}/actions.php"
assert_api_field discounts "$discount_id" title 'Updated senior savings'
assert_api_field discounts "$discount_id" details 'Updated offer details without repeated title'
assert_api_field 'discounts?category=Restaurant' "$discount_id" claim_instructions 'Show the updated membership card.'
curl -fsS "${base_url}/discounts.php" | grep -q 'Updated senior savings: Updated offer details without repeated title'
echo 'PASS admin discount edits and category filter reflected on website and Android API'
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_set_discount_archived' \
  --data-urlencode "id=${discount_id}" --data-urlencode 'archived=1' --data-urlencode 'reason=Integration archive test' "${base_url}/actions.php"
[[ "$(mysql_test "SELECT is_active FROM discounts WHERE id=${discount_id};")" == '0' ]]
assert_api_absent discounts "$discount_id"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_set_discount_archived' \
  --data-urlencode "id=${discount_id}" --data-urlencode 'archived=0' --data-urlencode 'reason=Integration restore test' "${base_url}/actions.php"
assert_api_field discounts "$discount_id" title 'Updated senior savings'
mysql_test "UPDATE discounts SET valid_until='2020-08-02' WHERE id=${discount_id};" >/dev/null
assert_api_absent discounts "$discount_id"
if curl -fsS "${base_url}/discounts.php" | grep -q "$discount_store"; then exit 1; fi
echo 'PASS expired discount hidden from website and Android API'
echo 'PASS administrator discount create and archive'

services_html="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/services.php")"
csrf="$(printf '%s' "$services_html" | csrf_from)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_create_service' --data-urlencode 'type=support' \
  --data-urlencode "name=${service_name}" --data-urlencode 'address=12 Integration Road' \
  --data-urlencode 'phone=071 555 0202' --data-urlencode 'opening_hours=Weekdays, 08:00-17:00' \
  --data-urlencode 'directions=Ask at the community hall reception.' "${base_url}/actions.php"
service_id="$(mysql_test "SELECT id FROM local_services WHERE name='${service_name}' LIMIT 1;")"
[[ -n "$service_id" ]]
service_edit="$(curl -fsS -b "$cookie_jar" "${base_url}/admin/services.php?edit=${service_id}")"
service_version="$(printf '%s' "$service_edit" | sed -n 's/.*name="version" value="\([^"]*\)".*/\1/p' | head -1)"
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_update_service' \
  --data-urlencode "id=${service_id}" --data-urlencode "version=${service_version}" --data-urlencode 'type=pharmacy' \
  --data-urlencode "name=${service_name}" --data-urlencode 'address=24 Updated Integration Road' \
  --data-urlencode 'phone=072 555 0203' --data-urlencode 'opening_hours=Weekdays, 09:00-18:00' \
  --data-urlencode 'directions=Use the accessible updated entrance.' "${base_url}/actions.php"
assert_api_field local-services "$service_id" address '24 Updated Integration Road'
assert_api_field 'local-services?type=pharmacy' "$service_id" phone '072 555 0203'
curl -fsS "${base_url}/info.php" | grep -q '24 Updated Integration Road'
echo 'PASS admin service edits and type filter reflected on website and Android API'
curl -fsS -b "$cookie_jar" -c "$cookie_jar" -o /dev/null \
  --data-urlencode "csrf_token=${csrf}" --data-urlencode 'action=admin_set_service_archived' \
  --data-urlencode "id=${service_id}" --data-urlencode 'archived=1' --data-urlencode 'reason=Integration archive test' "${base_url}/actions.php"
[[ "$(mysql_test "SELECT is_active FROM local_services WHERE id=${service_id};")" == '0' ]]
assert_api_absent local-services "$service_id"
if curl -fsS "${base_url}/info.php" | grep -q "$service_name"; then exit 1; fi
echo 'PASS administrator local-service create and archive'

audit_count="$(mysql_test "SELECT COUNT(*) FROM admin_audit_log WHERE admin_user_id=(SELECT id FROM users WHERE email='${test_email}');")"
[[ "$audit_count" -ge 7 ]]
echo 'PASS database audit records were persisted'

mysql_test "UPDATE users SET role='member', auth_version=auth_version+1 WHERE email='${test_email}';" >/dev/null
revoked_location="$(curl -sS -b "$cookie_jar" -o /dev/null -w '%{redirect_url}' "${base_url}/admin/index.php")"
[[ "$revoked_location" == "${base_url}/login.php" ]]
echo 'PASS administrator role revocation invalidates the active session'
echo 'PASS persistent administrator journey complete'
