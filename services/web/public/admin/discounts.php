<?php

declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin();
$pageTitle = 'Manage discounts';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'discounts';
$discounts = admin_all_discounts();
$editId = filter_var($_GET['edit'] ?? null, FILTER_VALIDATE_INT);
$editing = $editId ? admin_get_discount((int) $editId) : null;
if ($editId && !$editing) {
    flash('error', 'That discount could not be found.');
    redirect_to('admin/discounts.php');
}
$form = $editing ?? ['store_name' => '', 'category' => 'Pharmacy', 'deal' => '', 'eligibility' => '', 'claim_instructions' => '', 'tone' => 'blue', 'valid_from' => '', 'valid_until' => ''];
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Content management</p><h1>Manage discounts</h1></div><a class="button button-outline" href="<?= h(app_url('discounts.php')) ?>">View public page</a></header>
        <form class="panel" action="<?= h(app_url('actions.php')) ?>" method="post">
            <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="<?= $editing ? 'admin_update_discount' : 'admin_create_discount' ?>"><?php if ($editing): ?><input type="hidden" name="id" value="<?= (int) $editing['id'] ?>"><input type="hidden" name="version" value="<?= h($editing['version']) ?>"><?php endif; ?>
            <div class="section-heading"><h2><?= $editing ? 'Edit discount' : 'Add a discount' ?></h2><?php if ($editing): ?><a href="<?= h(app_url('admin/discounts.php')) ?>">Cancel edit</a><?php endif; ?></div>
            <div class="form-grid">
                <div class="field"><label for="store_name">Business name</label><input id="store_name" name="store_name" value="<?= h($form['store_name']) ?>" required minlength="2" maxlength="160"></div>
                <div class="field"><label for="category">Category</label><select id="category" name="category"><?php foreach (['Pharmacy', 'Grocery', 'Restaurant', 'Transport'] as $category): ?><option <?= $form['category'] === $category ? 'selected' : '' ?>><?= h($category) ?></option><?php endforeach; ?></select></div>
                <div class="field field-full"><label for="deal">Offer description</label><textarea id="deal" name="deal" required minlength="5" maxlength="5000"><?= h($form['deal']) ?></textarea></div>
                <div class="field"><label for="eligibility">Who qualifies</label><input id="eligibility" name="eligibility" value="<?= h($form['eligibility']) ?>" required minlength="3" maxlength="255"></div>
                <div class="field"><label for="claim_instructions">How to claim</label><input id="claim_instructions" name="claim_instructions" value="<?= h($form['claim_instructions']) ?>" required minlength="5" maxlength="2000"></div>
                <div class="field"><label for="valid_from">Valid from (optional)</label><input id="valid_from" name="valid_from" type="date" value="<?= h($form['valid_from'] ?? '') ?>"></div>
                <div class="field"><label for="valid_until">Valid until (optional)</label><input id="valid_until" name="valid_until" type="date" value="<?= h($form['valid_until'] ?? '') ?>"></div>
                <input type="hidden" name="tone" value="<?= h(tone_for_discount((string) $form['category'])) ?>">
            </div>
            <button class="button" type="submit"><?= $editing ? 'Save discount changes' : 'Add discount' ?></button>
        </form>
        <section class="panel admin-list-panel">
            <h2>All discounts</h2><p class="admin-table-hint">Archived offers stay in the audit history and disappear from the public page.</p>
            <div class="table-wrap" role="region" aria-label="All discounts table" tabindex="0"><table class="data-table"><thead><tr><th>Business</th><th>Offer</th><th>Status</th><th>Actions</th></tr></thead><tbody>
            <?php foreach ($discounts as $discount): $archived = !(bool) $discount['is_active']; ?>
                <tr><td><strong><?= h($discount['store_name']) ?></strong><br><small><?= h($discount['category']) ?></small></td><td><?= h($discount['deal']) ?></td><td><span class="status-badge <?= $archived ? 'status-muted' : 'status-live' ?>"><?= $archived ? 'Archived' : 'Active' ?></span></td><td><div class="admin-actions"><a class="button button-small button-outline" href="<?= h(app_url('admin/discounts.php?edit=' . (int) $discount['id'])) ?>">Edit</a><form action="<?= h(app_url('actions.php')) ?>" method="post"><input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_set_discount_archived"><input type="hidden" name="id" value="<?= (int) $discount['id'] ?>"><input type="hidden" name="archived" value="<?= $archived ? '0' : '1' ?>"><label class="visually-hidden" for="discount-reason-<?= (int) $discount['id'] ?>">Reason</label><input class="reason-input" id="discount-reason-<?= (int) $discount['id'] ?>" name="reason" required minlength="5" maxlength="255" placeholder="Reason"><button class="button button-small <?= $archived ? '' : 'button-danger' ?>" type="submit" data-confirm="<?= $archived ? 'Restore' : 'Archive' ?> this discount?"><?= $archived ? 'Restore' : 'Archive' ?></button></form></div></td></tr>
            <?php endforeach; ?>
            </tbody></table></div>
        </section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
