<?php
declare(strict_types=1);

$testDatabase = getenv('BKK_TEST_DB_NAME') ?: '';
if (!str_starts_with($testDatabase, 'bkk_staff_') && $testDatabase !== 'bkk_ci_test') {
    throw new RuntimeException('Use an isolated, disposable staff test database.');
}
putenv('DB_NAME=' . $testDatabase);
if (getenv('DB_HOST') === false) putenv('DB_HOST=127.0.0.1');
if (getenv('DB_USER') === false) putenv('DB_USER=' . (getenv('BKK_TEST_DB_USER') ?: 'root'));
require dirname(__DIR__) . '/app/bootstrap.php';
$db = database();
if (!$db) throw new RuntimeException('Test database unavailable.');

if (($argv[1] ?? '') === 'child') {
    $query = $db->prepare('SELECT * FROM users WHERE id = ?');
    $query->execute([(int) $argv[2]]);
    $_SESSION['user'] = $query->fetch();
    $_SESSION['session_started_at'] = $_SESSION['last_activity_at'] = time();
    try {
        staff_set_access((int) $argv[2], 'member', 1, 'Concurrent owner handover test');
        echo "changed\n";
    } catch (DomainException $e) {
        echo "refused\n";
    }
    exit;
}

if ((int) $db->query("SELECT COUNT(*) FROM users WHERE role='admin' AND staff_level='owner' AND deleted_at IS NULL")->fetchColumn() !== 0) {
    throw new RuntimeException('Concurrency fixture requires an otherwise owner-free test database.');
}
$ids = [];
$children = [];
try {
    for ($i = 0; $i < 2; $i++) {
        $query = $db->prepare("INSERT INTO users(full_name,email,password_hash,role,staff_level) VALUES ('Concurrent owner fixture', ?, ?, 'admin','owner')");
        $query->execute(['owner-race-' . bin2hex(random_bytes(8)) . '@example.test', password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT)]);
        $ids[] = (int) $db->lastInsertId();
    }
    foreach ($ids as $id) {
        $process = proc_open([PHP_BINARY, __FILE__, 'child', (string) $id], [0 => ['pipe','r'], 1 => ['pipe','w'], 2 => ['pipe','w']], $pipes);
        if (!is_resource($process)) throw new RuntimeException('Could not start concurrent test process.');
        fclose($pipes[0]);
        $children[] = [$process, $pipes];
    }
    $results = [];
    foreach ($children as [$process, $pipes]) {
        $results[] = trim(stream_get_contents($pipes[1]));
        $errors = stream_get_contents($pipes[2]);
        fclose($pipes[1]); fclose($pipes[2]);
        if (proc_close($process) !== 0) throw new RuntimeException('Concurrent change failed: ' . $errors);
    }
    $owners = (int) $db->query("SELECT COUNT(*) FROM users WHERE role='admin' AND staff_level='owner' AND deleted_at IS NULL")->fetchColumn();
    sort($results);
    if ($owners !== 1 || $results !== ['changed', 'refused']) throw new RuntimeException('Concurrent changes removed the final owner.');
    echo "PASS simultaneous owner removals leave exactly one active owner\n";
} finally {
    foreach ($ids as $id) {
        $db->prepare('DELETE FROM admin_audit_log WHERE admin_user_id = ?')->execute([$id]);
        $db->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
    }
}
