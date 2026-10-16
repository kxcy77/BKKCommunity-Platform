<?php

declare(strict_types=1);
require_once dirname(__DIR__) . '/app/bootstrap.php';
require_once dirname(__DIR__) . '/app/calendar.php';

$pageTitle = 'Community events';
$activeNav = 'events';
$category = is_string($_GET['category'] ?? null) ? trim($_GET['category']) : 'All';
$events = all_events();
$categories = array_values(array_unique(array_column($events, 'category')));
if ($category !== 'All') {
    $events = array_values(array_filter($events, fn (array $event): bool => strcasecmp($event['category'], $category) === 0));
}
$rsvpIds = rsvp_ids_for_current_user();
$calendar = event_calendar($events, is_string($_GET['month'] ?? null) ? $_GET['month'] : null);
require __DIR__ . '/partials/header.php';
?>

<section class="page-hero">
    <div class="shell">
        <p class="eyebrow eyebrow-light">Stay active together</p>
        <h1>Community events</h1>
        <p>Use the simple calendar for a quick overview, or read the detailed list below. Browsing is open to everyone.</p>
    </div>
</section>

<section class="section">
    <div class="shell">
        <nav class="filter-bar" aria-label="Filter events by category">
            <a class="filter-pill" href="<?= h(app_url('events.php' . event_calendar_query($calendar['month'], 'All'))) ?>" aria-current="<?= $category === 'All' ? 'true' : 'false' ?>">All events</a>
            <?php foreach ($categories as $item): ?>
                <a class="filter-pill" href="<?= h(app_url('events.php' . event_calendar_query($calendar['month'], $item))) ?>" aria-current="<?= $category === $item ? 'true' : 'false' ?>"><?= h($item) ?></a>
            <?php endforeach; ?>
        </nav>

        <section class="calendar-panel" aria-labelledby="calendar-heading">
            <div class="calendar-header"><h2 id="calendar-heading"><?= h($calendar['label']) ?></h2><span>Event days are marked with an “E”</span></div>
            <nav class="calendar-controls" aria-label="Choose calendar month">
                <?php if ($calendar['previous'] !== null): ?><a class="button button-outline" href="<?= h(app_url('events.php' . event_calendar_query($calendar['previous'], $category))) ?>">Previous month</a><?php endif; ?>
                <a class="button button-outline" href="<?= h(app_url('events.php' . event_calendar_query(null, $category))) ?>">Current month</a>
                <?php if ($calendar['next'] !== null): ?><a class="button button-outline" href="<?= h(app_url('events.php' . event_calendar_query($calendar['next'], $category))) ?>">Next month</a><?php endif; ?>
            </nav>
            <p>Viewing <?= h($calendar['label']) ?>. The list below includes all upcoming events in the selected category.</p>
            <div class="calendar-scroll" tabindex="0" aria-label="<?= h('Scrollable ' . $calendar['label'] . ' event calendar') ?>"><div class="calendar-grid">
                <?php foreach (['Sun','Mon','Tue','Wed','Thu','Fri','Sat'] as $weekday): ?><div class="calendar-weekday"><?= h($weekday) ?></div><?php endforeach; ?>
                <?php for ($blank = 0; $blank < $calendar['offset']; $blank++): ?><div class="calendar-day" aria-hidden="true"></div><?php endfor; ?>
                <?php for ($day = 1; $day <= $calendar['days']; $day++): ?>
                    <?php $fullDate = $calendar['month'] . '-' . str_pad((string) $day, 2, '0', STR_PAD_LEFT); $dayEvents = $calendar['events_by_date'][$fullDate] ?? []; ?>
                    <div class="calendar-day <?= $dayEvents ? 'has-event' : '' ?> <?= $fullDate === $calendar['today'] ? 'is-today' : '' ?>">
                        <?php if ($dayEvents): ?>
                            <a class="calendar-date-link" href="#event-<?= (int) $dayEvents[0]['id'] ?>" aria-label="<?= h($fullDate . ': ' . count($dayEvents) . ' scheduled event(s). Read event details.') ?>"><span><?= $day ?></span><span class="calendar-marker" aria-hidden="true">E</span></a>
                        <?php else: ?><span><?= $day ?></span><?php endif; ?>
                        <?php if ($fullDate === $calendar['today']): ?><span class="calendar-today-label">Today</span><?php endif; ?>
                    </div>
                <?php endfor; ?>
            </div></div>
        </section>

        <div class="section-heading">
            <div><p class="eyebrow">Detailed list</p><h2><?= $category === 'All' ? 'All upcoming events' : h($category) . ' events' ?></h2></div>
        </div>
        <?php if (!$events): ?>
            <div class="empty-state"><h2>No events in this category</h2><p>Choose another category or return to all events.</p></div>
        <?php else: ?>
            <div class="event-list">
                <?php foreach ($events as $event): ?>
                    <?php $date = new DateTimeImmutable($event['date']); $attending = in_array((int) $event['id'], $rsvpIds, true); ?>
                    <article id="event-<?= (int) $event['id'] ?>" class="event-card tone-<?= h($event['tone']) ?>" tabindex="-1">
                        <div class="event-date"><span><?= h($date->format('M')) ?></span><strong><?= h($date->format('d')) ?></strong><span><?= h($date->format('D')) ?></span></div>
                        <div class="event-content">
                            <h3><?= h($event['title']) ?></h3>
                            <div class="event-meta"><span><?= icon_svg('clock') ?> <?= h($event['time']) ?>–<?= h($event['end_time']) ?></span><span><?= icon_svg('pin') ?> <?= h($event['location']) ?></span><span><?= h($event['category']) ?></span></div>
                            <p><?= h($event['description']) ?></p>
                        </div>
                        <div class="event-action">
                            <form action="<?= h(app_url('actions.php')) ?>" method="post">
                                <input type="hidden" name="csrf_token" value="<?= h(csrf_token()) ?>"><input type="hidden" name="action" value="toggle_rsvp"><input type="hidden" name="event_id" value="<?= (int) $event['id'] ?>"><input type="hidden" name="return_to" value="<?= h('events.php' . event_calendar_query($calendar['month'], $category)) ?>">
                                <button class="button <?= $attending ? 'rsvp-active' : '' ?>" type="submit"><?= $attending ? icon_svg('check') . ' Attending' : 'I will attend' ?></button>
                            </form>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</section>

<?php require __DIR__ . '/partials/footer.php'; ?>
