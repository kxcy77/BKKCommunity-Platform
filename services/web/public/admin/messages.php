<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin();
$pageTitle = 'Contact messages';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'messages';
$page = max(1, (int) ($_GET['page'] ?? 1));
$search = mb_substr(trim((string) ($_GET['search'] ?? '')), 0, 100);
$status = trim((string) ($_GET['status'] ?? ''));
$result = admin_contact_messages($page, 25, $search, $status);
$messages = $result['items'];
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Community inbox</p><h1>Contact messages</h1></div><a class="button button-outline" href="<?= h(app_url('contact.php')) ?>">View contact page</a></header>
        <section class="panel">
            <div class="section-heading"><div><h2>Messages from the website</h2><p><?= (int) $result['total'] ?> matching message<?= (int) $result['total'] === 1 ? '' : 's' ?>.</p></div></div>
            <p class="privacy-note"><?= icon_svg('shield') ?><span>This page contains personal information. Access is restricted to authenticated administrators; do not copy it to personal devices.</span></p>
            <form class="admin-filter" method="get" action="<?= h(app_url('admin/messages.php')) ?>">
                <div class="field"><label for="search">Search sender or subject</label><input id="search" name="search" value="<?= h($search) ?>" maxlength="100"></div>
                <div class="field"><label for="status">Status</label><select id="status" name="status"><option value="">All statuses</option><?php foreach (['new' => 'New', 'read' => 'Read', 'resolved' => 'Resolved'] as $value => $label): ?><option value="<?= h($value) ?>" <?= $status === $value ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select></div>
                <button class="button button-small" type="submit">Apply filters</button><a href="<?= h(app_url('admin/messages.php')) ?>">Clear</a>
            </form>
            <?php if (!$messages): ?>
                <div class="empty-state"><p>No messages match these filters.</p></div>
            <?php else: ?>
                <p class="admin-table-hint">On a small screen, swipe the table sideways to see every column.</p>
                <div class="table-wrap" role="region" aria-label="Contact messages table" tabindex="0"><table class="data-table"><thead><tr><th>Received</th><th>Sender</th><th>Message</th><th>Status</th></tr></thead><tbody>
                <?php foreach ($messages as $message): ?>
                    <tr><td><?= h((new DateTimeImmutable($message['submitted_at']))->format('d M Y, H:i')) ?></td><td><strong><?= h($message['name']) ?></strong><br><a href="mailto:<?= h($message['email']) ?>"><?= h($message['email']) ?></a><?php if (!empty($message['phone'])): ?><br><a href="tel:<?= h(preg_replace('/[^0-9+]/', '', $message['phone'])) ?>"><?= h($message['phone']) ?></a><?php endif; ?></td><td><strong><?= h($message['subject']) ?></strong><details><summary>Read message</summary><p class="message-copy"><?= nl2br(h($message['message'])) ?></p></details></td><td><form action="<?= h(app_url('actions.php')) ?>" method="post"><input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_update_message"><input type="hidden" name="id" value="<?= (int) $message['id'] ?>"><label class="visually-hidden" for="status-<?= (int) $message['id'] ?>">Status for <?= h($message['subject']) ?></label><select id="status-<?= (int) $message['id'] ?>" name="status"><?php foreach (['new' => 'New', 'read' => 'Read', 'resolved' => 'Resolved'] as $value => $label): ?><option value="<?= h($value) ?>" <?= $message['status'] === $value ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select><button class="button button-small" type="submit">Save status</button></form></td></tr>
                <?php endforeach; ?>
                </tbody></table></div>
                <?php if ($result['pages'] > 1): ?><nav class="pagination" aria-label="Message pages"><?php for ($number = 1; $number <= $result['pages']; $number++): $query = http_build_query(['page' => $number, 'search' => $search, 'status' => $status]); ?><a href="<?= h(app_url('admin/messages.php?' . $query)) ?>" <?= $number === $result['page'] ? 'aria-current="page"' : '' ?>><?= $number ?></a><?php endfor; ?></nav><?php endif; ?>
            <?php endif; ?>
        </section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
