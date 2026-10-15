<?php
declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/app/bootstrap.php';
require_admin(($_SERVER['HTTP_X_BKK_DIRECTORY_POLL'] ?? '') !== '1');
header('Cache-Control: no-store, private');
$pageTitle = 'Registered users';
$bodyClass = 'admin-page';
$activeNav = 'admin';
$adminPage = 'users';
$search = is_string($_GET['search'] ?? '') ? mb_substr(trim($_GET['search'] ?? ''), 0, 100) : '';
$platform = is_string($_GET['platform'] ?? '') ? ($_GET['platform'] ?? '') : '';
$platforms = ['website' => 'Website', 'android' => 'Android', 'unknown' => 'Unknown / legacy'];
if (!isset($platforms[$platform])) $platform = '';
$page = filter_var($_GET['page'] ?? 1, FILTER_VALIDATE_INT) ?: 1;
$result = admin_registered_users($page, $search, $platform);
require dirname(__DIR__) . '/partials/header.php';
?>
<div class="admin-shell">
    <?php require __DIR__ . '/_sidebar.php'; ?>
    <div class="admin-content">
        <header class="admin-header"><div><p class="eyebrow">Community members</p><h1>Registered users</h1><p id="registered-users-count"><?= (int) $result['total'] ?> matching accounts. Newest registrations first.</p></div></header>
        <section class="panel">
            <div class="section-heading"><p id="user-directory-status" role="status">Checks for new registrations every 10 seconds while this page is open.</p><button type="button" class="button button-small" id="refresh-user-directory">Refresh now</button></div>
            <p class="privacy-note"><?= icon_svg('shield') ?><span>Personal information is available only to administrators. Signup platform records where an account was created, not its most recent login.</span></p>
            <form class="admin-filter user-directory-filter" method="get" action="<?= h(app_url('admin/users.php')) ?>">
                <div class="field"><label for="search">Search name, email or phone</label><input id="search" name="search" maxlength="100" value="<?= h($search) ?>"></div>
                <div class="field"><label for="platform">Signup platform</label><select id="platform" name="platform"><option value="">All platforms</option><?php foreach ($platforms as $value => $label): ?><option value="<?= h($value) ?>" <?= $platform === $value ? 'selected' : '' ?>><?= h($label) ?></option><?php endforeach; ?></select></div>
                <button class="button button-small" type="submit">Apply filters</button><a href="<?= h(app_url('admin/users.php')) ?>">Clear</a>
            </form>
            <div id="registered-users-results" data-checked-at="<?= time() ?>">
            <?php if (!$result['items']): ?>
                <div class="empty-state"><p>No registered users match these filters.</p></div>
            <?php else: ?>
                <p class="admin-table-hint">On a small screen, swipe the table sideways to see every column.</p>
                <div class="table-wrap" role="region" aria-label="Registered users table" tabindex="0"><table class="data-table"><thead><tr><th>Name</th><th>Email</th><th>Phone number</th><th>Signup platform</th><th>Registered (South Africa)</th></tr></thead><tbody>
                <?php foreach ($result['items'] as $user): ?>
                    <tr><td><?= h($user['full_name']) ?></td><td><?= h($user['email']) ?></td><td><?= h(trim($user['phone'] ?? '') ?: 'Not provided') ?></td><td><?= h($platforms[$user['signup_platform'] ?? 'unknown'] ?? $platforms['unknown']) ?></td><td><?= empty($user['created_at']) ? 'Not recorded' : h((new DateTimeImmutable($user['created_at'], new DateTimeZone('UTC')))->setTimezone(new DateTimeZone('Africa/Johannesburg'))->format('d M Y, H:i')) ?></td></tr>
                <?php endforeach; ?>
                </tbody></table></div>
                <?php if ($result['pages'] > 1): ?><nav class="pagination" aria-label="Registered user pages"><?php for ($number = max(1, $result['page'] - 2); $number <= min($result['pages'], $result['page'] + 2); $number++): ?><a href="<?= h(app_url('admin/users.php?' . http_build_query(['page' => $number, 'search' => $search, 'platform' => $platform]))) ?>" <?= $number === $result['page'] ? 'aria-current="page"' : '' ?>><?= $number ?></a><?php endfor; ?></nav><?php endif; ?>
            <?php endif; ?>
            </div>
        </section>
    </div>
</div>
<?php require dirname(__DIR__) . '/partials/footer.php'; ?>
