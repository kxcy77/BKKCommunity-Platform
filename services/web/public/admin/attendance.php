<?php
declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_permission('attendance');
header('Cache-Control: no-store, private');
$pageTitle = 'Attendance enquiries'; $bodyClass = 'admin-page'; $activeNav = 'admin'; $adminPage = 'attendance';
$search = is_string($_GET['search'] ?? null) ? mb_substr(trim($_GET['search']), 0, 100) : '';
$page = max(1, filter_var($_GET['page'] ?? 1, FILTER_VALIDATE_INT) ?: 1);
$db = database(); $rows = []; $total = 0;
if ($db) {
    $where = "u.deleted_at IS NULL AND (u.full_name LIKE ? OR u.email LIKE ? OR e.title LIKE ?)";
    $args = array_fill(0, 3, '%' . addcslashes($search, '%_\\') . '%');
    $query = $db->prepare("SELECT COUNT(*) FROM attendance a JOIN users u ON u.id=a.user_id JOIN events e ON e.id=a.event_id WHERE $where");
    $query->execute($args); $total = (int) $query->fetchColumn();
    $pages = max(1, (int) ceil($total / 25)); $page = min($page, $pages);
    $query = $db->prepare("SELECT u.full_name,u.email,u.phone,e.title,e.start_at,a.status FROM attendance a JOIN users u ON u.id=a.user_id JOIN events e ON e.id=a.event_id WHERE $where ORDER BY e.start_at DESC,a.id DESC LIMIT 25 OFFSET " . (($page - 1) * 25));
    $query->execute($args); $rows = $query->fetchAll();
}
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell"><?php require __DIR__ . '/_sidebar.php'; ?><div class="admin-content"><header class="admin-header"><h1>Attendance enquiries</h1></header>
<section class="panel"><p>Read-only RSVP records for helping members. <?= $total ?> matches. Do not copy personal information to personal devices.</p>
<form method="get"><div class="field"><label for="search">Search member name, email or event</label><input id="search" name="search" maxlength="100" value="<?= h($search) ?>"></div><button class="button" type="submit">Search attendance</button></form>
<?php if (!$rows): ?><p>No attendance records match.</p><?php else: ?><div class="table-wrap" role="region" aria-label="Attendance records" tabindex="0"><table class="data-table"><thead><tr><th>Member</th><th>Contact</th><th>Event</th><th>Status</th></tr></thead><tbody><?php foreach ($rows as $row): ?><tr><td><?= h($row['full_name']) ?></td><td><?= h($row['email']) ?><br><?= h($row['phone'] ?: 'Not provided') ?></td><td><?= h($row['title']) ?><br><?= h((new DateTimeImmutable($row['start_at'], new DateTimeZone('UTC')))->setTimezone(new DateTimeZone('Africa/Johannesburg'))->format('d M Y, H:i')) ?></td><td><?= h(ucfirst($row['status'])) ?></td></tr><?php endforeach; ?></tbody></table></div>
<nav aria-label="Attendance pages"><?php if ($page > 1): ?><a href="?<?= h(http_build_query(['page' => $page - 1, 'search' => $search])) ?>">Previous</a><?php endif; ?> <span>Page <?= $page ?> of <?= $pages ?></span> <?php if ($page < $pages): ?><a href="?<?= h(http_build_query(['page' => $page + 1, 'search' => $search])) ?>">Next</a><?php endif; ?></nav><?php endif; ?></section>
</div></div><?php require dirname(__DIR__) . '/partials/footer.php'; ?>
