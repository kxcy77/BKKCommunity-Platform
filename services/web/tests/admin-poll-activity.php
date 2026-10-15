<?php
declare(strict_types=1);

// Isolated fixture: no production credentials, network access or database writes.
function database(): ?PDO { return null; }
function app_config(?string $key = null): mixed
{
    $config = [
        'app_env' => 'test', 'allow_demo_mode' => true,
        'admin_idle_timeout_seconds' => 300, 'admin_absolute_timeout_seconds' => 3600,
        'demo' => ['admin_email' => 'poll@example.test', 'admin_password' => 'fixture-only'],
    ];
    return $key === null ? $config : ($config[$key] ?? null);
}
require dirname(__DIR__) . '/app/auth.php';
$_SESSION = [
    'user' => ['email' => 'poll@example.test', 'role' => 'admin'],
    'session_started_at' => time() - 60,
    'last_activity_at' => time() - 30,
];
$originalActivity = $_SESSION['last_activity_at'];
require_admin(false);
if ($_SESSION['last_activity_at'] !== $originalActivity) {
    throw new RuntimeException('Background polling must not renew administrator idle time.');
}
require_admin();
if ($_SESSION['last_activity_at'] <= $originalActivity) {
    throw new RuntimeException('Explicit administrator interaction must record activity.');
}
echo "PASS background directory polling preserves idle expiry; explicit activity renews it\n";
