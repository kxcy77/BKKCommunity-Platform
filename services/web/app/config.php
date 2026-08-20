<?php

declare(strict_types=1);

function load_environment(string $file): void
{
    if (!is_file($file)) {
        return;
    }

    foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }

        [$key, $value] = array_map('trim', explode('=', $line, 2));
        $value = trim($value, "\"'");
        if ($key !== '' && getenv($key) === false) {
            putenv("{$key}={$value}");
            $_ENV[$key] = $value;
        }
    }
}

function env_value(string $key, ?string $default = null): ?string
{
    $value = getenv($key);
    return $value === false ? $default : $value;
}

load_environment(dirname(__DIR__) . '/.env');

$appEnvironment = strtolower((string) env_value('APP_ENV', 'development'));
$allowDemoMode = $appEnvironment !== 'production'
    && filter_var(env_value('ALLOW_DEMO_MODE', 'false'), FILTER_VALIDATE_BOOL);

return [
    'app_env' => $appEnvironment,
    'app_url' => rtrim((string) env_value('APP_URL', 'http://localhost:8080'), '/'),
    'base_path' => rtrim((string) env_value('APP_BASE_PATH', ''), '/'),
    'session_name' => env_value('APP_SESSION_NAME', 'bkk_community_session'),
    'trust_proxy' => filter_var(env_value('APP_TRUST_PROXY', 'false'), FILTER_VALIDATE_BOOL),
    'reset_code_secret' => env_value('RESET_CODE_SECRET', ''),
    'allow_demo_mode' => $allowDemoMode,
    'admin_idle_timeout_seconds' => max(300, (int) env_value('ADMIN_IDLE_TIMEOUT_SECONDS', '1800')),
    'admin_absolute_timeout_seconds' => max(900, (int) env_value('ADMIN_ABSOLUTE_TIMEOUT_SECONDS', '28800')),
    'contact_retention_days' => max(30, (int) env_value('CONTACT_RETENTION_DAYS', '365')),
    'demo' => [
        'member_email' => strtolower((string) env_value('DEMO_MEMBER_EMAIL', '')),
        'member_password' => (string) env_value('DEMO_MEMBER_PASSWORD', ''),
        'member_name' => (string) env_value('DEMO_MEMBER_NAME', 'Demo Member'),
        'admin_email' => strtolower((string) env_value('DEMO_ADMIN_EMAIL', '')),
        'admin_password' => (string) env_value('DEMO_ADMIN_PASSWORD', ''),
        'admin_name' => (string) env_value('DEMO_ADMIN_NAME', 'Demo Administrator'),
    ],
    'mail' => [
        'resend_api_key' => env_value('RESEND_API_KEY', ''),
        'host' => env_value('SMTP_HOST', ''),
        'port' => env_value('SMTP_PORT', '587'),
        'username' => env_value('SMTP_USER', ''),
        'password' => env_value('SMTP_PASSWORD', ''),
        'encryption' => strtolower((string) env_value('SMTP_ENCRYPTION', 'tls')),
        'from_address' => env_value('MAIL_FROM', ''),
        'from_name' => env_value('MAIL_FROM_NAME', 'BKK Community'),
    ],
    'db' => [
        'host' => env_value('DB_HOST', ''),
        'port' => env_value('DB_PORT', '3306'),
        'name' => env_value('DB_NAME', 'bkk_community'),
        'user' => env_value('DB_USER', 'bkk_app'),
        'password' => env_value('DB_PASSWORD', ''),
    ],
];
