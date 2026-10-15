<aside class="admin-sidebar">
    <h2>BKK Admin</h2>
    <nav class="admin-nav" aria-label="Administrator navigation">
        <a href="<?= h(app_url('admin/index.php')) ?>" <?= ($adminPage ?? '') === 'dashboard' ? 'aria-current="page"' : '' ?>><?= icon_svg('shield') ?> Dashboard</a>
        <?php if (staff_can('users')): ?><a href="<?= h(app_url('admin/users.php')) ?>" <?= ($adminPage ?? '') === 'users' ? 'aria-current="page"' : '' ?>><?= icon_svg('users') ?> Registered users</a><?php endif; ?>
        <?php if (staff_can('staff')): ?><a href="<?= h(app_url('admin/staff.php')) ?>" <?= ($adminPage ?? '') === 'staff' ? 'aria-current="page"' : '' ?>><?= icon_svg('shield') ?> Staff access</a><?php endif; ?>
        <?php if (staff_can('content.write')): ?>
        <a href="<?= h(app_url('admin/events.php')) ?>" <?= ($adminPage ?? '') === 'events' ? 'aria-current="page"' : '' ?>><?= icon_svg('calendar') ?> Manage events</a>
        <a href="<?= h(app_url('admin/discounts.php')) ?>" <?= ($adminPage ?? '') === 'discounts' ? 'aria-current="page"' : '' ?>><?= icon_svg('tag') ?> Manage discounts</a>
        <a href="<?= h(app_url('admin/services.php')) ?>" <?= ($adminPage ?? '') === 'services' ? 'aria-current="page"' : '' ?>><?= icon_svg('pin') ?> Manage local services</a>
        <?php endif; ?>
        <?php if (staff_can('content.read')): ?><a href="<?= h(app_url('admin/reports.php')) ?>" <?= ($adminPage ?? '') === 'reports' ? 'aria-current="page"' : '' ?>><?= icon_svg('calendar') ?> Content overview</a><?php endif; ?>
        <?php if (staff_can('attendance')): ?><a href="<?= h(app_url('admin/attendance.php')) ?>" <?= ($adminPage ?? '') === 'attendance' ? 'aria-current="page"' : '' ?>><?= icon_svg('users') ?> Attendance enquiries</a><?php endif; ?>
        <?php if (staff_can('messages')): ?><a href="<?= h(app_url('admin/messages.php')) ?>" <?= ($adminPage ?? '') === 'messages' ? 'aria-current="page"' : '' ?>><?= icon_svg('mail') ?> Contact messages</a><?php endif; ?>
        <?php if (staff_can('audit')): ?><a href="<?= h(app_url('admin/audit.php')) ?>" <?= ($adminPage ?? '') === 'audit' ? 'aria-current="page"' : '' ?>><?= icon_svg('shield') ?> Audit history</a><?php endif; ?>
    </nav>
</aside>
