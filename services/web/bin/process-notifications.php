<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
$_SERVER['REQUEST_URI'] = '/api/v1';
require dirname(__DIR__) . '/app/bootstrap.php';
require dirname(__DIR__) . '/app/push.php';
if (!filter_var(getenv('FCM_ENABLED') ?: 'false', FILTER_VALIDATE_BOOL)) {
    fwrite(STDOUT, "Cloud notifications are disabled.\n"); exit(0);
}
$since = (string) getenv('FCM_ALERTS_SINCE');
if (!preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/', $since)) {
    fwrite(STDERR, "Set FCM_ALERTS_SINCE to the UTC activation timestamp.\n"); exit(1);
}
try { $credentials = push_credentials(); }
catch (Throwable) { fwrite(STDERR, "FCM credentials are missing or invalid.\n"); exit(1); }
if (in_array('--check-config', $argv, true)) {
    fwrite(STDOUT, "Cloud notification configuration is present.\n"); exit(0);
}
$loop = in_array('--loop', $argv, true);
do {
    try {
        $db = database();
        if (!$db) throw new RuntimeException('Database unavailable.');
        $counts = push_process($db, $credentials, $since);
        fwrite(STDOUT, json_encode($counts, JSON_THROW_ON_ERROR) . PHP_EOL);
    } catch (Throwable) {
        // Never log provider responses, recipient addresses, keys or device tokens.
        fwrite(STDERR, "Notification worker failed; retrying on the next run.\n");
        if (!$loop) exit(1);
    }
    if ($loop) sleep(60);
} while ($loop);
