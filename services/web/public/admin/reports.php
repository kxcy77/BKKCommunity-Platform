<?php
declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_permission('content.read');
header('Cache-Control: no-store, private');
$pageTitle = 'Content overview'; $bodyClass = 'admin-page'; $activeNav = 'admin'; $adminPage = 'reports';
$events = all_events(); $discounts = all_discounts(); $services = all_services();
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell"><?php require __DIR__ . '/_sidebar.php'; ?><div class="admin-content">
<header class="admin-header"><div><p class="eyebrow">Read-only report</p><h1>Content overview</h1></div></header>
<p>This report shows publicly available content. It contains no member contact details and cannot change records.</p>
<section class="panel"><h2>Upcoming events (<?= count($events) ?>)</h2><?php if (!$events): ?><p>No upcoming events.</p><?php endif; ?><?php foreach ($events as $event): ?><p><strong><?= h($event['title']) ?></strong> — <?= h($event['date']) ?>, <?= h($event['time']) ?>, <?= h($event['location']) ?></p><?php endforeach; ?></section>
<section class="panel"><h2>Active discounts (<?= count($discounts) ?>)</h2><?php if (!$discounts): ?><p>No active discounts.</p><?php endif; ?><?php foreach ($discounts as $discount): ?><p><strong><?= h($discount['store_name']) ?></strong> — <?= h($discount['deal']) ?></p><?php endforeach; ?></section>
<section class="panel"><h2>Local services (<?= count($services) ?>)</h2><?php if (!$services): ?><p>No active services.</p><?php endif; ?><?php foreach ($services as $service): ?><p><strong><?= h($service['name']) ?></strong> — <?= h($service['address']) ?></p><?php endforeach; ?></section>
</div></div><?php require dirname(__DIR__) . '/partials/footer.php'; ?>
