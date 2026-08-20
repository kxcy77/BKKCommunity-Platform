<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin();
$pageTitle = 'Administrator audit history';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'audit';
$entries = admin_recent_audit_log(100);
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Accountability</p><h1>Audit history</h1></div></header>
        <section class="panel"><h2>Latest administrator changes</h2><p>Creates, edits, archives, restores and message-status changes are recorded here. The log is append-only in the application interface.</p>
        <?php if (!$entries): ?><div class="empty-state"><p>No administrator changes have been recorded yet.</p></div><?php else: ?>
            <p class="admin-table-hint">Showing the 100 most recent actions.</p><div class="table-wrap" role="region" aria-label="Administrator audit history" tabindex="0"><table class="data-table"><thead><tr><th>Date</th><th>Administrator</th><th>Action</th><th>Record</th><th>Reason</th></tr></thead><tbody>
            <?php foreach ($entries as $entry): ?><tr><td><?= h((new DateTimeImmutable($entry['created_at']))->format('d M Y, H:i')) ?></td><td><?= h($entry['admin_name']) ?></td><td><?= h(ucwords(str_replace('_', ' ', $entry['action']))) ?></td><td><?= h(ucwords(str_replace('_', ' ', $entry['entity_type']))) ?><?= $entry['entity_id'] ? ' #' . (int) $entry['entity_id'] : '' ?></td><td><?= h($entry['reason'] ?: 'Not required') ?></td></tr><?php endforeach; ?>
            </tbody></table></div>
        <?php endif; ?></section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
