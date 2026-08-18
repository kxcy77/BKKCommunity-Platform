<?php

declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';

$pageTitle = 'Stay connected';
$activeNav = 'home';
$events = array_slice(all_events(), 0, 2);
$discounts = array_slice(all_discounts(), 0, 3);
$rsvpIds = rsvp_ids_for_current_user();
require __DIR__ . '/partials/header.php';
?>

<section class="hero">
    <div class="shell hero-grid hero-grid-simple">
        <div class="hero-copy">
            <p class="eyebrow eyebrow-light">BKK Community Group</p>
            <h1>What would you like to do today?</h1>
            <p>Choose one option below. You can always use Home to start again.</p>
        </div>
    </div>
</section>

<section class="section section-white">
    <div class="shell">
        <div class="section-heading">
            <div>
                <p class="eyebrow">Start here</p>
                <h2>Choose one task</h2>
                <p>Each option takes you directly to the information you need.</p>
            </div>
        </div>
        <div class="feature-grid">
            <a class="feature-card tone-blue" href="<?= h(app_url('events.php')) ?>">
                <span class="feature-icon"><?= icon_svg('calendar') ?></span>
                <h3>Community events</h3>
                <p>See upcoming activities and confirm attendance.</p>
                <span class="card-link">Browse events <?= icon_svg('arrow') ?></span>
            </a>
            <a class="feature-card tone-green" href="<?= h(app_url('discounts.php')) ?>">
                <span class="feature-icon"><?= icon_svg('tag') ?></span>
                <h3>Senior discounts</h3>
                <p>Find savings and read how to claim each offer.</p>
                <span class="card-link">Find savings <?= icon_svg('arrow') ?></span>
            </a>
            <a class="feature-card tone-teal" href="<?= h(app_url('info.php')) ?>">
                <span class="feature-icon"><?= icon_svg('pin') ?></span>
                <h3>Local services</h3>
                <p>Find phone numbers, addresses and opening hours.</p>
                <span class="card-link">View local support <?= icon_svg('arrow') ?></span>
            </a>
            <a class="feature-card tone-red" href="<?= h(app_url('contact.php')) ?>">
                <span class="feature-icon"><?= icon_svg('mail') ?></span>
                <h3>Contact BKK</h3>
                <p>Ask for help or send the community team a message.</p>
                <span class="card-link">Get help <?= icon_svg('arrow') ?></span>
            </a>
        </div>
    </div>
</section>

<section class="section section-blue" id="upcoming-events">
    <div class="shell">
        <div class="section-heading">
            <div>
                <p class="eyebrow">Plan your week</p>
                <h2>Upcoming events</h2>
                <p>Confirming attendance helps the group prepare seating, refreshments and support.</p>
            </div>
            <a class="section-link" href="<?= h(app_url('events.php')) ?>">View all events <?= icon_svg('arrow') ?></a>
        </div>
        <div class="event-list">
            <?php foreach ($events as $event): ?>
                <?php $date = new DateTimeImmutable($event['date']); $attending = in_array((int) $event['id'], $rsvpIds, true); ?>
                <article class="event-card tone-<?= h($event['tone']) ?>">
                    <div class="event-date"><span><?= h($date->format('M')) ?></span><strong><?= h($date->format('d')) ?></strong><span><?= h($date->format('D')) ?></span></div>
                    <div class="event-content">
                        <h3><?= h($event['title']) ?></h3>
                        <div class="event-meta">
                            <span><?= icon_svg('clock') ?> <?= h($event['time']) ?>–<?= h($event['end_time']) ?></span>
                            <span><?= icon_svg('pin') ?> <?= h($event['location']) ?></span>
                        </div>
                    </div>
                    <div class="event-action">
                        <?php if (!empty($event['is_demo'])): ?>
                            <div class="demo-event-action" role="note"><strong>Demonstration only</strong><span>Attendance is unavailable for this test event.</span></div>
                        <?php else: ?>
                        <form action="<?= h(app_url('actions.php')) ?>" method="post">
                            <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>">
                            <input type="hidden" name="action" value="toggle_rsvp">
                            <input type="hidden" name="event_id" value="<?= (int) $event['id'] ?>">
                            <input type="hidden" name="return_to" value="index.php">
                            <button class="button <?= $attending ? 'rsvp-active' : '' ?>" type="submit"><?= $attending ? icon_svg('check') . ' Attending' : 'I will attend' ?></button>
                        </form>
                        <?php endif; ?>
                    </div>
                </article>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="section section-gold">
    <div class="shell">
        <div class="section-heading">
            <div>
                <p class="eyebrow eyebrow-gold">Featured savings</p>
                <h2>Spend a little less</h2>
                <p>Offers can change. Always confirm availability and eligibility with the participating business before purchasing.</p>
            </div>
            <a class="section-link" href="<?= h(app_url('discounts.php')) ?>">See all discounts <?= icon_svg('arrow') ?></a>
        </div>
        <div class="discount-row">
            <?php foreach ($discounts as $discount): ?>
                <article class="discount-mini"><strong><?= h($discount['store_name']) ?></strong><span><?= h($discount['deal']) ?></span></article>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<?php require __DIR__ . '/partials/footer.php'; ?>
