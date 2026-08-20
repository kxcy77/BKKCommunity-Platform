<?php

declare(strict_types=1);

function database(): ?PDO
{
    static $connection = false;
    global $config;

    if ($connection instanceof PDO) {
        return $connection;
    }
    if ($connection === null) {
        return null;
    }

    $db = $config['db'];
    if (empty($db['host'])) {
        if (empty($config['allow_demo_mode']) || ($config['app_env'] ?? '') === 'production') {
            error_log('BKK database configuration is missing and demonstration mode is disabled.');
            http_response_code(503);
            exit('The BKK Community service is temporarily unavailable. No information was saved. Please try again later.');
        }
        $connection = null;
        return null;
    }

    try {
        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $db['host'], $db['port'], $db['name']);
        $connection = new PDO($dsn, $db['user'], $db['password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    } catch (PDOException $exception) {
        error_log('BKK database connection failed: ' . $exception->getMessage());
        http_response_code(503);
        exit('The BKK Community service is temporarily unavailable. No information was saved. Please try again later.');
    }

    return $connection;
}

function tone_from_colour(?string $colour): string
{
    return match (strtoupper((string) $colour)) {
        '#315C24', '#315D23' => 'green',
        '#B00020', '#B4232C' => 'red',
        '#BF7600' => 'gold',
        '#007C83' => 'teal',
        default => 'blue',
    };
}

function tone_for_discount(string $category): string
{
    return match (strtolower($category)) {
        'pharmacy' => 'blue',
        'grocery' => 'green',
        'restaurant' => 'red',
        'transport' => 'gold',
        default => 'teal',
    };
}

function tone_for_service(string $type): string
{
    return match (strtolower($type)) {
        'clinic' => 'red',
        'pharmacy' => 'blue',
        'transport' => 'green',
        'support' => 'teal',
        default => 'gold',
    };
}

function is_demonstration_event(array $event): bool
{
    return strcasecmp((string) ($event['category'] ?? ''), 'Demonstration') === 0
        || str_contains(strtolower((string) ($event['title'] ?? '')), 'not a real event')
        || str_contains(strtolower((string) ($event['description'] ?? '')), 'test content only')
        || str_contains(strtolower((string) ($event['location'] ?? '')), 'do not travel');
}

function all_events(): array
{
    $db = database();
    if (!$db) {
        $events = array_values(array_filter(
            $_SESSION['demo_events'] ?? demo_events(),
            static fn (array $event): bool => ($event['status'] ?? 'published') === 'published'
        ));
        usort($events, fn (array $a, array $b): int => strcmp($a['date'] . $a['time'], $b['date'] . $b['time']));
        return array_map(function (array $event): array {
            $event['is_demo'] = is_demonstration_event($event);
            return $event;
        }, $events);
    }

    $rows = $db->query("SELECT e.id, e.title,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%Y-%m-%d') AS date,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%H:%i') AS time,
        DATE_FORMAT(CONVERT_TZ(e.end_at, '+00:00', '+02:00'), '%H:%i') AS end_time,
        e.location, c.name AS category, c.colour_hex, e.description
        FROM events e
        INNER JOIN event_categories c ON c.id = e.category_id
        WHERE e.status = 'published' AND e.end_at >= UTC_TIMESTAMP()
        ORDER BY e.start_at")->fetchAll();
    return array_map(function (array $event): array {
        $event['tone'] = tone_from_colour($event['colour_hex'] ?? null);
        $event['is_demo'] = is_demonstration_event($event);
        unset($event['colour_hex']);
        return $event;
    }, $rows);
}

function all_discounts(): array
{
    $db = database();
    if (!$db) {
        return array_values(array_filter(
            $_SESSION['demo_discounts'] ?? demo_discounts(),
            static fn (array $discount): bool => (bool) ($discount['is_active'] ?? true)
        ));
    }

    $rows = $db->query("SELECT d.id, d.store_name, c.name AS category,
        CONCAT(d.title, ': ', d.details) AS deal,
        d.eligibility, d.claim_instructions
        FROM discounts d
        INNER JOIN discount_categories c ON c.id = d.category_id
        WHERE d.is_active = 1
          AND (d.valid_from IS NULL OR d.valid_from <= CURRENT_DATE)
          AND (d.valid_until IS NULL OR d.valid_until >= CURRENT_DATE)
        ORDER BY d.store_name")->fetchAll();
    return array_map(function (array $discount): array {
        $discount['tone'] = tone_for_discount($discount['category']);
        return $discount;
    }, $rows);
}

function all_services(): array
{
    $db = database();
    if (!$db) {
        return array_values(array_filter(
            $_SESSION['demo_services'] ?? demo_services(),
            static fn (array $service): bool => (bool) ($service['is_active'] ?? true)
        ));
    }

    $rows = $db->query("SELECT id, type, name, phone, address,
        COALESCE(opening_hours, 'Contact the service for opening times') AS hours,
        COALESCE(directions, 'Contact the service for directions and support information.') AS description
        FROM local_services WHERE is_active = 1 ORDER BY type, name")->fetchAll();
    return array_map(function (array $service): array {
        $service['category'] = ucwords(str_replace('_', ' ', $service['type']));
        $service['tone'] = tone_for_service($service['type']);
        unset($service['type']);
        return $service;
    }, $rows);
}

function rsvp_ids_for_current_user(): array
{
    $user = current_user();
    if (!$user) {
        return [];
    }

    $db = database();
    if (!$db || empty($user['id'])) {
        return array_map('intval', $_SESSION['rsvps'] ?? []);
    }

    $statement = $db->prepare("SELECT event_id FROM attendance WHERE user_id = ? AND status = 'attending'");
    $statement->execute([$user['id']]);
    return array_map('intval', array_column($statement->fetchAll(), 'event_id'));
}

function attendance_history_for_current_user(): array
{
    $user = current_user();
    if (!$user) {
        return [];
    }

    $db = database();
    if (!$db || empty($user['id'])) {
        $ids = rsvp_ids_for_current_user();
        return array_values(array_filter(all_events(), fn (array $event): bool => in_array((int) $event['id'], $ids, true)));
    }

    $statement = $db->prepare("SELECT e.id, e.title, e.location, c.name AS category, a.status,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%Y-%m-%d') AS date,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%H:%i') AS time
        FROM attendance a
        INNER JOIN events e ON e.id = a.event_id
        INNER JOIN event_categories c ON c.id = e.category_id
        WHERE a.user_id = ?
        ORDER BY e.start_at DESC");
    $statement->execute([$user['id']]);
    return $statement->fetchAll();
}

function toggle_rsvp(int $eventId): bool
{
    $user = current_user();
    if (!$user) {
        return false;
    }

    $db = database();
    if (!$db || empty($user['id'])) {
        $ids = rsvp_ids_for_current_user();
        if (in_array($eventId, $ids, true)) {
            $_SESSION['rsvps'] = array_values(array_diff($ids, [$eventId]));
            return false;
        }
        $ids[] = $eventId;
        $_SESSION['rsvps'] = array_values(array_unique($ids));
        return true;
    }

    $check = $db->prepare('SELECT id, status FROM attendance WHERE user_id = ? AND event_id = ?');
    $check->execute([$user['id'], $eventId]);
    $existing = $check->fetch();
    if ($existing) {
        $attending = $existing['status'] !== 'attending';
        $update = $db->prepare("UPDATE attendance SET status = ?, confirmed_at = IF(? = 'attending', NOW(), confirmed_at) WHERE id = ?");
        $status = $attending ? 'attending' : 'cancelled';
        $update->execute([$status, $status, $existing['id']]);
        return $attending;
    }

    $insert = $db->prepare('INSERT INTO attendance (user_id, event_id) VALUES (?, ?)');
    $insert->execute([$user['id'], $eventId]);
    return true;
}

function save_contact_message(array $input): void
{
    $db = database();
    if (!$db) {
        $_SESSION['demo_contact_messages'][] = $input + ['submitted_at' => date(DATE_ATOM)];
        return;
    }

    $userId = current_user()['id'] ?? null;
    $statement = $db->prepare('INSERT INTO contact_messages (user_id, name, email, phone, subject, message) VALUES (?, ?, ?, ?, ?, ?)');
    $statement->execute([$userId, $input['name'], $input['email'], $input['phone'], $input['subject'], $input['message']]);
}

function admin_metrics(): array
{
    $db = database();
    if (!$db) {
        return [
            'events' => count(all_events()),
            'discounts' => count(all_discounts()),
            'messages' => count($_SESSION['demo_contact_messages'] ?? []),
            'users' => count(demo_accounts()) + count($_SESSION['demo_registered_users'] ?? []),
        ];
    }
    return [
        'events' => (int) $db->query("SELECT COUNT(*) FROM events WHERE status = 'published' AND end_at >= UTC_TIMESTAMP()")->fetchColumn(),
        'discounts' => (int) $db->query('SELECT COUNT(*) FROM discounts WHERE is_active = 1')->fetchColumn(),
        'messages' => (int) $db->query("SELECT COUNT(*) FROM contact_messages WHERE status = 'new'")->fetchColumn(),
        'users' => (int) $db->query('SELECT COUNT(*) FROM users WHERE deleted_at IS NULL')->fetchColumn(),
    ];
}

function admin_audit_log(string $action, string $entityType, ?int $entityId, ?array $before = null, ?array $after = null, ?string $reason = null): void
{
    $db = database();
    if (!$db) {
        $_SESSION['demo_admin_audit'][] = [
            'id' => count($_SESSION['demo_admin_audit'] ?? []) + 1,
            'admin_name' => current_user()['full_name'] ?? 'Demo administrator',
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'reason' => $reason,
            'created_at' => date('Y-m-d H:i:s'),
        ];
        return;
    }

    $statement = $db->prepare('INSERT INTO admin_audit_log
        (admin_user_id, action, entity_type, entity_id, before_json, after_json, reason)
        VALUES (?, ?, ?, ?, ?, ?, ?)');
    $statement->execute([
        current_user()['id'] ?? null,
        mb_substr($action, 0, 80),
        mb_substr($entityType, 0, 50),
        $entityId,
        $before === null ? null : json_encode($before, JSON_INVALID_UTF8_SUBSTITUTE),
        $after === null ? null : json_encode($after, JSON_INVALID_UTF8_SUBSTITUTE),
        $reason === null ? null : mb_substr($reason, 0, 255),
    ]);
}

function admin_recent_audit_log(int $limit = 100): array
{
    $limit = max(1, min(100, $limit));
    $db = database();
    if (!$db) {
        return array_reverse(array_slice($_SESSION['demo_admin_audit'] ?? [], -$limit));
    }

    $statement = $db->prepare('SELECT a.id, a.action, a.entity_type, a.entity_id, a.reason, a.created_at,
        COALESCE(u.full_name, \'Former administrator\') AS admin_name
        FROM admin_audit_log a LEFT JOIN users u ON u.id = a.admin_user_id
        ORDER BY a.created_at DESC, a.id DESC LIMIT ?');
    $statement->bindValue(1, $limit, PDO::PARAM_INT);
    $statement->execute();
    return $statement->fetchAll();
}

function admin_all_events(): array
{
    $db = database();
    if (!$db) {
        $events = $_SESSION['demo_events'] ?? demo_events();
        return array_map(static fn (array $event): array => $event + ['directions' => '', 'status' => 'published', 'version' => 'demo-1'], $events);
    }

    return $db->query("SELECT e.id, e.title, e.description, e.location, e.directions, e.status,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%Y-%m-%d') AS date,
        DATE_FORMAT(CONVERT_TZ(e.start_at, '+00:00', '+02:00'), '%H:%i') AS time,
        DATE_FORMAT(CONVERT_TZ(e.end_at, '+00:00', '+02:00'), '%H:%i') AS end_time,
        c.name AS category, c.colour_hex, e.row_version AS version
        FROM events e INNER JOIN event_categories c ON c.id = e.category_id
        ORDER BY e.status = 'published' DESC, e.start_at DESC")->fetchAll();
}

function admin_get_event(int $eventId): ?array
{
    foreach (admin_all_events() as $event) {
        if ((int) $event['id'] === $eventId) {
            $event['tone'] = $event['tone'] ?? tone_from_colour($event['colour_hex'] ?? null);
            return $event;
        }
    }
    return null;
}

function admin_event_category_id(PDO $db, string $name, string $tone): int
{
    $colour = match ($tone) {
        'green' => '#315C24', 'teal' => '#007C83', 'red' => '#B00020', 'gold' => '#BF7600', default => '#2E75B6',
    };
    $category = $db->prepare('SELECT id FROM event_categories WHERE name = ? LIMIT 1');
    $category->execute([$name]);
    $categoryId = $category->fetchColumn();
    if (!$categoryId) {
        $db->prepare('INSERT INTO event_categories (name, colour_hex) VALUES (?, ?)')->execute([$name, $colour]);
        $categoryId = (int) $db->lastInsertId();
    }
    return (int) $categoryId;
}

function admin_event_datetimes(array $event): array
{
    $localZone = new DateTimeZone('Africa/Johannesburg');
    $utcZone = new DateTimeZone('UTC');
    $start = new DateTimeImmutable($event['date'] . ' ' . $event['time'], $localZone);
    $end = new DateTimeImmutable($event['date'] . ' ' . $event['end_time'], $localZone);
    return [$start->setTimezone($utcZone)->format('Y-m-d H:i:s'), $end->setTimezone($utcZone)->format('Y-m-d H:i:s')];
}

function admin_create_event(array $event): int
{
    $db = database();
    if (!$db) {
        $events = $_SESSION['demo_events'] ?? demo_events();
        $event['id'] = $events ? max(array_map('intval', array_column($events, 'id'))) + 1 : 1;
        $event['status'] = 'published';
        $event['version'] = 'demo-' . hrtime(true);
        $events[] = $event;
        $_SESSION['demo_events'] = $events;
        admin_audit_log('create', 'event', (int) $event['id'], null, $event);
        return (int) $event['id'];
    }

    $db->beginTransaction();
    try {
        $categoryId = admin_event_category_id($db, $event['category'], $event['tone']);
        [$startAt, $endAt] = admin_event_datetimes($event);
        $statement = $db->prepare("INSERT INTO events (category_id, title, description, start_at, end_at, location, directions, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'published')");
        $statement->execute([$categoryId, $event['title'], $event['description'], $startAt, $endAt, $event['location'], $event['directions'] ?: null]);
        $eventId = (int) $db->lastInsertId();
        admin_audit_log('create', 'event', $eventId, null, $event + ['status' => 'published']);
        $db->commit();
        return $eventId;
    } catch (Throwable $exception) {
        $db->rollBack();
        throw $exception;
    }
}

function admin_update_event(int $eventId, array $event): bool
{
    $before = admin_get_event($eventId);
    if (!$before) {
        return false;
    }
    $db = database();
    if (!$db) {
        $events = admin_all_events();
        foreach ($events as &$row) {
            if ((int) $row['id'] === $eventId) {
                if (!hash_equals((string) ($row['version'] ?? ''), (string) ($event['version'] ?? ''))) {
                    return false;
                }
                $row = array_merge($row, $event, ['id' => $eventId, 'version' => 'demo-' . hrtime(true)]);
                break;
            }
        }
        unset($row);
        $_SESSION['demo_events'] = $events;
        admin_audit_log('update', 'event', $eventId, $before, $event);
        return true;
    }

    $db->beginTransaction();
    try {
        $categoryId = admin_event_category_id($db, $event['category'], $event['tone']);
        [$startAt, $endAt] = admin_event_datetimes($event);
        $statement = $db->prepare('UPDATE events SET category_id = ?, title = ?, description = ?, start_at = ?, end_at = ?, location = ?, directions = ?, row_version = row_version + 1 WHERE id = ? AND row_version = ?');
        $statement->execute([$categoryId, $event['title'], $event['description'], $startAt, $endAt, $event['location'], $event['directions'] ?: null, $eventId, $event['version']]);
        if ($statement->rowCount() !== 1) {
            $db->rollBack();
            return false;
        }
        admin_audit_log('update', 'event', $eventId, $before, $event);
        $db->commit();
        return true;
    } catch (Throwable $exception) {
        $db->rollBack();
        throw $exception;
    }
}

function admin_set_event_archived(int $eventId, bool $archived, string $reason): bool
{
    $before = admin_get_event($eventId);
    if (!$before) {
        return false;
    }
    $status = $archived ? 'cancelled' : 'published';
    $db = database();
    if (!$db) {
        $events = admin_all_events();
        foreach ($events as &$event) {
            if ((int) $event['id'] === $eventId) {
                $event['status'] = $status;
                $event['version'] = 'demo-' . hrtime(true);
                break;
            }
        }
        unset($event);
        $_SESSION['demo_events'] = $events;
    } else {
        $db->prepare('UPDATE events SET status = ?, row_version = row_version + 1 WHERE id = ?')->execute([$status, $eventId]);
    }
    admin_audit_log($archived ? 'archive' : 'restore', 'event', $eventId, $before, ['status' => $status], $reason);
    return true;
}

function admin_all_discounts(): array
{
    $db = database();
    if (!$db) {
        return array_map(static fn (array $discount): array => $discount + ['valid_from' => '', 'valid_until' => '', 'is_active' => 1, 'version' => 'demo-1'], $_SESSION['demo_discounts'] ?? demo_discounts());
    }

    return $db->query('SELECT d.id, d.store_name, d.title, d.details AS deal, d.eligibility,
        d.claim_instructions, d.valid_from, d.valid_until, d.is_active, c.name AS category,
        d.row_version AS version
        FROM discounts d INNER JOIN discount_categories c ON c.id = d.category_id
        ORDER BY d.is_active DESC, d.updated_at DESC, d.store_name')->fetchAll();
}

function admin_get_discount(int $discountId): ?array
{
    foreach (admin_all_discounts() as $discount) {
        if ((int) $discount['id'] === $discountId) {
            $discount['tone'] = tone_for_discount((string) $discount['category']);
            return $discount;
        }
    }
    return null;
}

function admin_discount_category_id(PDO $db, string $name): int
{
    $category = $db->prepare('SELECT id FROM discount_categories WHERE name = ? LIMIT 1');
    $category->execute([$name]);
    $categoryId = $category->fetchColumn();
    if (!$categoryId) {
        $db->prepare('INSERT INTO discount_categories (name) VALUES (?)')->execute([$name]);
        $categoryId = (int) $db->lastInsertId();
    }
    return (int) $categoryId;
}

function admin_create_discount(array $discount): int
{
    $db = database();
    if (!$db) {
        $discounts = $_SESSION['demo_discounts'] ?? demo_discounts();
        $discount['id'] = $discounts ? max(array_map('intval', array_column($discounts, 'id'))) + 1 : 1;
        $discount['is_active'] = 1;
        $discount['version'] = 'demo-' . hrtime(true);
        $discounts[] = $discount;
        $_SESSION['demo_discounts'] = $discounts;
        admin_audit_log('create', 'discount', (int) $discount['id'], null, $discount);
        return (int) $discount['id'];
    }

    $categoryId = admin_discount_category_id($db, $discount['category']);
    $title = mb_substr($discount['deal'], 0, 190);
    $statement = $db->prepare('INSERT INTO discounts (category_id, store_name, title, details, eligibility, claim_instructions, valid_from, valid_until, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)');
    $statement->execute([$categoryId, $discount['store_name'], $title, $discount['deal'], $discount['eligibility'], $discount['claim_instructions'], $discount['valid_from'] ?: null, $discount['valid_until'] ?: null]);
    $discountId = (int) $db->lastInsertId();
    admin_audit_log('create', 'discount', $discountId, null, $discount + ['is_active' => 1]);
    return $discountId;
}

function admin_update_discount(int $discountId, array $discount): bool
{
    $before = admin_get_discount($discountId);
    if (!$before) {
        return false;
    }
    $db = database();
    if (!$db) {
        $discounts = admin_all_discounts();
        foreach ($discounts as &$row) {
            if ((int) $row['id'] === $discountId) {
                if (!hash_equals((string) ($row['version'] ?? ''), (string) ($discount['version'] ?? ''))) {
                    return false;
                }
                $row = array_merge($row, $discount, ['id' => $discountId, 'version' => 'demo-' . hrtime(true)]);
                break;
            }
        }
        unset($row);
        $_SESSION['demo_discounts'] = $discounts;
        admin_audit_log('update', 'discount', $discountId, $before, $discount);
        return true;
    }

    $categoryId = admin_discount_category_id($db, $discount['category']);
    $statement = $db->prepare('UPDATE discounts SET category_id = ?, store_name = ?, title = ?, details = ?, eligibility = ?, claim_instructions = ?, valid_from = ?, valid_until = ?, row_version = row_version + 1 WHERE id = ? AND row_version = ?');
    $statement->execute([$categoryId, $discount['store_name'], mb_substr($discount['deal'], 0, 190), $discount['deal'], $discount['eligibility'], $discount['claim_instructions'], $discount['valid_from'] ?: null, $discount['valid_until'] ?: null, $discountId, $discount['version']]);
    if ($statement->rowCount() !== 1) {
        return false;
    }
    admin_audit_log('update', 'discount', $discountId, $before, $discount);
    return true;
}

function admin_set_discount_archived(int $discountId, bool $archived, string $reason): bool
{
    $before = admin_get_discount($discountId);
    if (!$before) {
        return false;
    }
    $active = $archived ? 0 : 1;
    $db = database();
    if (!$db) {
        $discounts = admin_all_discounts();
        foreach ($discounts as &$discount) {
            if ((int) $discount['id'] === $discountId) {
                $discount['is_active'] = $active;
                $discount['version'] = 'demo-' . hrtime(true);
                break;
            }
        }
        unset($discount);
        $_SESSION['demo_discounts'] = $discounts;
    } else {
        $db->prepare('UPDATE discounts SET is_active = ?, row_version = row_version + 1 WHERE id = ?')->execute([$active, $discountId]);
    }
    admin_audit_log($archived ? 'archive' : 'restore', 'discount', $discountId, $before, ['is_active' => $active], $reason);
    return true;
}

function admin_contact_messages(int $page = 1, int $perPage = 25, string $search = '', string $status = ''): array
{
    $page = max(1, $page);
    $perPage = max(10, min(50, $perPage));
    $search = mb_substr(trim($search), 0, 100);
    $status = in_array($status, ['new', 'read', 'resolved'], true) ? $status : '';
    $db = database();
    if (!$db) {
        $messages = array_reverse(array_map(static function (array $message, int $index): array {
            return $message + ['id' => $index + 1, 'status' => 'new'];
        }, $_SESSION['demo_contact_messages'] ?? [], array_keys($_SESSION['demo_contact_messages'] ?? [])));
        $messages = array_values(array_filter($messages, static function (array $message) use ($search, $status): bool {
            $matchesStatus = $status === '' || ($message['status'] ?? 'new') === $status;
            $haystack = strtolower(implode(' ', [$message['name'] ?? '', $message['email'] ?? '', $message['subject'] ?? '']));
            return $matchesStatus && ($search === '' || str_contains($haystack, strtolower($search)));
        }));
        $total = count($messages);
        return ['items' => array_slice($messages, ($page - 1) * $perPage, $perPage), 'total' => $total, 'page' => $page, 'pages' => max(1, (int) ceil($total / $perPage))];
    }

    $where = [];
    $parameters = [];
    if ($status !== '') {
        $where[] = 'status = ?';
        $parameters[] = $status;
    }
    if ($search !== '') {
        $where[] = '(name LIKE ? OR email LIKE ? OR subject LIKE ?)';
        $term = '%' . $search . '%';
        array_push($parameters, $term, $term, $term);
    }
    $whereSql = $where ? ' WHERE ' . implode(' AND ', $where) : '';
    $count = $db->prepare('SELECT COUNT(*) FROM contact_messages' . $whereSql);
    $count->execute($parameters);
    $total = (int) $count->fetchColumn();
    $pages = max(1, (int) ceil($total / $perPage));
    $page = min($page, $pages);
    $statement = $db->prepare('SELECT id, name, email, phone, subject, message, status, submitted_at FROM contact_messages' . $whereSql . ' ORDER BY submitted_at DESC LIMIT ? OFFSET ?');
    $position = 1;
    foreach ($parameters as $parameter) {
        $statement->bindValue($position++, $parameter, PDO::PARAM_STR);
    }
    $statement->bindValue($position++, $perPage, PDO::PARAM_INT);
    $statement->bindValue($position, ($page - 1) * $perPage, PDO::PARAM_INT);
    $statement->execute();
    return ['items' => $statement->fetchAll(), 'total' => $total, 'page' => $page, 'pages' => $pages];
}

function admin_update_contact_status(int $messageId, string $status): bool
{
    if (!in_array($status, ['new', 'read', 'resolved'], true)) {
        return false;
    }

    $db = database();
    if (!$db) {
        $index = $messageId - 1;
        if (!isset($_SESSION['demo_contact_messages'][$index])) {
            return false;
        }
        $_SESSION['demo_contact_messages'][$index]['status'] = $status;
        admin_audit_log('status_update', 'contact_message', $messageId, null, ['status' => $status]);
        return true;
    }

    $statement = $db->prepare('UPDATE contact_messages SET status = ? WHERE id = ?');
    $statement->execute([$status, $messageId]);
    $exists = $statement->rowCount() === 1;
    if (!$exists) {
        $check = $db->prepare('SELECT COUNT(*) FROM contact_messages WHERE id = ? AND status = ?');
        $check->execute([$messageId, $status]);
        $exists = (int) $check->fetchColumn() === 1;
    }
    if ($exists) {
        admin_audit_log('status_update', 'contact_message', $messageId, null, ['status' => $status]);
    }
    return $exists;
}

function admin_all_services(): array
{
    $db = database();
    if (!$db) {
        return array_map(static function (array $service): array {
            $type = strtolower((string) ($service['type'] ?? $service['category'] ?? 'support'));
            if (!in_array($type, ['pharmacy', 'clinic', 'shop', 'support', 'transport'], true)) {
                $type = 'support';
            }
            return $service + [
                'type' => $type,
                'directions' => $service['description'] ?? '',
                'opening_hours' => $service['hours'] ?? '',
                'is_active' => 1,
                'version' => 'demo-1',
            ];
        }, $_SESSION['demo_services'] ?? demo_services());
    }

    return $db->query("SELECT id, type, name, address, phone, directions, opening_hours, is_active,
        row_version AS version
        FROM local_services ORDER BY is_active DESC, type, name")->fetchAll();
}

function admin_get_service(int $serviceId): ?array
{
    foreach (admin_all_services() as $service) {
        if ((int) $service['id'] === $serviceId) {
            return $service;
        }
    }
    return null;
}

function admin_create_service(array $service): int
{
    $db = database();
    if (!$db) {
        $services = $_SESSION['demo_services'] ?? demo_services();
        $service['id'] = $services ? max(array_map('intval', array_column($services, 'id'))) + 1 : 1;
        $service['category'] = ucwords($service['type']);
        $service['description'] = $service['directions'];
        $service['hours'] = $service['opening_hours'];
        $service['tone'] = tone_for_service($service['type']);
        $service['is_active'] = 1;
        $service['version'] = 'demo-' . hrtime(true);
        $services[] = $service;
        $_SESSION['demo_services'] = $services;
        admin_audit_log('create', 'local_service', (int) $service['id'], null, $service);
        return (int) $service['id'];
    }

    $statement = $db->prepare('INSERT INTO local_services (type, name, address, phone, directions, opening_hours, is_active) VALUES (?, ?, ?, ?, ?, ?, 1)');
    $statement->execute([$service['type'], $service['name'], $service['address'], $service['phone'], $service['directions'], $service['opening_hours']]);
    $serviceId = (int) $db->lastInsertId();
    admin_audit_log('create', 'local_service', $serviceId, null, $service + ['is_active' => 1]);
    return $serviceId;
}

function admin_update_service(int $serviceId, array $service): bool
{
    $before = admin_get_service($serviceId);
    if (!$before) {
        return false;
    }
    $db = database();
    if (!$db) {
        $services = admin_all_services();
        foreach ($services as &$row) {
            if ((int) $row['id'] === $serviceId) {
                if (!hash_equals((string) ($row['version'] ?? ''), (string) ($service['version'] ?? ''))) {
                    return false;
                }
                $row = array_merge($row, $service, ['id' => $serviceId, 'version' => 'demo-' . hrtime(true)]);
                break;
            }
        }
        unset($row);
        $_SESSION['demo_services'] = $services;
        admin_audit_log('update', 'local_service', $serviceId, $before, $service);
        return true;
    }

    $statement = $db->prepare('UPDATE local_services SET type = ?, name = ?, address = ?, phone = ?, directions = ?, opening_hours = ?, row_version = row_version + 1 WHERE id = ? AND row_version = ?');
    $statement->execute([$service['type'], $service['name'], $service['address'], $service['phone'], $service['directions'], $service['opening_hours'], $serviceId, $service['version']]);
    if ($statement->rowCount() !== 1) {
        return false;
    }
    admin_audit_log('update', 'local_service', $serviceId, $before, $service);
    return true;
}

function admin_set_service_archived(int $serviceId, bool $archived, string $reason): bool
{
    $before = admin_get_service($serviceId);
    if (!$before) {
        return false;
    }
    $active = $archived ? 0 : 1;
    $db = database();
    if (!$db) {
        $services = admin_all_services();
        foreach ($services as &$service) {
            if ((int) $service['id'] === $serviceId) {
                $service['is_active'] = $active;
                $service['version'] = 'demo-' . hrtime(true);
                break;
            }
        }
        unset($service);
        $_SESSION['demo_services'] = $services;
    } else {
        $db->prepare('UPDATE local_services SET is_active = ?, row_version = row_version + 1 WHERE id = ?')->execute([$active, $serviceId]);
    }
    admin_audit_log($archived ? 'archive' : 'restore', 'local_service', $serviceId, $before, ['is_active' => $active], $reason);
    return true;
}
