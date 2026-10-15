#!/usr/bin/env bash
set -euo pipefail
trap 'echo "FAIL staff permissions at line $LINENO" >&2' ERR
base_url="${BKK_BASE_URL:-http://127.0.0.1:8116}"
db_name="${BKK_TEST_DB_NAME:?Use a disposable test database}"
db_user="${BKK_TEST_DB_USER:-root}"
[[ "$db_name" == bkk_staff_* || "$db_name" == bkk_ci_test ]] || { echo 'Refusing non-test database'; exit 1; }
stamp="$(date +%s)"
prefix="staff.${stamp}"
test_dir="$(mktemp -d /tmp/bkk-staff-tests.XXXXXX)"
password='StaffFixtureOnly26'
sql() { mysql -N -B -u "$db_user" -D "$db_name" -e "$1"; }
cleanup() {
  sql "DELETE FROM staff_invitations WHERE email LIKE '${prefix}.%@example.test'; DELETE FROM contact_messages WHERE email LIKE '${prefix}.%@example.test'; DELETE FROM events WHERE title='${prefix} event'; DELETE FROM admin_audit_log WHERE admin_user_id IN (SELECT id FROM users WHERE email LIKE '${prefix}.%@example.test'); DELETE FROM users WHERE email LIKE '${prefix}.%@example.test';" >/dev/null 2>&1 || true
  find "$test_dir" -type f -delete
  rmdir "$test_dir"
}
trap cleanup EXIT
hash="$(php -r 'echo password_hash("StaffFixtureOnly26", PASSWORD_DEFAULT);')"
for role in owner editor support viewer member other; do
  account_role=admin; level="$role"
  if [[ "$role" == member || "$role" == other ]]; then account_role=member; level=viewer; fi
  sql "INSERT INTO users(full_name,email,password_hash,role,staff_level) VALUES ('Staff fixture $role','${prefix}.${role}@example.test','$hash','$account_role','$level');"
done
csrf_from() { sed -n 's/.*name="csrf_token" value="\([^"]*\)".*/\1/p' | sed -n '1p'; }
login() {
  local role="$1" html csrf
  html="$(curl -fsS -c "$test_dir/$role.cookies" "$base_url/login.php")"
  csrf="$(printf '%s' "$html" | csrf_from)"
  curl -fsS -o /dev/null -b "$test_dir/$role.cookies" -c "$test_dir/$role.cookies" \
    --data-urlencode "csrf_token=$csrf" --data-urlencode 'action=login' \
    --data-urlencode "email=${prefix}.${role}@example.test" --data-urlencode "password=$password" "$base_url/actions.php"
}
get() { curl -sS -b "$test_dir/$1.cookies" -o "$test_dir/body" -w '%{http_code}' "$base_url/$2"; }
post() {
  local role="$1" action="$2"; shift 2
  local html csrf
  html="$(curl -fsS -b "$test_dir/$role.cookies" "$base_url/profile.php")"
  csrf="$(printf '%s' "$html" | csrf_from)"
  curl -sS -b "$test_dir/$role.cookies" -c "$test_dir/$role.cookies" -o "$test_dir/body" -w '%{http_code}' \
    --data-urlencode "csrf_token=$csrf" --data-urlencode "action=$action" "$@" "$base_url/actions.php"
}
for role in owner editor support viewer member other; do login "$role"; done
for role in owner editor support viewer; do
  for page in index events discounts services reports users staff messages attendance audit; do
    expected=403
    if [[ "$page" == index || "$role" == owner ]]; then expected=200; fi
    if [[ "$role" == editor && ( "$page" == events || "$page" == discounts || "$page" == services || "$page" == reports ) ]]; then expected=200; fi
    if [[ "$role" == support && ( "$page" == messages || "$page" == attendance ) ]]; then expected=200; fi
    if [[ "$role" == viewer && "$page" == reports ]]; then expected=200; fi
    actual="$(get "$role" "admin/$page.php")"
    [[ "$actual" == "$expected" ]] || { echo "FAIL $role $page got $actual wanted $expected"; exit 1; }
  done
done
[[ "$(get member admin/staff.php)" == 302 ]]
[[ "$(curl -sS -o /dev/null -w '%{http_code}' "$base_url/admin/staff.php")" == 302 ]]
echo 'PASS all four staff levels, member/guest restrictions and direct URL access matrix'
for role in editor support viewer; do
  [[ "$(post "$role" admin_invite_staff --data-urlencode "email=${prefix}.other@example.test" --data-urlencode 'staff_level=owner')" == 403 ]]
done
for role in support viewer; do
  for action in admin_create_event admin_update_event admin_set_event_archived admin_create_discount admin_update_discount admin_set_discount_archived admin_create_service admin_update_service admin_set_service_archived; do
    [[ "$(post "$role" "$action")" == 403 ]]
  done
done
[[ "$(post editor admin_update_message)" == 403 ]]
[[ "$(post viewer admin_update_message)" == 403 ]]
echo 'PASS forged content, inbox and privilege-escalation POSTs denied'
[[ "$(post editor admin_create_event --data-urlencode "title=${prefix} event" --data-urlencode 'date=2099-08-10' --data-urlencode 'time=10:00' --data-urlencode 'end_time=11:00' --data-urlencode 'location=Fixture hall' --data-urlencode 'category=Exercise' --data-urlencode 'tone=blue' --data-urlencode 'description=Staff editor integration verification event')" == 302 ]]
[[ "$(sql "SELECT COUNT(*) FROM events WHERE title='${prefix} event';")" == 1 ]]
sql "INSERT INTO contact_messages(name,email,subject,message) VALUES ('Fixture member','${prefix}.member@example.test','Fixture enquiry','Support permission verification');"
message_id="$(sql "SELECT id FROM contact_messages WHERE email='${prefix}.member@example.test' ORDER BY id DESC LIMIT 1;")"
[[ "$(post support admin_update_message --data-urlencode "id=$message_id" --data-urlencode 'status=resolved')" == 302 ]]
[[ "$(sql "SELECT status FROM contact_messages WHERE id=$message_id;")" == resolved ]]
echo 'PASS editor can create content and Support can resolve contact messages'
[[ "$(get viewer admin/index.php)" == 200 ]]
! grep -F 'Registered users' "$test_dir/body" >/dev/null
! grep -F 'Add event' "$test_dir/body" >/dev/null
[[ "$(get viewer admin/reports.php)" == 200 ]]
! grep -F 'admin_create_' "$test_dir/body" >/dev/null
echo 'PASS read-only interface contains no private directory or write controls'
[[ "$(post owner admin_invite_staff --data-urlencode "email=${prefix}.member@example.test" --data-urlencode 'staff_level=editor' --data-urlencode 'current_password=wrong' --data-urlencode 'reason=Fixture invitation')" == 302 ]]
[[ "$(sql "SELECT COUNT(*) FROM staff_invitations WHERE email='${prefix}.member@example.test';")" == 0 ]]
[[ "$(post owner admin_invite_staff --data-urlencode "email=${prefix}.member@example.test" --data-urlencode 'staff_level=editor' --data-urlencode "current_password=$password" --data-urlencode 'reason=Fixture invitation')" == 302 ]]
[[ "$(get owner admin/staff.php)" == 200 ]]
code="$(sed -n 's/.*id="new-invitation-code" readonly value="\([^"]*\)".*/\1/p' "$test_dir/body")"
[[ ${#code} == 64 ]]
[[ "$(sql "SELECT role FROM users WHERE email='${prefix}.member@example.test';")" == member ]]
stored="$(sql "SELECT token_hash FROM staff_invitations WHERE email='${prefix}.member@example.test' AND revoked_at IS NULL;")"
[[ "$code" != "$stored" && ${#stored} == 64 ]]
[[ "$(post other accept_staff_invitation --data-urlencode "invitation_code=$code")" == 302 ]]
[[ "$(sql "SELECT role FROM users WHERE email='${prefix}.other@example.test';")" == member ]]
[[ "$(post member accept_staff_invitation --data-urlencode "invitation_code=$code")" == 302 ]]
[[ "$(sql "SELECT staff_level FROM users WHERE email='${prefix}.member@example.test';")" == editor ]]
login member
[[ "$(get member admin/events.php)" == 200 ]]
[[ "$(post other accept_staff_invitation --data-urlencode "invitation_code=$code")" == 302 ]]
[[ "$(sql "SELECT role FROM users WHERE email='${prefix}.other@example.test';")" == member ]]
echo 'PASS password confirmation, no grant before acceptance, hashed codes, email binding and single use'
target_id="$(sql "SELECT id FROM users WHERE email='${prefix}.member@example.test';")"
api_token="$(curl -fsS -H 'Content-Type: application/json' -d "{\"email\":\"${prefix}.member@example.test\",\"password\":\"$password\"}" "$base_url/api/v1/auth/login" | php -r '$d=json_decode(stream_get_contents(STDIN),true);echo $d["data"]["token"]??"";')"
[[ -n "$api_token" ]]
[[ "$(curl -sS -X DELETE -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $api_token" "$base_url/api/v1/me")" == 409 ]]
version="$(sql "SELECT auth_version FROM users WHERE id=$target_id;")"
[[ "$(post owner admin_change_staff --data-urlencode "id=$target_id" --data-urlencode "version=$version" --data-urlencode 'staff_level=member' --data-urlencode "current_password=$password" --data-urlencode 'reason=Fixture revocation')" == 302 ]]
[[ "$(get member admin/events.php)" == 302 ]]
[[ "$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $api_token" "$base_url/api/v1/me")" == 401 ]]
[[ "$(sql "SELECT role FROM users WHERE id=$target_id;")" == member ]]
echo 'PASS staff removal preserves the member account and invalidates web and API sessions'
[[ "$(post owner admin_invite_staff --data-urlencode "email=${prefix}.other@example.test" --data-urlencode 'staff_level=support' --data-urlencode "current_password=$password" --data-urlencode 'reason=Expiry verification')" == 302 ]]
[[ "$(get owner admin/staff.php)" == 200 ]]
expired_code="$(sed -n 's/.*id="new-invitation-code" readonly value="\([^"]*\)".*/\1/p' "$test_dir/body")"
sql "UPDATE staff_invitations SET expires_at=DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 MINUTE) WHERE email='${prefix}.other@example.test';"
[[ "$(post other accept_staff_invitation --data-urlencode "invitation_code=$expired_code")" == 302 ]]
[[ "$(sql "SELECT role FROM users WHERE email='${prefix}.other@example.test';")" == member ]]
[[ "$(post owner admin_invite_staff --data-urlencode "email=${prefix}.other@example.test" --data-urlencode 'staff_level=owner' --data-urlencode "current_password=$password" --data-urlencode 'reason=Cancellation verification')" == 302 ]]
invite_id="$(sql "SELECT MAX(id) FROM staff_invitations WHERE email='${prefix}.other@example.test';")"
[[ "$(post owner admin_revoke_invitation --data-urlencode "id=$invite_id" --data-urlencode "current_password=$password" --data-urlencode 'reason=Cancel fixture invitation')" == 302 ]]
[[ "$(sql "SELECT revoked_at IS NOT NULL FROM staff_invitations WHERE id=$invite_id;")" == 1 ]]
echo 'PASS expired invitations rejected and pending invitations can be cancelled'
owner_id="$(sql "SELECT id FROM users WHERE email='${prefix}.owner@example.test';")"
owner_count="$(sql "SELECT COUNT(*) FROM users WHERE role='admin' AND staff_level='owner' AND deleted_at IS NULL;")"
if [[ "$owner_count" == 1 ]]; then
  owner_version="$(sql "SELECT auth_version FROM users WHERE id=$owner_id;")"
  [[ "$(post owner admin_change_staff --data-urlencode "id=$owner_id" --data-urlencode "version=$owner_version" --data-urlencode 'staff_level=member' --data-urlencode "current_password=$password" --data-urlencode 'reason=Last owner protection')" == 302 ]]
  [[ "$(sql "SELECT role FROM users WHERE id=$owner_id;")" == admin ]]
  echo 'PASS last-owner removal refused'
else
  echo 'SKIP last-owner fixture requires an otherwise owner-free disposable database'
fi
[[ "$(post owner delete_account --data-urlencode "confirm_email=${prefix}.owner@example.test")" == 302 ]]
[[ "$(sql "SELECT COUNT(*) FROM users WHERE id=$owner_id;")" == 1 ]]
audit_count="$(sql "SELECT COUNT(*) FROM admin_audit_log WHERE admin_user_id=$owner_id AND action LIKE 'staff_%';")"
[[ "$audit_count" -ge 5 ]]
echo 'PASS staff account deletion blocked and access changes recorded in audit history'
[[ "$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d "{\"full_name\":\"Injected staff fields\",\"email\":\"${prefix}.injected@example.test\",\"password\":\"$password\",\"role\":\"admin\",\"staff_level\":\"owner\"}" "$base_url/api/v1/auth/register")" == 201 ]]
[[ "$(sql "SELECT CONCAT(role,':',staff_level) FROM users WHERE email='${prefix}.injected@example.test';")" == member:viewer ]]
echo 'PASS public registration cannot inject staff or owner permissions'
