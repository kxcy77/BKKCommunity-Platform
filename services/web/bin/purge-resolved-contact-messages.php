#!/usr/bin/env php
<?php

declare(strict_types=1);

require dirname(__DIR__) . '/app/bootstrap.php';

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

$db = database();
if (!$db) {
    fwrite(STDERR, "A configured database is required.\n");
    exit(1);
}

$days = (int) app_config('contact_retention_days');
$cutoff = (new DateTimeImmutable('now', new DateTimeZone('UTC')))->modify("-{$days} days")->format('Y-m-d H:i:s');
$statement = $db->prepare('DELETE FROM contact_messages WHERE status = \'resolved\' AND submitted_at < ?');
$statement->execute([$cutoff]);
$deleted = $statement->rowCount();

if ($deleted > 0) {
    $audit = $db->prepare("INSERT INTO admin_audit_log (admin_user_id, action, entity_type, entity_id, reason) VALUES (NULL, 'retention_purge', 'contact_message', NULL, ?)");
    $audit->execute(["Automatically removed {$deleted} resolved message(s) older than {$days} days."]);
}

fwrite(STDOUT, "Removed {$deleted} resolved contact message(s).\n");
