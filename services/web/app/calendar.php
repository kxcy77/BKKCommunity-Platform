<?php

declare(strict_types=1);

/** Build a calendar from full event dates, using the community's time zone. */
function event_calendar(array $events, ?string $requestedMonth = null, ?DateTimeImmutable $now = null): array
{
    $zone = new DateTimeZone('Africa/Johannesburg');
    $today = ($now ?? new DateTimeImmutable('now', $zone))->setTimezone($zone);
    $month = $today->modify('first day of this month')->setTime(0, 0);
    if ($requestedMonth !== null && preg_match('/^(19\d{2}|[2-9]\d{3})-(0[1-9]|1[0-2])$/D', $requestedMonth)) {
        $parsed = DateTimeImmutable::createFromFormat('!Y-m', $requestedMonth, $zone);
        if ($parsed !== false && $parsed->format('Y-m') === $requestedMonth) {
            $month = $parsed;
        }
    }

    $eventsByDate = [];
    foreach ($events as $event) {
        $date = $event['date'] ?? null;
        if (!is_string($date) || !preg_match('/^\d{4}-\d{2}-\d{2}$/D', $date)) {
            continue;
        }
        $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date, $zone);
        if ($parsed !== false && $parsed->format('Y-m-d') === $date && $parsed->format('Y-m') === $month->format('Y-m')) {
            $eventsByDate[$date][] = $event;
        }
    }

    return [
        'month' => $month->format('Y-m'),
        'label' => $month->format('F Y'),
        'previous' => $month->format('Y-m') === '1900-01' ? null : $month->modify('-1 month')->format('Y-m'),
        'next' => $month->format('Y-m') === '9999-12' ? null : $month->modify('+1 month')->format('Y-m'),
        'offset' => (int) $month->format('w'),
        'days' => (int) $month->format('t'),
        'today' => $today->format('Y-m-d'),
        'events_by_date' => $eventsByDate,
    ];
}

function event_calendar_query(?string $month, string $category): string
{
    $query = [];
    if ($month !== null) {
        $query['month'] = $month;
    }
    if ($category !== 'All') {
        $query['category'] = $category;
    }
    return $query === [] ? '' : '?' . http_build_query($query, '', '&', PHP_QUERY_RFC3986);
}
