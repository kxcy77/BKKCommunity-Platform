<?php

declare(strict_types=1);

function current_user(): ?array
{
    return isset($_SESSION['user']) && is_array($_SESSION['user']) ? $_SESSION['user'] : null;
}

function is_admin(): bool
{
    return (current_user()['role'] ?? null) === 'admin';
}

function demo_accounts(): array
{
    $config = app_config();
    if (empty($config['allow_demo_mode']) || ($config['app_env'] ?? '') === 'production') {
        return [];
    }

    $demo = $config['demo'] ?? [];
    $accounts = [];
    foreach (['member', 'admin'] as $role) {
        $email = strtolower(trim((string) ($demo[$role . '_email'] ?? '')));
        $password = (string) ($demo[$role . '_password'] ?? '');
        if ($email === '' || $password === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            continue;
        }
        $accounts[$email] = [
            'full_name' => (string) ($demo[$role . '_name'] ?? ucfirst($role)),
            'email' => $email,
            'phone' => '',
            'role' => $role,
            'auth_version' => 1,
            'password' => $password,
            'event_reminders' => true,
            'discount_alerts' => true,
        ];
    }
    return $accounts;
}

function establish_authenticated_session(array $user): void
{
    session_regenerate_id(true);
    $_SESSION['user'] = $user;
    $_SESSION['session_started_at'] = time();
    $_SESSION['last_activity_at'] = time();
}

function administrator_session_expired(int $now, int $startedAt, int $lastActivityAt, int $idleLimit, int $absoluteLimit): bool
{
    return ($now - $lastActivityAt) > $idleLimit || ($now - $startedAt) > $absoluteLimit;
}

function require_login(): void
{
    $user = current_user();
    if (!$user) {
        flash('info', 'Please log in to use that feature.');
        $_SESSION['return_after_login'] = ltrim(request_path(), '/');
        redirect_to('login.php');
    }

    $db = database();
    if ($db && !empty($user['id'])) {
        $statement = $db->prepare('SELECT id, full_name, email, phone, role, auth_version,
            event_reminders_enabled AS event_reminders,
            discount_alerts_enabled AS discount_alerts
            FROM users WHERE id = ? AND deleted_at IS NULL LIMIT 1');
        $statement->execute([(int) $user['id']]);
        $fresh = $statement->fetch();
        if (!$fresh || (int) ($fresh['auth_version'] ?? 0) !== (int) ($user['auth_version'] ?? 0)) {
            logout_user();
            flash('info', 'Your account security changed. Please log in again.');
            redirect_to('login.php');
        }
        $_SESSION['user'] = $fresh;
    }
}

function require_admin(): void
{
    $user = current_user();
    if (!$user) {
        $_SESSION['return_after_login'] = ltrim(request_path(), '/');
        flash('error', 'Administrator access is required.');
        redirect_to('login.php');
    }

    if (($user['role'] ?? null) !== 'admin') {
        flash('error', 'Your account does not have administrator access.');
        redirect_to('profile.php');
    }

    $now = time();
    $_SESSION['session_started_at'] ??= $now;
    $_SESSION['last_activity_at'] ??= $now;
    $startedAt = (int) ($_SESSION['session_started_at'] ?? $now);
    $lastActivityAt = (int) ($_SESSION['last_activity_at'] ?? $now);
    $idleLimit = (int) app_config('admin_idle_timeout_seconds');
    $absoluteLimit = (int) app_config('admin_absolute_timeout_seconds');
    if (administrator_session_expired($now, $startedAt, $lastActivityAt, $idleLimit, $absoluteLimit)) {
        logout_user();
        flash('info', 'Your administrator session expired. Please log in again.');
        redirect_to('login.php');
    }

    $db = database();
    if ($db && !empty($user['id'])) {
        $statement = $db->prepare('SELECT id, full_name, email, phone, role, auth_version,
            event_reminders_enabled AS event_reminders,
            discount_alerts_enabled AS discount_alerts
            FROM users WHERE id = ? AND deleted_at IS NULL LIMIT 1');
        $statement->execute([(int) $user['id']]);
        $fresh = $statement->fetch();
        if (!$fresh || ($fresh['role'] ?? null) !== 'admin'
            || (int) ($fresh['auth_version'] ?? 0) !== (int) ($user['auth_version'] ?? 0)) {
            logout_user();
            flash('error', 'Your administrator access changed. Please log in again.');
            redirect_to('login.php');
        }
        $_SESSION['user'] = $fresh;
    } elseif (!$db) {
        $account = demo_accounts()[strtolower((string) ($user['email'] ?? ''))] ?? null;
        if (!$account || ($account['role'] ?? null) !== 'admin') {
            logout_user();
            flash('error', 'Your administrator access is no longer available.');
            redirect_to('login.php');
        }
    }

    $_SESSION['last_activity_at'] = $now;
}

function attempt_login(string $email, string $password): bool
{
    $email = strtolower(trim($email));
    $db = database();

    if ($db) {
        $statement = $db->prepare('SELECT id, full_name, email, phone, role, auth_version, password_hash,
            event_reminders_enabled AS event_reminders,
            discount_alerts_enabled AS discount_alerts
            FROM users WHERE email = ? AND deleted_at IS NULL LIMIT 1');
        $statement->execute([$email]);
        $user = $statement->fetch();
        if (!$user || !password_verify($password, $user['password_hash'])) {
            return false;
        }
        unset($user['password_hash']);
        establish_authenticated_session($user);
        return true;
    }

    $registered = $_SESSION['demo_registered_users'][$email] ?? null;
    if (is_array($registered) && password_verify($password, $registered['password_hash'])) {
        unset($registered['password_hash']);
        $registered['auth_version'] = (int) ($registered['auth_version'] ?? 1);
        establish_authenticated_session($registered);
        return true;
    }

    $user = demo_accounts()[$email] ?? null;
    if (!$user || !hash_equals($user['password'], $password)) {
        return false;
    }
    unset($user['password']);
    establish_authenticated_session($user);
    return true;
}

function register_user(array $input): array
{
    $email = strtolower(trim($input['email']));
    $db = database();

    if ($db) {
        $check = $db->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $check->execute([$email]);
        if ($check->fetchColumn()) {
            return [false, 'An account with that email address already exists.'];
        }
        try {
            $statement = $db->prepare('INSERT INTO users (full_name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, \'member\')');
            $statement->execute([$input['full_name'], $email, $input['phone'], password_hash($input['password'], PASSWORD_DEFAULT)]);
        } catch (PDOException $exception) {
            if ($exception->getCode() === '23000') {
                return [false, 'An account with that email address already exists.'];
            }
            throw $exception;
        }
        return [true, 'Your account was created. You can now log in.'];
    }

    if (isset($_SESSION['demo_registered_users'][$email]) || isset(demo_accounts()[$email])) {
        return [false, 'An account with that email address already exists in this demo session.'];
    }
    $_SESSION['demo_registered_users'][$email] = [
        'full_name' => $input['full_name'],
        'email' => $email,
        'phone' => $input['phone'],
        'role' => 'member',
        'auth_version' => 1,
        'password_hash' => password_hash($input['password'], PASSWORD_DEFAULT),
    ];
    return [true, 'Your demo account was created for this browser session. You can now log in.'];
}

function logout_user(): void
{
    unset($_SESSION['user'], $_SESSION['rsvps'], $_SESSION['session_started_at'], $_SESSION['last_activity_at']);
    session_regenerate_id(true);
}
