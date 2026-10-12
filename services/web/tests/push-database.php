<?php
declare(strict_types=1);
if (!preg_match('/^bkk_(fix_|ci_)/', (string) getenv('DB_NAME'))) throw new RuntimeException('Disposable database required.');
$_SERVER['REQUEST_URI'] = '/api/v1';
require dirname(__DIR__) . '/app/bootstrap.php';
require dirname(__DIR__) . '/app/push.php';
$db = database(); $checks = 0;
$check = static function(bool $ok, string $label) use (&$checks): void {
    if (!$ok) throw new RuntimeException($label);
    ++$checks; echo "PASS $label\n";
};
$db->beginTransaction();
try {
    $db->exec("INSERT INTO users(full_name,email,password_hash) VALUES ('Push Fixture','push-fixture@example.test','unused')");
    $user = (int) $db->lastInsertId();
    $db->exec("INSERT INTO users(full_name,email,password_hash) VALUES ('Other Fixture','other-push-fixture@example.test','unused')");
    $other = (int) $db->lastInsertId();
    $db->prepare("INSERT INTO devices(user_id,fcm_token,created_at) VALUES (?,'push-fixture-token',DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 DAY))")->execute([$user]);
    $device = (int) $db->lastInsertId();
    $db->prepare("INSERT INTO auth_sessions(user_id,token_hash,expires_at) VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY))")->execute([$user, hash('sha256', 'push-fixture-session')]);
    $category = (int) $db->query('SELECT id FROM event_categories ORDER BY id LIMIT 1')->fetchColumn();
    $db->prepare("INSERT INTO events(category_id,title,description,start_at,end_at,location) VALUES (?,'Push fixture','Fixture',DATE_ADD(UTC_TIMESTAMP(),INTERVAL 23 HOUR),DATE_ADD(UTC_TIMESTAMP(),INTERVAL 24 HOUR),'Fixture hall')")->execute([$category]);
    $event = (int) $db->lastInsertId();
    $db->prepare("INSERT INTO attendance(user_id,event_id) VALUES (?,?)")->execute([$user,$event]);
    push_enqueue($db, '2099-01-01 00:00:00'); push_enqueue($db, '2099-01-01 00:00:00');
    $stmt = $db->prepare("SELECT * FROM notification_log WHERE device_id=? AND event_id=?");
    $stmt->execute([$device,$event]); $jobs=$stmt->fetchAll();
    $check(count($jobs) === 1, 'Repeated scans queue one reminder');
    $job=$jobs[0];
    $check(push_job_target($db,$job) === 'push-fixture-token', 'Active RSVP and session eligible');
    $db->prepare("UPDATE attendance SET status='cancelled' WHERE user_id=?")->execute([$user]);
    $check(push_job_target($db,$job) === null, 'Cancelled RSVP blocks delivery');
    $db->prepare("UPDATE attendance SET status='attending' WHERE user_id=?")->execute([$user]);
    $db->prepare('UPDATE users SET event_reminders_enabled=0 WHERE id=?')->execute([$user]);
    $check(push_job_target($db,$job) === null, 'Opt-out blocks delivery');
    $db->prepare('UPDATE users SET event_reminders_enabled=1 WHERE id=?')->execute([$user]);
    $db->prepare("UPDATE events SET status='cancelled' WHERE id=?")->execute([$event]);
    $check(push_job_target($db,$job) === null, 'Archived event blocks delivery');
    $db->prepare("UPDATE events SET status='published', start_at=DATE_ADD(start_at,INTERVAL 1 HOUR) WHERE id=?")->execute([$event]);
    $check(push_job_target($db,$job) === null, 'Rescheduled event blocks old reminder');
    $db->prepare("UPDATE events SET start_at=DATE_SUB(start_at,INTERVAL 1 HOUR) WHERE id=?")->execute([$event]);
    $db->prepare('UPDATE devices SET user_id=? WHERE id=?')->execute([$other,$device]);
    $check(push_job_target($db,$job) === null, 'Reassigned device cannot receive previous member reminder');
    $db->prepare('UPDATE devices SET user_id=? WHERE id=?')->execute([$user,$device]);
    $accepted = push_process($db, [], '2099-01-01 00:00:00', static fn(): array => ['sent'=>true,'provider_id'=>'fixture-accepted','unregistered'=>false]);
    $check($accepted['accepted'] === 1, 'Worker records provider acceptance');
    $again = push_process($db, [], '2099-01-01 00:00:00', static fn(): array => throw new RuntimeException('Duplicate'));
    $check($again['accepted'] === 0 && $again['retry'] === 0, 'Sent reminder is not retried');

    // A busy scan must advance past records already queued by an earlier scan.
    $discountCategory = (int) $db->query('SELECT id FROM discount_categories ORDER BY id LIMIT 1')->fetchColumn();
    $offer = $db->prepare("INSERT INTO discounts(category_id,store_name,title,details,eligibility,claim_instructions)
        VALUES (?,'Fixture shop',?,'Fixture details','Fixture members','Ask in store')");
    for ($i = 0; $i < 501; ++$i) $offer->execute([$discountCategory, 'Fixture offer ' . $i]);
    $cutover = (string) $db->query("SELECT DATE_FORMAT(DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 MINUTE), '%Y-%m-%d %H:%i:%s')")->fetchColumn();
    push_enqueue($db, $cutover);
    $queued = (int) $db->query("SELECT COUNT(*) FROM notification_log WHERE type='discount_alert' AND user_id=$user")->fetchColumn();
    $check($queued === 500, 'First batch queues at most 500 eligible offers');
    push_enqueue($db, $cutover);
    $queued = (int) $db->query("SELECT COUNT(*) FROM notification_log WHERE type='discount_alert' AND user_id=$user")->fetchColumn();
    $check($queued === 501, 'Second batch reaches the offer beyond the first 500');
} finally { if ($db->inTransaction()) $db->rollBack(); }
echo "$checks database assertions passed; fixtures rolled back.\n";
