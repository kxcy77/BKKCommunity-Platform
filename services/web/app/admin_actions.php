<?php

declare(strict_types=1);

// Enforce permissions for direct/forged POSTs before parsing action inputs.
if (str_starts_with($action, 'admin_')) {
    require_permission(match ($action) {
        'admin_update_message' => 'messages',
        'admin_invite_staff', 'admin_change_staff', 'admin_revoke_invitation' => 'staff',
        default => 'content.write',
    });
}

if (in_array($action, ['admin_invite_staff', 'admin_change_staff', 'admin_revoke_invitation'], true)) {
    if (persistent_rate_limit_exceeded('staff-security-change', 10, 900, (string) current_user()['id'])) {
        flash('error', 'Too many staff access attempts. Wait 15 minutes before trying again.');
        redirect_to('admin/staff.php');
    }
    $reason = staff_post_text('reason');
    $currentPassword = is_string($_POST['current_password'] ?? null) ? $_POST['current_password'] : '';
    if (mb_strlen($reason) < 5 || mb_strlen($reason) > 255 || !staff_confirm_password($currentPassword)) {
        flash('error', 'Enter your current password and a reason of 5 to 255 characters.');
        redirect_to('admin/staff.php');
    }
    try {
        if ($action === 'admin_invite_staff') {
            $email = strtolower(staff_post_text('email'));
            $code = staff_create_invitation($email, staff_post_text('staff_level'), $reason);
            $_SESSION['new_staff_invitation'] = ['email' => $email, 'code' => $code];
        } elseif ($action === 'admin_change_staff') {
            $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
            $version = filter_var($_POST['version'] ?? null, FILTER_VALIDATE_INT);
            if (!$id || !$version) throw new DomainException('Reload the staff list and try again.');
            staff_set_access((int) $id, staff_post_text('staff_level'), (int) $version, $reason);
            if ((int) current_user()['id'] === (int) $id) {
                logout_user();
                flash('success', 'Your staff access changed. Sign in again.');
                redirect_to('login.php');
            }
        } else {
            $id = filter_var($_POST['id'] ?? null, FILTER_VALIDATE_INT);
            if (!$id) throw new DomainException('Choose a valid invitation.');
            staff_revoke_invitation((int) $id, $reason);
        }
        flash('success', 'The staff access change was saved and recorded in the audit history.');
    } catch (DomainException $e) {
        flash('error', $e->getMessage());
    } catch (Throwable $e) {
        admin_failed_change($e, 'admin/staff.php');
    }
    redirect_to('admin/staff.php');
}

if ($action === 'accept_staff_invitation') {
    require_login();
    if (persistent_rate_limit_exceeded('staff-invitation-accept', 8, 900, (string) current_user()['id'])) {
        flash('error', 'Too many invitation attempts. Wait 15 minutes before trying again.');
        redirect_to('staff-invitation.php');
    }
    try {
        staff_accept_invitation(staff_post_text('invitation_code'));
        logout_user();
        flash('success', 'Staff invitation accepted. Sign in again to use your new access.');
        redirect_to('login.php');
    } catch (DomainException $e) {
        flash('error', $e->getMessage());
    } catch (Throwable $e) {
        admin_failed_change($e, 'staff-invitation.php');
    }
    redirect_to('staff-invitation.php');
}

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
        && in_array($event['category'], admin_event_category_names(), true)
        && in_array($event['tone'], ['blue', 'green', 'teal', 'red', 'gold'], true);
}

function admin_discount_input(): array
{
    return [
        'store_name' => trim((string) ($_POST['store_name'] ?? '')),
        'category' => trim((string) ($_POST['category'] ?? '')),
        'title' => trim((string) ($_POST['title'] ?? $_POST['deal'] ?? '')),
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
        && admin_text_length($discount['title'], 3, 190)
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
    $visibility = ($event['date'] . ' ' . $event['end_time'] < date('Y-m-d H:i'))
        ? ' Past events are hidden from upcoming events.'
        : ' Published upcoming events appear on the website and in the Android app after its next refresh (normally within 30 seconds online). Draft or archived events remain hidden.';
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The event was updated.' : 'The event was added.') . $visibility : 'The event changed in another session or could not be found. Reload it before trying again.');
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
    $visibility = ' Active discounts appear on the website and in the Android app after its next refresh (normally within 30 seconds online). Archived offers and offers outside their validity dates remain hidden.';
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The discount was updated.' : 'The discount was added.') . $visibility : 'The discount changed in another session or could not be found. Reload it before trying again.');
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
    flash($saved ? 'success' : 'error', $saved ? ($updating ? 'The local service was updated.' : 'The local service was added.') . ' Active services appear on the website and in the Android app after its next refresh (normally within 30 seconds online). Archived services remain hidden.' : 'The local service changed in another session or could not be found. Reload it before trying again.');
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
