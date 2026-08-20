<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin();
$pageTitle = 'Manage events';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'events';
$events = admin_all_events();
$editId = filter_var($_GET['edit'] ?? null, FILTER_VALIDATE_INT);
$editing = $editId ? admin_get_event((int) $editId) : null;
if ($editId && !$editing) {
    flash('error', 'That event could not be found.');
    redirect_to('admin/events.php');
}
$form = $editing ?? ['title' => '', 'date' => '', 'time' => '', 'end_time' => '', 'location' => '', 'category' => 'Community', 'tone' => 'blue', 'description' => '', 'directions' => ''];
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header">
            <div><p class="eyebrow">Content management</p><h1>Manage events</h1></div>
            <a class="button button-outline" href="<?= h(app_url('events.php')) ?>">View public page</a>
        </header>
        <form class="panel" action="<?= h(app_url('actions.php')) ?>" method="post">
            <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>">
            <input type="hidden" name="action" value="<?= $editing ? 'admin_update_event' : 'admin_create_event' ?>">
            <?php if ($editing): ?><input type="hidden" name="id" value="<?= (int) $editing['id'] ?>"><input type="hidden" name="version" value="<?= h($editing['version']) ?>"><?php endif; ?>
            <div class="section-heading"><h2><?= $editing ? 'Edit event' : 'Add an event' ?></h2><?php if ($editing): ?><a href="<?= h(app_url('admin/events.php')) ?>">Cancel edit</a><?php endif; ?></div>
            <div class="form-grid">
                <div class="field field-full"><label for="title">Event title</label><input id="title" name="title" value="<?= h($form['title']) ?>" required minlength="3" maxlength="160"></div>
                <div class="field"><label for="date">Date</label><input id="date" name="date" type="date" value="<?= h($form['date']) ?>" required></div>
                <div class="field"><label for="category">Category</label><select id="category" name="category"><?php foreach (['Community', 'Wellness', 'Social', 'Health', 'Support'] as $category): ?><option <?= $form['category'] === $category ? 'selected' : '' ?>><?= h($category) ?></option><?php endforeach; ?></select></div>
                <div class="field"><label for="time">Start time</label><input id="time" name="time" type="time" value="<?= h($form['time']) ?>" required></div>
                <div class="field"><label for="end_time">End time</label><input id="end_time" name="end_time" type="time" value="<?= h($form['end_time']) ?>" required></div>
                <div class="field field-full"><label for="location">Location</label><input id="location" name="location" value="<?= h($form['location']) ?>" required minlength="3" maxlength="190"></div>
                <div class="field"><label for="tone">Card colour</label><select id="tone" name="tone"><?php foreach (['blue', 'green', 'teal', 'red', 'gold'] as $tone): ?><option value="<?= h($tone) ?>" <?= ($form['tone'] ?? tone_from_colour($form['colour_hex'] ?? null)) === $tone ? 'selected' : '' ?>><?= h(ucfirst($tone)) ?></option><?php endforeach; ?></select></div>
                <div class="field field-full"><label for="description">Description</label><textarea id="description" name="description" required minlength="10" maxlength="5000"><?= h($form['description']) ?></textarea></div>
                <div class="field field-full"><label for="directions">Directions (optional)</label><textarea id="directions" name="directions" maxlength="2000"><?= h($form['directions'] ?? '') ?></textarea></div>
            </div>
            <button class="button" type="submit"><?= $editing ? 'Save event changes' : 'Add event' ?></button>
        </form>
        <section class="panel admin-list-panel">
            <h2>All events</h2><p class="admin-table-hint">On a small screen, swipe the table sideways to see every column.</p>
            <div class="table-wrap" role="region" aria-label="All events table" tabindex="0"><table class="data-table"><thead><tr><th>Event</th><th>Date</th><th>Status</th><th>Actions</th></tr></thead><tbody>
            <?php foreach ($events as $event): $archived = ($event['status'] ?? 'published') !== 'published'; ?>
                <tr><td><strong><?= h($event['title']) ?></strong><br><small><?= h($event['category']) ?> · <?= h($event['location']) ?></small></td><td><?= h((new DateTimeImmutable($event['date']))->format('d M Y')) ?><br><small><?= h($event['time']) ?>–<?= h($event['end_time']) ?></small></td><td><span class="status-badge <?= $archived ? 'status-muted' : 'status-live' ?>"><?= $archived ? 'Archived' : 'Published' ?></span></td><td><div class="admin-actions"><a class="button button-small button-outline" href="<?= h(app_url('admin/events.php?edit=' . (int) $event['id'])) ?>">Edit</a><form action="<?= h(app_url('actions.php')) ?>" method="post"><input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_set_event_archived"><input type="hidden" name="id" value="<?= (int) $event['id'] ?>"><input type="hidden" name="archived" value="<?= $archived ? '0' : '1' ?>"><label class="visually-hidden" for="event-reason-<?= (int) $event['id'] ?>">Reason</label><input class="reason-input" id="event-reason-<?= (int) $event['id'] ?>" name="reason" required minlength="5" maxlength="255" placeholder="Reason for <?= $archived ? 'restoring' : 'archiving' ?>"><button class="button button-small <?= $archived ? '' : 'button-danger' ?>" type="submit" data-confirm="<?= $archived ? 'Restore' : 'Archive' ?> this event?"><?= $archived ? 'Restore' : 'Archive' ?></button></form></div></td></tr>
            <?php endforeach; ?>
            </tbody></table></div>
        </section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
