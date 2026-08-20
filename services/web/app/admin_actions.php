<?php

declare(strict_types=1);

function admin_text_length(string $value, int $minimum, int $maximum): bool
{
    $length = mb_strlen($value);
    return $length >= $minimum && $length <= $maximum;
}

function admin_valid_optional_date(string $value): bool
{
    if ($value === '') {
        return true;
    }
    $date = DateTimeImmutable::createFromFormat('!Y-m-d', $value);
    return $date !== false && $date->format('Y-m-d') === $value;
}

function admin_failed_change(Throwable $exception, string $returnTo): never
{
    $reference = bin2hex(random_bytes(4));
    error_log("BKK administrator action failed [{$reference}]: " . get_class($exception) . ': ' . $exception->getMessage());
    flash('error', "The change could not be saved. Nothing was reported as successful. Reference: {$reference}");
    redirect_to($returnTo);
}

function admin_event_input(): array
{
    return [
        'title' => trim((string) ($_POST['title'] ?? '')),
        'date' => trim((string) ($_POST['date'] ?? '')),
        'time' => trim((string) ($_POST['time'] ?? '')),
        'end_time' => trim((string) ($_POST['end_time'] ?? '')),
        'location' => trim((string) ($_POST['location'] ?? '')),
        'category' => trim((string) ($_POST['category'] ?? '')),
        'tone' => trim((string) ($_POST['tone'] ?? 'blue')),
        'description' => trim((string) ($_POST['description'] ?? '')),
        'directions' => trim((string) ($_POST['directions'] ?? '')),
        'version' => trim((string) ($_POST['version'] ?? '')),
    ];
}

function admin_event_input_valid(array $event, bool $mustBeFuture): bool
{
    $start = DateTimeImmutable::createFromFormat('!Y-m-d H:i', $event['date'] . ' ' . $event['time']);
    $end = DateTimeImmutable::createFromFormat('!Y-m-d H:i', $event['date'] . ' ' . $event['end_time']);
    $exactStart = $start && $start->format('Y-m-d H:i') === $event['date'] . ' ' . $event['time'];
    $exactEnd = $end && $end->format('Y-m-d H:i') === $event['date'] . ' ' . $event['end_time'];
    return admin_text_length($event['title'], 3, 160)
        && $exactStart && $exactEnd && $end > $start
        && (!$mustBeFuture || $start > new DateTimeImmutable('now'))
        && admin_text_length($event['location'], 3, 190)
        && admin_text_length($event['description'], 10, 5000)
        && mb_strlen($event['directions']) <= 2000
        && in_array($event['category'], ['Community', 'Wellness', 'Social', 'Health', 'Support'], true)
        && in_array($event['tone'], ['blue', 'green', 'teal', 'red', 'gold'], true);
}

function admin_discount_input(): array
{
    return [
        'store_name' => trim((string) ($_POST['store_name'] ?? '')),
        'category' => trim((string) ($_POST['category'] ?? '')),
        'deal' => trim((string) ($_POST['deal'] ?? '')),
        'eligibility' => trim((string) ($_POST['eligibility'] ?? '')),
        'claim_instructions' => trim((string) ($_POST['claim_instructions'] ?? '')),
        'tone' => trim((string) ($_POST['tone'] ?? 'gold')),
        'valid_from' => trim((string) ($_POST['valid_from'] ?? '')),
        'valid_until' => trim((string) ($_POST['valid_until'] ?? '')),
        'version' => trim((string) ($_POST['version'] ?? '')),
    ];
}

function admin_discount_input_valid(array $discount): bool
{
    return admin_text_length($discount['store_name'], 2, 160)
        && in_array($discount['category'], ['Pharmacy', 'Grocery', 'Restaurant', 'Transport'], true)
        && admin_text_length($discount['deal'], 5, 5000)
        && admin_text_length($discount['eligibility'], 3, 255)
        && admin_text_length($discount['claim_instructions'], 5, 2000)
        && in_array($discount['tone'], ['blue', 'green', 'teal', 'red', 'gold'], true)
        && admin_valid_optional_date($discount['valid_from'])
        && admin_valid_optional_date($discount['valid_until'])
        && ($discount['valid_from'] === '' || $discount['valid_until'] === '' || $discount['valid_until'] >= $discount['valid_from']);
}

function admin_service_input(): array
{
    return [
        'type' => trim((string) ($_POST['type'] ?? '')),
        'name' => trim((string) ($_POST['name'] ?? '')),
        'address' => trim((string) ($_POST['address'] ?? '')),
        'phone' => trim((string) ($_POST['phone'] ?? '')),
        'directions' => trim((string) ($_POST['directions'] ?? '')),
        'opening_hours' => trim((string) ($_POST['opening_hours'] ?? '')),
        'version' => trim((string) ($_POST['version'] ?? '')),
    ];
}

function admin_service_input_valid(array $service): bool
{
    return in_array($service['type'], ['pharmacy', 'clinic', 'shop', 'support', 'transport'], true)
        && admin_text_length($service['name'], 2, 160)
        && admin_text_length($service['address'], 4, 255)
        && preg_match('/^[0-9+() .-]{5,30}$/', $service['phone']) === 1
        && admin_text_length($service['directions'], 5, 2000)
        && admin_text_length($service['opening_hours'], 3, 190);
}

if (in_array($action, ['admin_delete_event', 'admin_delete_discount', 'admin_delete_service'], true)) {
    require_admin();
    flash('error', 'Permanent deletion is disabled. Use the audited archive action instead.');
    $target = match ($action) {
        'admin_delete_event' => 'admin/events.php',
        'admin_delete_discount' => 'admin/discounts.php',
        default => 'admin/services.php',
    };
    redirect_to($target);
}

if (in_array($action, ['admin_create_event', 'admin_update_event'], true)) {
    require_admin();
    $event = admin_event_input();
    $eventId = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $updating = $action === 'admin_update_event';
    if (($updating && (!$eventId || $event['version'] === '')) || !admin_event_input_valid($event, !$updating)) {
        flash('error', 'The event information is invalid. Check the dates, categories and text limits.');
        redirect_to('admin/events.php' . ($eventId ? '?edit=' . (int) $eventId : ''));
    }
    try {
        $saved = $updating ? admin_update_event((int) $eventId, $event) : (admin_create_event($event) > 0);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/events.php' . ($eventId ? '?edit=' . (int) $eventId : ''));
    }
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The event was updated.' : 'The event was added.') : 'The event changed in another session or could not be found. Reload it before trying again.');
    redirect_to('admin/events.php');
}

if ($action === 'admin_set_event_archived') {
    require_admin();
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $archive = ($_POST['archived'] ?? '') === '1';
    $reason = trim((string) ($_POST['reason'] ?? ''));
    if (!$id || !admin_text_length($reason, 5, 255)) {
        flash('error', 'Enter a reason of 5 to 255 characters.');
        redirect_to('admin/events.php');
    }
    try {
        $saved = admin_set_event_archived((int) $id, $archive, $reason);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/events.php');
    }
    flash($saved ? 'success' : 'error', $saved ? ($archive ? 'The event was archived.' : 'The event was restored.') : 'That event could not be found.');
    redirect_to('admin/events.php');
}

if (in_array($action, ['admin_create_discount', 'admin_update_discount'], true)) {
    require_admin();
    $discount = admin_discount_input();
    $discountId = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $updating = $action === 'admin_update_discount';
    if (($updating && (!$discountId || $discount['version'] === '')) || !admin_discount_input_valid($discount)) {
        flash('error', 'The discount information is invalid. Check categories, dates and text limits.');
        redirect_to('admin/discounts.php' . ($discountId ? '?edit=' . (int) $discountId : ''));
    }
    try {
        $saved = $updating ? admin_update_discount((int) $discountId, $discount) : (admin_create_discount($discount) > 0);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/discounts.php' . ($discountId ? '?edit=' . (int) $discountId : ''));
    }
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The discount was updated.' : 'The discount was added.') : 'The discount changed in another session or could not be found. Reload it before trying again.');
    redirect_to('admin/discounts.php');
}

if ($action === 'admin_set_discount_archived') {
    require_admin();
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $archive = ($_POST['archived'] ?? '') === '1';
    $reason = trim((string) ($_POST['reason'] ?? ''));
    if (!$id || !admin_text_length($reason, 5, 255)) {
        flash('error', 'Enter a reason of 5 to 255 characters.');
        redirect_to('admin/discounts.php');
    }
    try {
        $saved = admin_set_discount_archived((int) $id, $archive, $reason);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/discounts.php');
    }
    flash($saved ? 'success' : 'error', $saved ? ($archive ? 'The discount was archived.' : 'The discount was restored.') : 'That discount could not be found.');
    redirect_to('admin/discounts.php');
}

if (in_array($action, ['admin_create_service', 'admin_update_service'], true)) {
    require_admin();
    $service = admin_service_input();
    $serviceId = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $updating = $action === 'admin_update_service';
    if (($updating && (!$serviceId || $service['version'] === '')) || !admin_service_input_valid($service)) {
        flash('error', 'The local-service information is invalid. Check the phone number and text limits.');
        redirect_to('admin/services.php' . ($serviceId ? '?edit=' . (int) $serviceId : ''));
    }
    try {
        $saved = $updating ? admin_update_service((int) $serviceId, $service) : (admin_create_service($service) > 0);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/services.php' . ($serviceId ? '?edit=' . (int) $serviceId : ''));
    }
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The local service was updated.' : 'The local service was added.') : 'The local service changed in another session or could not be found. Reload it before trying again.');
    redirect_to('admin/services.php');
}

if ($action === 'admin_set_service_archived') {
    require_admin();
    $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
    $archive = ($_POST['archived'] ?? '') === '1';
    $reason = trim((string) ($_POST['reason'] ?? ''));
    if (!$id || !admin_text_length($reason, 5, 255)) {
        flash('error', 'Enter a reason of 5 to 255 characters.');
        redirect_to('admin/services.php');
    }
    try {
        $saved = admin_set_service_archived((int) $id, $archive, $reason);
    } catch (Throwable $exception) {
        admin_failed_change($exception, 'admin/services.php');
    }
    flash($saved ? 'success' : 'error', $saved ? ($archive ? 'The local service was archived.' : 'The local service was restored.') : 'That local service could not be found.');
    redirect_to('admin/services.php');
}
