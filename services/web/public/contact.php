<?php

declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';

$pageTitle = 'Contact us';
$activeNav = 'contact';
$user = current_user();
$subject = trim((string) ($_GET['subject'] ?? 'General enquiry'));
require __DIR__ . '/partials/header.php';
?>
<section class="page-hero"><div class="shell"><p class="eyebrow eyebrow-light">We are here to help</p><h1>Contact BKK Community</h1><p>Send one clear message to the community team. We collect only the information needed to respond.</p></div></section>
<section class="form-page">
    <div class="shell form-layout">
        <form class="form-card" action="<?= h(app_url('actions.php')) ?>" method="post" novalidate>
            <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="contact">
            <h2>Send us a message</h2><p class="form-intro">Required fields are marked “required”. Your message is saved for BKK staff to review; a response time is not yet guaranteed.</p>
            <div class="form-grid">
                <div class="field"><label for="name">Full name <span aria-hidden="true">*</span></label><input id="name" name="name" autocomplete="name" required minlength="2" value="<?= h($user['full_name'] ?? '') ?>"></div>
                <div class="field"><label for="email">Email address <span aria-hidden="true">*</span></label><input id="email" name="email" type="email" autocomplete="email" required value="<?= h($user['email'] ?? '') ?>"></div>
                <div class="field"><label for="phone">Phone number</label><input id="phone" name="phone" type="tel" autocomplete="tel" value="<?= h($user['phone'] ?? '') ?>"></div>
                <div class="field"><label for="subject">Subject <span aria-hidden="true">*</span></label><select id="subject" name="subject" required><option <?= $subject === 'General enquiry' ? 'selected' : '' ?>>General enquiry</option><option <?= str_starts_with($subject, 'Event') ? 'selected' : '' ?>>Event enquiry</option><option <?= str_starts_with($subject, 'Discount') ? 'selected' : '' ?>>Discount enquiry</option><option <?= $subject === 'Local service enquiry' ? 'selected' : '' ?>>Local service enquiry</option><option <?= $subject === 'Website support' ? 'selected' : '' ?>>Website support</option></select></div>
                <div class="field field-full"><label for="message">Message <span aria-hidden="true">*</span></label><textarea id="message" name="message" required minlength="10" maxlength="2000" placeholder="Please tell us how we can help."></textarea><small>10–2,000 characters. Do not include identity numbers, medical records or banking information.</small></div>
            </div>
            <button class="button" type="submit"><?= icon_svg('mail') ?> Send message</button>
        </form>
        <aside class="side-panel">
            <p class="eyebrow eyebrow-light">Contact information</p><h2>Verified details are coming</h2><p>BKK staff have not yet confirmed a public phone number, email address, office location or response time. Please use the message form for now. Do not use contact details shown in demonstration records.</p>
        </aside>
    </div>
</section>
<?php require __DIR__ . '/partials/footer.php'; ?>

