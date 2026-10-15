<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_permission('dashboard');
$pageTitle = 'Admin dashboard';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'dashboard';
$metrics = admin_metrics();
$events = array_slice(all_events(), 0, 5);
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Administrator</p><h1>Dashboard overview</h1></div><span>Welcome, <?= h(current_user()['full_name']) ?></span></header>
        <p>Your access: <?= h(staff_levels()[current_user()['staff_level'] ?? 'owner'] ?? 'Unassigned') ?>. The menu shows the sections available to you.</p>
        <div class="metric-grid">
            <article class="metric tone-blue"><strong><?= $metrics['events'] ?></strong><span>Upcoming events</span></article>
            <article class="metric tone-green"><strong><?= $metrics['discounts'] ?></strong><span>Active discounts</span></article>
            <?php if (staff_can('messages')): ?><article class="metric tone-gold"><strong><?= $metrics['messages'] ?></strong><span>New messages</span></article><?php endif; ?>
            <?php if (staff_can('users')): ?><a class="metric tone-teal" href="<?= h(app_url('admin/users.php')) ?>"><strong><?= $metrics['users'] ?></strong><span>Registered users</span></a><?php endif; ?>
        </div>
        <section class="panel"><div class="section-heading"><h2>Upcoming events</h2><?php if (staff_can('content.write')): ?><a class="button button-small" href="<?= h(app_url('admin/events.php')) ?>">Add event</a><?php endif; ?></div><div class="table-wrap" role="region" aria-label="Upcoming events table" tabindex="0"><table class="data-table"><thead><tr><th>Event</th><th>Date</th><th>Time</th><th>Location</th><th>Category</th></tr></thead><tbody><?php foreach ($events as $event): ?><tr><td><strong><?= h($event['title']) ?></strong></td><td><?= h((new DateTimeImmutable($event['date']))->format('d M Y')) ?></td><td><?= h($event['time']) ?></td><td><?= h($event['location']) ?></td><td><?= h($event['category']) ?></td></tr><?php endforeach; ?></tbody></table></div></section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
