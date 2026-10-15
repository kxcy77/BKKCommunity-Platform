<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';
require_login();
header('Cache-Control: no-store, private');
header('Referrer-Policy: no-referrer');
$pageTitle = 'Accept staff invitation';
require __DIR__ . '/partials/header.php';
?>
<section class="panel"><h1>Accept your staff invitation</h1>
<p>You are signed in as <?= h(current_user()['email']) ?>. This must be the email address the owner invited. If you need a new account, register with your own password first.</p>
<p>Paste the one-time invitation code your owner shared privately. It expires after 48 hours. You will need to sign in again after accepting.</p>
<form method="post" action="<?= h(app_url('actions.php')) ?>">
<input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="accept_staff_invitation">
<div class="field"><label for="invitation_code">Invitation code</label><input id="invitation_code" name="invitation_code" type="password" autocomplete="off" required minlength="64" maxlength="64" pattern="[a-f0-9]{64}"></div>
<button class="button" type="submit">Accept staff invitation</button></form></section>
<?php require __DIR__ . '/partials/footer.php'; ?>
