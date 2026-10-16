<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';
$pageTitle = 'About BKK';
$pageDescription = 'Meet BKK Community Group, a South African non-profit community organisation helping older people stay connected through events, useful information and local support.';
$activeNav = 'about';
require __DIR__ . '/partials/header.php';
?>
<section class="hero">
    <div class="shell hero-grid hero-grid-simple"><div class="hero-copy">
        <p class="eyebrow eyebrow-light">Our community</p>
        <h1>About BKK Community Group</h1>
        <p>Helping older people stay connected, active and informed.</p>
        <div class="hero-actions"><a class="button button-light" href="<?= h(app_url('events.php')) ?>">Explore community events <?= icon_svg('arrow') ?></a></div>
    </div></div>
</section>
<section class="section section-white"><div class="shell about-reading">
    <p class="eyebrow">Who we are</p>
    <h2>Supporting older community members</h2>
    <p>BKK Community Group is a non-profit organisation in South Africa serving older community members. Our founder is Andrew Spaumer.</p>
    <p>Our aim is to make it easier for older people to find useful information, take part in community activities and stay in touch with the community team.</p>
    <h2>Why this platform exists</h2>
    <p>When updates are scattered across different messages and channels, it can be difficult to know what is happening, where to find help or which information is current. People can miss activities and useful services simply because the information is hard to find.</p>
    <p>The BKK website and Android app bring community events, senior-discount information, local services and enquiries together in one place. The platform is designed to support participation and connection, not replace personal contact.</p>
</div></section>
<section class="section section-blue"><div class="shell">
    <div class="section-heading"><div><p class="eyebrow">What you can do here</p><h2>Practical information for everyday community life</h2></div></div>
    <div class="feature-grid">
        <a class="feature-card tone-blue" href="<?= h(app_url('events.php')) ?>"><span class="feature-icon"><?= icon_svg('calendar') ?></span><h3>Join community activities</h3><p>See event dates, times and venues. Sign in to confirm or cancel your attendance so the team can plan.</p><span class="card-link">Find an event <?= icon_svg('arrow') ?></span></a>
        <a class="feature-card tone-green" href="<?= h(app_url('discounts.php')) ?>"><span class="feature-icon"><?= icon_svg('tag') ?></span><h3>Understand available discounts</h3><p>Read offer details, who qualifies and how to claim. Always confirm the terms and availability with the business before buying.</p><span class="card-link">View discount information <?= icon_svg('arrow') ?></span></a>
        <a class="feature-card tone-teal" href="<?= h(app_url('info.php')) ?>"><span class="feature-icon"><?= icon_svg('pin') ?></span><h3>Find local support</h3><p>Look for local-service information, including pharmacies, clinics, shops, transport and community support.</p><span class="card-link">Find local information <?= icon_svg('arrow') ?></span></a>
        <a class="feature-card tone-red" href="<?= h(app_url('contact.php')) ?>"><span class="feature-icon"><?= icon_svg('mail') ?></span><h3>Speak to the BKK team</h3><p>Ask a question, request help using the platform or share feedback through the contact form.</p><span class="card-link">Contact BKK <?= icon_svg('arrow') ?></span></a>
    </div>
</div></section>
<section class="section section-white"><div class="shell about-reading">
    <h2>Built to be straightforward</h2>
    <p>The platform is intended for older community members, including people who are less confident with technology. Clear labels, readable text and simple choices help people find their way. Family members can also use the website to find information and help someone get started.</p>
    <h2>How information reaches you</h2>
    <p>Authorised BKK staff manage events, discounts and local-service information through the website. The Android app reads from the same central system, so members do not need to search through separate sets of updates.</p>
    <p>Some actions, including confirming attendance and sending a message, need an internet connection. The Android app can keep previously loaded information available when you are offline.</p>
    <h2>Start with one simple step</h2>
    <p>Find an activity that interests you, or contact the community team if you are unsure where to begin.</p>
    <p><a class="button" href="<?= h(app_url('events.php')) ?>">Explore community events <?= icon_svg('arrow') ?></a></p>
    <p><a href="<?= h(app_url('contact.php')) ?>">Ask BKK a question</a> · <a href="<?= h(app_url('download.php')) ?>">Get the Android app</a></p>
</div></section>
<?php require __DIR__ . '/partials/footer.php'; ?>
