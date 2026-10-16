<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';
$pageTitle = 'Download Android app';
$activeNav = 'download';
$download = require dirname(__DIR__) . '/app/android_download.php';
require __DIR__ . '/partials/header.php';
?>
<section class="section section-blue">
    <div class="shell download-layout">
        <p class="eyebrow">BKK on your phone</p>
        <h1>Download the Android app</h1>
        <p>Keep community events, discounts and local information close at hand. Use the same BKK account as the website.</p>
        <p><strong>Version <?= h($download['version']) ?></strong> · Android 8 or newer · Approximately 21 MB</p>
        <p><a class="button" href="<?= h(app_url('download-apk.php')) ?>"><?= icon_svg('download') ?> Download Android APK</a></p>
        <p>This is a signed testing build, downloaded from our public GitHub release. It is not a Google Play release.</p>
        <p><strong>Using an iPhone?</strong> This APK works only on Android. You can use <a href="<?= h(app_url('index.php')) ?>">the BKK website</a> in your browser instead.</p>
    </div>
</section>
<section class="section section-white"><div class="shell download-layout">
    <h2>How to install</h2>
    <ol class="download-steps">
        <li>Open this page on your Android phone and select <strong>Download Android APK</strong>.</li>
        <li>After downloading, open your phone’s Downloads folder and select <strong><?= h($download['filename']) ?></strong>.</li>
        <li>If Android asks, allow this browser or file manager to install this app. Change only that app’s permission, not your phone’s general security protections.</li>
        <li>Select <strong>Install</strong>, then open BKK Community and sign in or register.</li>
        <li>After installation, turn the browser or file manager’s <strong>Allow from this source</strong> setting off again.</li>
    </ol>
    <p><strong>Keep Play Protect switched on.</strong> If your phone blocks installation or reports a security warning, stop and <a href="<?= h(app_url('contact.php')) ?>">contact BKK for help</a>.</p>
    <h2>Already have the app?</h2>
    <p>Install this APK over your existing copy if Android allows the update. If you see “App not installed” or a signing conflict, contact BKK before uninstalling. Uninstalling can remove locally saved information.</p>
    <h2>Need help downloading?</h2>
    <p>If the download fails, check your connection and try again. You can continue using the website without installing anything.</p>
    <details><summary>File verification details</summary><p>Filename: <?= h($download['filename']) ?></p><p>SHA-256 checksum:</p><code class="download-checksum"><?= h($download['sha256']) ?></code></details>
</div></section>
<?php require __DIR__ . '/partials/footer.php'; ?>
