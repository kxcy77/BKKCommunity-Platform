<?php

declare(strict_types=1);
require dirname(__DIR__) . '/app/calendar.php';

$checks = 0;
function calendar_check(bool $condition, string $message): void
{
    global $checks;
    if (!$condition) {
        fwrite(STDERR, "FAIL {$message}\n");
        exit(1);
    }
    $checks++;
}

$now = new DateTimeImmutable('2026-09-30T23:30:00+00:00');
$default = event_calendar([], null, $now);
calendar_check($default['label'] === 'October 2026', 'default month uses Johannesburg, not UTC');
calendar_check($default['offset'] === 4 && $default['days'] === 31, 'October starts on Thursday and has 31 days');
calendar_check($default['today'] === '2026-10-01', 'today uses the community time zone');
calendar_check(event_calendar([], '2024-02', $now)['days'] === 29, 'leap-year February');
calendar_check(event_calendar([], '2025-02', $now)['days'] === 28, 'ordinary February');
calendar_check(event_calendar([], '2026-04', $now)['days'] === 30, 'April has 30 days');
calendar_check(event_calendar([], '2026-11', $now)['offset'] === 0, 'month beginning on Sunday needs no blanks');
calendar_check(event_calendar([], '2026-12', $now)['next'] === '2027-01', 'December to January navigation');
calendar_check(event_calendar([], '2026-01', $now)['previous'] === '2025-12', 'January to December navigation');
calendar_check(event_calendar([], '1900-01', $now)['previous'] === null, 'minimum year navigation boundary');
calendar_check(event_calendar([], '9999-12', $now)['next'] === null, 'maximum year navigation boundary');
foreach (['2026-13', '2026-00', '2026-2', '<script>', '0999-01', '2026-02-01', '2026-02garbage'] as $invalid) {
    calendar_check(event_calendar([], $invalid, $now)['month'] === '2026-10', 'invalid month falls back safely');
}
$events = [
    ['id' => 1, 'date' => '2026-10-13'], ['id' => 2, 'date' => '2026-11-13'],
    ['id' => 3, 'date' => '2025-10-13'], ['id' => 4, 'date' => '2026-10-13'],
    ['id' => 5, 'date' => '2026-02-30'], ['id' => 6, 'date' => 'not-a-date'],
];
$calendar = event_calendar($events, '2026-10', $now);
calendar_check(array_keys($calendar['events_by_date']) === ['2026-10-13'], 'only exact month and year are marked');
calendar_check(count($calendar['events_by_date']['2026-10-13']) === 2, 'multiple events on a day');
calendar_check(event_calendar($events, '2026-02', $now)['events_by_date'] === [], 'invalid dates do not overflow into another month');
calendar_check(event_calendar_query('2026-11', 'Health & Support') === '?month=2026-11&category=Health%20%26%20Support', 'month navigation preserves and encodes category');
calendar_check(event_calendar_query(null, 'All') === '', 'current month with all categories');
calendar_check(event_calendar_query(null, 'Social') === '?category=Social', 'current month preserves category');
echo "PASS {$checks} calendar regression checks\n";
