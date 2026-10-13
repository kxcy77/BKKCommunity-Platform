<?php
declare(strict_types=1);
require dirname(__DIR__) . '/app/push.php';
$checks = 0;
function check_push(bool $condition, string $label): void {
    global $checks;
    if (!$condition) throw new RuntimeException($label);
    ++$checks; echo "PASS $label\n";
}
$key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
openssl_pkey_export($key, $pem);
$credentials = ['type' => 'service_account', 'project_id' => 'bkk-test-project', 'client_email' => 'worker@bkk-test-project.iam.gserviceaccount.com','private_key' => $pem];
$jwt = push_jwt($credentials, 1000);
$parts = explode('.', $jwt);
$decode = static fn(string $s): string => base64_decode(strtr($s, '-_', '+/'));
check_push(count($parts) === 3, 'JWT has three parts');
check_push(openssl_verify("$parts[0].$parts[1]", $decode($parts[2]), openssl_pkey_get_details($key)['key'], OPENSSL_ALGO_SHA256) === 1, 'JWT signature verifies');
$claims = json_decode($decode($parts[1]), true);
check_push($claims['exp'] === 4600 && $claims['scope'] === 'https://www.googleapis.com/auth/firebase.messaging', 'OAuth is time limited and messaging scoped');
$job = ['title' => 'Upcoming event', 'message' => 'Open BKK', 'dedupe_key' => 'event:1:device:1','type' => 'event_reminder', 'event_id' => 1, 'discount_id' => null, 'user_id' => 9];
$payload = push_payload($job, 'fixture-token');
check_push(!isset($payload['message']['notification']), 'Data-only message honours Android session guards');
check_push($payload['message']['data']['event_id'] === '1' && $payload['message']['data']['recipient_user_id'] === '9', 'Message carries item and intended member IDs');
$mock = static function(string $url): array {
    if ($url === 'https://oauth2.googleapis.com/token') return ['status' => 200,'body' => ['access_token' => 'fixture-oauth-token', 'expires_in' => 3600]];
    return ['status' => 200, 'body' => ['name' => 'projects/bkk-test-project/messages/fixture']];
};
check_push(push_send($credentials, $job, 'fixture-token', $mock)['sent'], 'Provider acceptance is validated');
$unregistered = static fn(): array => ['status' => 404, 'body' => ['error' => ['details' => [['errorCode' => 'UNREGISTERED']]]]];
check_push(push_send($credentials, $job, 'fixture-token', $unregistered)['unregistered'], 'Unregistered token is recognised');
$invalid = static fn(): array => ['status' => 400, 'body' => ['error' => ['details' => [['errorCode' => 'INVALID_ARGUMENT']]]]];
check_push(!push_send($credentials, $job, 'fixture-token', $invalid)['unregistered'], 'Malformed message does not disable a valid device');
putenv('FCM_SERVICE_ACCOUNT_JSON='); putenv('GOOGLE_APPLICATION_CREDENTIALS=');
putenv('FCM_PROJECT_ID=bkk-test-project');
$rejected = false;
try { push_credentials(); } catch (RuntimeException) { $rejected = true; }
check_push($rejected, 'Missing credentials fail closed');
$serviceAccount = json_encode($credentials, JSON_THROW_ON_ERROR);
putenv('FCM_SERVICE_ACCOUNT_JSON=' . $serviceAccount);
putenv('FCM_PROJECT_ID=another-project');
$rejected = false;
try { push_credentials(); } catch (RuntimeException) { $rejected = true; }
check_push($rejected, 'A service account for the wrong Firebase project fails closed');
putenv('FCM_PROJECT_ID=bkk-test-project');
check_push(push_credentials()['project_id'] === 'bkk-test-project', 'Matching Firebase project is accepted');
echo "$checks transport assertions passed; no real notification sent.\n";
