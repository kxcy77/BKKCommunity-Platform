<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin();
$pageTitle = 'Manage local services';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'services';
$services = admin_all_services();
$editId = filter_var($_GET['edit'] ?? null, FILTER_VALIDATE_INT);
$editing = $editId ? admin_get_service((int) $editId) : null;
if ($editId && !$editing) {
    flash('error', 'That local service could not be found.');
    redirect_to('admin/services.php');
}
$form = $editing ?? ['type' => 'clinic', 'name' => '', 'address' => '', 'phone' => '', 'directions' => '', 'opening_hours' => ''];
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Content management</p><h1>Manage local services</h1></div><a class="button button-outline" href="<?= h(app_url('info.php')) ?>">View public page</a></header>
        <form class="panel" action="<?= h(app_url('actions.php')) ?>" method="post">
            <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="<?= $editing ? 'admin_update_service' : 'admin_create_service' ?>"><?php if ($editing): ?><input type="hidden" name="id" value="<?= (int) $editing['id'] ?>"><input type="hidden" name="version" value="<?= h($editing['version']) ?>"><?php endif; ?>
            <div class="section-heading"><h2><?= $editing ? 'Edit local service' : 'Add a local service' ?></h2><?php if ($editing): ?><a href="<?= h(app_url('admin/services.php')) ?>">Cancel edit</a><?php endif; ?></div>
            <div class="form-grid">
                <div class="field"><label for="type">Service type</label><select id="type" name="type" required><?php foreach (['clinic' => 'Clinic', 'pharmacy' => 'Pharmacy', 'shop' => 'Shop', 'support' => 'Support', 'transport' => 'Transport'] as $value => $label): ?><option value="<?= h($value) ?>" <?= $form['type'] === $value ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select></div>
                <div class="field"><label for="name">Service name</label><input id="name" name="name" value="<?= h($form['name']) ?>" required minlength="2" maxlength="160"></div>
                <div class="field field-full"><label for="address">Address</label><input id="address" name="address" value="<?= h($form['address']) ?>" required minlength="4" maxlength="255"></div>
                <div class="field"><label for="phone">Phone number</label><input id="phone" name="phone" type="tel" value="<?= h($form['phone']) ?>" required minlength="5" maxlength="30" pattern="[0-9+() .-]{5,30}"></div>
                <div class="field"><label for="opening_hours">Opening hours</label><input id="opening_hours" name="opening_hours" value="<?= h($form['opening_hours'] ?? $form['hours'] ?? '') ?>" required minlength="3" maxlength="190"></div>
                <div class="field field-full"><label for="directions">Directions and support information</label><textarea id="directions" name="directions" required minlength="5" maxlength="2000"><?= h($form['directions'] ?? $form['description'] ?? '') ?></textarea></div>
            </div>
            <button class="button" type="submit"><?= $editing ? 'Save service changes' : 'Add local service' ?></button>
        </form>
        <section class="panel admin-list-panel">
            <h2>All services</h2><p class="admin-table-hint">Archived services are retained for recovery and audit purposes.</p>
            <div class="table-wrap" role="region" aria-label="All local services table" tabindex="0"><table class="data-table"><thead><tr><th>Service</th><th>Contact</th><th>Status</th><th>Actions</th></tr></thead><tbody>
            <?php foreach ($services as $service): $archived = !(bool) ($service['is_active'] ?? 1); ?>
                <tr><td><strong><?= h($service['name']) ?></strong><br><small><?= h(ucfirst($service['type'])) ?> · <?= h($service['address']) ?></small></td><td><?= h($service['phone']) ?><br><small><?= h($service['opening_hours'] ?? $service['hours'] ?? '') ?></small></td><td><span class="status-badge <?= $archived ? 'status-muted' : 'status-live' ?>"><?= $archived ? 'Archived' : 'Active' ?></span></td><td><div class="admin-actions"><a class="button button-small button-outline" href="<?= h(app_url('admin/services.php?edit=' . (int) $service['id'])) ?>">Edit</a><form action="<?= h(app_url('actions.php')) ?>" method="post"><input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_set_service_archived"><input type="hidden" name="id" value="<?= (int) $service['id'] ?>"><input type="hidden" name="archived" value="<?= $archived ? '0' : '1' ?>"><label class="visually-hidden" for="service-reason-<?= (int) $service['id'] ?>">Reason</label><input class="reason-input" id="service-reason-<?= (int) $service['id'] ?>" name="reason" required minlength="5" maxlength="255" placeholder="Reason"><button class="button button-small <?= $archived ? '' : 'button-danger' ?>" type="submit" data-confirm="<?= $archived ? 'Restore' : 'Archive' ?> this service?"><?= $archived ? 'Restore' : 'Archive' ?></button></form></div></td></tr>
            <?php endforeach; ?>
            </tbody></table></div>
        </section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
