<?php
declare(strict_types=1);
function database(): ?PDO { return null; }
function app_config(?string $key = null): mixed { return $key === 'allow_demo_mode' ? false : null; }
require dirname(__DIR__) . '/app/auth.php';
$matrix = [
    'owner' => ['dashboard','content.read','content.write','messages','attendance','users','audit','staff'],
    'editor' => ['dashboard','content.read','content.write'],
    'support' => ['dashboard','messages','attendance'],
    'viewer' => ['dashboard','content.read'],
    'unknown' => [],
    '' => [],
];
foreach ($matrix as $level => $allowed) {
    $_SESSION['user'] = ['role' => 'admin', 'staff_level' => $level];
    foreach (['dashboard','content.read','content.write','messages','attendance','users','audit','staff','made.up'] as $permission) {
        if (staff_can($permission) !== in_array($permission, $allowed, true)) throw new RuntimeException("Wrong access for $level / $permission");
    }
}
$_SESSION['user'] = ['role' => 'member', 'staff_level' => 'owner'];
if (staff_can('staff')) throw new RuntimeException('A member cannot acquire staff access through the level field.');
$_SESSION['user'] = ['role' => 'admin'];
if (staff_can('staff')) throw new RuntimeException('Missing levels must fail closed outside explicit demo mode.');
unset($_SESSION['user']);
if (staff_can('dashboard')) throw new RuntimeException('Guests cannot access the staff dashboard.');
echo "PASS permission matrix, unknown permissions, missing levels, member and guest fail-closed behaviour\n";
