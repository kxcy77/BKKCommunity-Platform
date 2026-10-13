<?php

declare(strict_types=1);

/** HTTPS-only FCM HTTP v1 transport. Service-account keys never reach the APK. */
function push_http(string $url, array $headers, string $body): array
{
    if (!function_exists('curl_init')) throw new RuntimeException('Push transport requires cURL.');
    $handle = curl_init($url);
    curl_setopt_array($handle, [
        CURLOPT_POST => true, CURLOPT_POSTFIELDS => $body,
        CURLOPT_HTTPHEADER => $headers, CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 5, CURLOPT_TIMEOUT => 20,
        CURLOPT_PROTOCOLS => CURLPROTO_HTTPS, CURLOPT_FOLLOWLOCATION => false,
    ]);
    $response = curl_exec($handle);
    $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
    if ($response === false) throw new RuntimeException('Push transport unavailable.');
    return ['status' => $status, 'body' => json_decode($response, true) ?: []];
}

function push_credentials(): array
{
    $expectedProject = trim((string) getenv('FCM_PROJECT_ID'));
    $raw = trim((string) getenv('FCM_SERVICE_ACCOUNT_JSON'));
    $file = trim((string) getenv('GOOGLE_APPLICATION_CREDENTIALS'));
    if ($raw === '' && $file !== '') $raw = (string) @file_get_contents($file);
    $credentials = json_decode($raw, true);
    if ($expectedProject === '' || !is_array($credentials) || ($credentials['type'] ?? '') !== 'service_account'
        || !preg_match('/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/', (string) ($credentials['project_id'] ?? ''))
        || !hash_equals($expectedProject, (string) $credentials['project_id'])
        || !filter_var($credentials['client_email'] ?? '', FILTER_VALIDATE_EMAIL)
        || empty($credentials['private_key'])
        || openssl_pkey_get_private((string) $credentials['private_key']) === false) {
        throw new RuntimeException('FCM service-account configuration is incomplete or belongs to a different project.');
    }
    return $credentials;
}

function push_jwt(array $credentials, int $now): string
{
    $encode = static fn (string $value): string => rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    $header = $encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR));
    $claims = $encode(json_encode([
        'iss' => $credentials['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
    ], JSON_THROW_ON_ERROR));
    if (!openssl_sign("$header.$claims", $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
        throw new RuntimeException('FCM signing configuration is invalid.');
    }
    return "$header.$claims." . $encode($signature);
}

function push_access_token(array $credentials, ?callable $http = null): string
{
    $http ??= 'push_http';
    static $cached = [];
    $key = hash('sha256', $credentials['client_email'] . $credentials['private_key']);
    if (($cached[$key]['expires'] ?? 0) > time() + 60) return $cached[$key]['token'];
    $result = $http('https://oauth2.googleapis.com/token', ['Content-Type: application/x-www-form-urlencoded'],
        http_build_query(['grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => push_jwt($credentials, time())]));
    $token = $result['body']['access_token'] ?? null;
    if ($result['status'] !== 200 || !is_string($token) || $token === '') {
        throw new RuntimeException('FCM authentication was not accepted.');
    }
    $cached[$key] = ['token' => $token, 'expires' => time() + min(3600, (int) ($result['body']['expires_in'] ?? 300))];
    return $token;
}

function push_payload(array $job, string $deviceToken): array
{
    $data = ['title' => $job['title'], 'body' => $job['message'], 'notice_id' => $job['dedupe_key'],
        'recipient_user_id' => (string) $job['user_id'],
        'type' => $job['type'] === 'event_reminder' ? 'event' : 'discount'];
    $data[$data['type'] === 'event' ? 'event_id' : 'discount_id'] =
        (string) ($data['type'] === 'event' ? $job['event_id'] : $job['discount_id']);
    // Data-only delivery is intentional: Android checks the local session and
    // preferences even when the app is in the background. Never include passwords or emails.
    return ['message' => ['token' => $deviceToken, 'data' => $data,
        'android' => ['priority' => 'high', 'ttl' => '3600s']]];
}

function push_send(array $credentials, array $job, string $deviceToken, ?callable $http = null): array
{
    $http ??= 'push_http';
    $token = push_access_token($credentials, $http);
    $response = $http('https://fcm.googleapis.com/v1/projects/' . $credentials['project_id'] . '/messages:send',
        ['Content-Type: application/json', 'Authorization: Bearer ' . $token],
        json_encode(push_payload($job, $deviceToken), JSON_THROW_ON_ERROR));
    if ($response['status'] === 200 && is_string($response['body']['name'] ?? null)) {
        return ['sent' => true, 'provider_id' => $response['body']['name'], 'unregistered' => false];
    }
    $unregistered = false;
    foreach ($response['body']['error']['details'] ?? [] as $detail) {
        if (($detail['errorCode'] ?? '') === 'UNREGISTERED') $unregistered = true;
    }
    return ['sent' => false, 'provider_id' => null, 'unregistered' => $unregistered];
}

function push_enqueue(PDO $db, string $alertsSince): void
{
    // A required cutover timestamp prevents a first run from broadcasting all seed offers.
    $discounts = $db->prepare("SELECT d.id, d.title, d.store_name, v.id AS device_id, v.user_id
        FROM discounts d CROSS JOIN devices v JOIN users u ON u.id = v.user_id
        JOIN auth_sessions s ON s.id = v.session_id AND s.user_id = v.user_id
        WHERE d.is_active = 1 AND d.is_demo = 0 AND d.created_at >= ? AND d.created_at >= v.created_at
        AND (d.valid_from IS NULL OR d.valid_from <= DATE(CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '+02:00')))
        AND (d.valid_until IS NULL OR d.valid_until >= DATE(CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '+02:00')))
        AND v.notifications_enabled = 1 AND u.deleted_at IS NULL
        AND s.revoked_at IS NULL AND s.expires_at > UTC_TIMESTAMP()
        AND u.notifications_enabled = 1 AND u.discount_alerts_enabled = 1
        AND NOT EXISTS (SELECT 1 FROM notification_log n WHERE n.dedupe_key =
            CONCAT('discount:', d.id, ':device:', v.id, ':user:', v.user_id))
        ORDER BY d.id, v.id LIMIT 500");
    $discounts->execute([$alertsSince]);
    $insert = $db->prepare("INSERT IGNORE INTO notification_log
        (user_id, device_id, event_id, discount_id, type, title, message, dedupe_key)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($discounts->fetchAll() as $row) {
        $insert->execute([$row['user_id'], $row['device_id'], null, $row['id'], 'discount_alert',
            'New BKK discount', mb_substr($row['store_name'] . ': ' . $row['title'], 0, 500),
            'discount:' . $row['id'] . ':device:' . $row['device_id'] . ':user:' . $row['user_id']]);
    }
    $events = $db->query("SELECT e.id, e.title, e.description, e.location, e.start_at,
        c.name AS category, v.id AS device_id, v.user_id FROM attendance a
        JOIN events e ON e.id = a.event_id JOIN event_categories c ON c.id = e.category_id
        JOIN users u ON u.id = a.user_id JOIN devices v ON v.user_id = u.id
        JOIN auth_sessions s ON s.id = v.session_id AND s.user_id = v.user_id
        WHERE a.status = 'attending' AND e.status = 'published'
        AND e.start_at > UTC_TIMESTAMP() AND e.start_at <= DATE_ADD(UTC_TIMESTAMP(), INTERVAL 24 HOUR)
        AND v.notifications_enabled = 1 AND u.deleted_at IS NULL
        AND s.revoked_at IS NULL AND s.expires_at > UTC_TIMESTAMP()
        AND u.notifications_enabled = 1 AND u.event_reminders_enabled = 1
        AND NOT EXISTS (SELECT 1 FROM notification_log n WHERE n.dedupe_key =
            CONCAT('event:', e.id, ':start:', e.start_at, ':device:', v.id, ':user:', v.user_id))
        ORDER BY e.id, v.id LIMIT 500")->fetchAll();
    foreach ($events as $row) {
        if (is_demonstration_event($row)) continue;
        $insert->execute([$row['user_id'], $row['device_id'], $row['id'], null, 'event_reminder',
            'Upcoming BKK event', mb_substr($row['title'] . ' at ' . $row['location'], 0, 500),
            'event:' . $row['id'] . ':start:' . $row['start_at'] . ':device:' . $row['device_id'] . ':user:' . $row['user_id']]);
    }
}

/** Recheck eligibility at delivery time: cancellation, archive and opt-out must win. */
function push_job_target(PDO $db, array $job): ?string
{
    $target = $db->prepare("SELECT v.fcm_token FROM devices v JOIN users u ON u.id = v.user_id
        JOIN auth_sessions s ON s.id = v.session_id AND s.user_id = v.user_id
        WHERE v.id = ? AND v.user_id = ? AND v.notifications_enabled = 1
        AND u.deleted_at IS NULL AND u.notifications_enabled = 1
        AND s.revoked_at IS NULL AND s.expires_at > UTC_TIMESTAMP()
        AND ((? = 'event_reminder' AND u.event_reminders_enabled = 1)
            OR (? = 'discount_alert' AND u.discount_alerts_enabled = 1))");
    $target->execute([$job['device_id'], $job['user_id'], $job['type'], $job['type']]);
    $token = $target->fetchColumn();
    if (!is_string($token)) return null;
    if ($job['type'] === 'event_reminder') {
        $event = $db->prepare("SELECT e.*, c.name AS category FROM events e
            JOIN event_categories c ON c.id = e.category_id JOIN attendance a ON a.event_id = e.id
            WHERE e.id = ? AND a.user_id = ? AND a.status = 'attending'
            AND e.status = 'published' AND e.start_at > UTC_TIMESTAMP()");
        $event->execute([$job['event_id'], $job['user_id']]);
        $row = $event->fetch();
        if (!$row || is_demonstration_event($row)
            || !str_contains($job['dedupe_key'], ':start:' . $row['start_at'] . ':')) return null;
    } else {
        $discount = $db->prepare("SELECT id FROM discounts WHERE id = ? AND is_active = 1 AND is_demo = 0
            AND (valid_from IS NULL OR valid_from <= DATE(CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '+02:00')))
            AND (valid_until IS NULL OR valid_until >= DATE(CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '+02:00')))");
        $discount->execute([$job['discount_id']]);
        if (!$discount->fetchColumn()) return null;
    }
    return $token;
}

function push_process(PDO $db, array $credentials, string $alertsSince, ?callable $sender = null): array
{
    $sender ??= 'push_send';
    $counts = ['accepted' => 0, 'skipped' => 0, 'retry' => 0];
    // Serialise workers without holding a row transaction open during HTTPS calls.
    if ((int) $db->query("SELECT GET_LOCK('bkk_push_worker', 0)")->fetchColumn() !== 1) return $counts;
    try {
        push_enqueue($db, $alertsSince);
        $jobs = $db->query("SELECT * FROM notification_log WHERE delivery_status = 'queued'
            AND attempt_count < 5 AND (next_attempt_at IS NULL OR next_attempt_at <= UTC_TIMESTAMP())
            ORDER BY id LIMIT 50")->fetchAll();
        foreach ($jobs as $job) {
            $target = push_job_target($db, $job);
            if ($target === null) {
                $db->prepare("UPDATE notification_log SET delivery_status = 'failed', last_error_code = 'ineligible' WHERE id = ?")
                    ->execute([$job['id']]);
                ++$counts['skipped'];
                continue;
            }
            try { $result = $sender($credentials, $job, $target); }
            catch (Throwable) { $result = ['sent' => false, 'unregistered' => false]; }
            if ($result['sent']) {
                $db->prepare("UPDATE notification_log SET delivery_status = 'sent', provider_message_id = ?,
                    sent_at = UTC_TIMESTAMP(), attempt_count = attempt_count + 1, last_error_code = NULL WHERE id = ?")
                    ->execute([$result['provider_id'], $job['id']]);
                ++$counts['accepted'];
            } else {
                $attempt = (int) $job['attempt_count'] + 1;
                $terminal = $result['unregistered'] || $attempt >= 5;
                $delay = min(3600, 60 * (2 ** ($attempt - 1)));
                $db->prepare("UPDATE notification_log SET delivery_status = ?, attempt_count = ?,
                    next_attempt_at = DATE_ADD(UTC_TIMESTAMP(), INTERVAL $delay SECOND), last_error_code = ? WHERE id = ?")
                    ->execute([$terminal ? 'failed' : 'queued', $attempt,
                        $result['unregistered'] ? 'unregistered' : 'provider_unavailable', $job['id']]);
                if ($result['unregistered']) {
                    $db->prepare('UPDATE devices SET notifications_enabled = 0 WHERE id = ? AND fcm_token = ?')
                        ->execute([$job['device_id'], $target]);
                }
                ++$counts['retry'];
            }
        }
    } finally { $db->query("SELECT RELEASE_LOCK('bkk_push_worker')"); }
    return $counts;
}
