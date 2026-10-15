<?php
declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_permission('staff');
header('Cache-Control: no-store, private');
$pageTitle = 'Staff access'; $bodyClass = 'admin-page'; $activeNav = 'admin'; $adminPage = 'staff';
$db = database();
$staff = $db ? $db->query("SELECT id, full_name, email, staff_level, auth_version FROM users WHERE role = 'admin' AND deleted_at IS NULL ORDER BY full_name, id")->fetchAll() : [];
$invitations = $db ? $db->query('SELECT id, email, staff_level, expires_at FROM staff_invitations WHERE accepted_at IS NULL AND revoked_at IS NULL AND expires_at > UTC_TIMESTAMP() ORDER BY id DESC LIMIT 100')->fetchAll() : [];
$newInvite = $_SESSION['new_staff_invitation'] ?? null;
unset($_SESSION['new_staff_invitation']);
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell"><?php require __DIR__ . '/_sidebar.php'; ?><div class="admin-content">
<header class="admin-header"><div><p class="eyebrow">Owner controls</p><h1>Staff access</h1></div></header>
<section class="panel"><h2>Choose the right level</h2><ul>
<li><strong>Owner:</strong> staff invitations, permissions, content, member directory, attendance, messages and audit history.</li>
<li><strong>Content editor:</strong> add, edit, archive and restore events, discounts and services. No member directory, private inbox or staff controls.</li>
<li><strong>Support:</strong> handle contact messages and view attendance enquiries. Cannot edit content or staff access.</li>
<li><strong>Read-only:</strong> dashboard and public-content overview only. No editing or member information.</li></ul>
<p>Every staff member needs their own account. Changing or removing access signs that person out of existing website and Android sessions. The final owner cannot be removed.</p></section>
<?php if ($newInvite): ?><section class="panel"><h2>Share this invitation privately</h2>
<p>For <?= h($newInvite['email']) ?>. Copy this code now; it is shown once and expires after 48 hours. No email has been sent automatically.</p>
<div class="field"><label for="new-invitation-code">One-time invitation code</label><input id="new-invitation-code" readonly value="<?= h($newInvite['code']) ?>" autocomplete="off"></div>
<p>Ask the recipient to register or sign in with that email, then open <a href="<?= h(app_url('staff-invitation.php')) ?>">Accept staff invitation</a> and paste the code. Do not put this code in public messages, screenshots or documents.</p></section><?php endif; ?>
<form class="panel" method="post" action="<?= h(app_url('actions.php')) ?>"><h2>Invite staff</h2>
<input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_invite_staff">
<div class="form-grid"><div class="field"><label for="invite-email">Staff email address</label><input id="invite-email" name="email" type="email" maxlength="190" required></div>
<div class="field"><label for="invite-level">Access level</label><select id="invite-level" name="staff_level"><?php foreach (staff_levels() as $value => $label): ?><option value="<?= h($value) ?>" <?= $value === 'viewer' ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select></div>
<div class="field"><label for="invite-reason">Reason for access</label><input id="invite-reason" name="reason" minlength="5" maxlength="255" required></div>
<div class="field"><label for="invite-password">Your current password</label><input id="invite-password" name="current_password" type="password" autocomplete="current-password" required></div></div>
<button class="button" type="submit" data-confirm="Create a private staff invitation with this access level?">Create invitation</button></form>
<section class="panel"><h2>Current staff</h2><?php if (!$staff): ?><p>No connected staff records.</p><?php endif; ?>
<?php foreach ($staff as $person): ?><form class="panel" method="post" action="<?= h(app_url('actions.php')) ?>">
<h3><?= h($person['full_name']) ?></h3><p><?= h($person['email']) ?> — <?= h(staff_levels()[$person['staff_level']]) ?></p>
<input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_change_staff"><input type="hidden" name="id" value="<?= (int) $person['id'] ?>"><input type="hidden" name="version" value="<?= (int) $person['auth_version'] ?>">
<div class="form-grid"><div class="field"><label for="level-<?= (int) $person['id'] ?>">New access level</label><select id="level-<?= (int) $person['id'] ?>" name="staff_level"><?php foreach (staff_levels() + ['member' => 'Remove staff access (keep member account)'] as $value => $label): ?><option value="<?= h($value) ?>" <?= $value === $person['staff_level'] ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select></div>
<div class="field"><label for="reason-<?= (int) $person['id'] ?>">Reason</label><input id="reason-<?= (int) $person['id'] ?>" name="reason" minlength="5" maxlength="255" required></div>
<div class="field"><label for="password-<?= (int) $person['id'] ?>">Your current password</label><input id="password-<?= (int) $person['id'] ?>" name="current_password" type="password" autocomplete="current-password" required></div></div>
<button class="button button-small" type="submit" data-confirm="Change this person's access and sign out their existing sessions?">Save access</button></form><?php endforeach; ?></section>
<section class="panel"><h2>Pending invitations</h2><p>Showing up to 100 current invitations. Creating another invitation for the same email cancels the previous code.</p><?php if (!$invitations): ?><p>No pending invitations.</p><?php endif; ?>
<?php foreach ($invitations as $invite): ?><form method="post" action="<?= h(app_url('actions.php')) ?>"><p><strong><?= h($invite['email']) ?></strong> — <?= h(staff_levels()[$invite['staff_level']]) ?>. Expires <?= h((new DateTimeImmutable($invite['expires_at'], new DateTimeZone('UTC')))->setTimezone(new DateTimeZone('Africa/Johannesburg'))->format('d M Y, H:i')) ?> (South Africa).</p>
<input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="admin_revoke_invitation"><input type="hidden" name="id" value="<?= (int) $invite['id'] ?>">
<div class="form-grid"><div class="field"><label for="cancel-reason-<?= (int) $invite['id'] ?>">Reason for cancellation</label><input id="cancel-reason-<?= (int) $invite['id'] ?>" name="reason" minlength="5" maxlength="255" required></div><div class="field"><label for="cancel-password-<?= (int) $invite['id'] ?>">Your current password</label><input id="cancel-password-<?= (int) $invite['id'] ?>" name="current_password" type="password" autocomplete="current-password" required></div></div><button class="button button-small button-danger" type="submit">Cancel invitation</button></form><?php endforeach; ?></section>
</div></div><?php require dirname(__DIR__) . '/partials/footer.php'; ?>
