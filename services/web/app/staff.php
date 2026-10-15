<?php
declare(strict_types=1);

function staff_post_text(string $key): string
{
    return is_string($_POST[$key] ?? null) ? trim($_POST[$key]) : '';
}

function delete_own_member_account(int $id): bool
{
    $db = database();
    if (!$db) return false;
    $db->beginTransaction();
    try {
        staff_lock($db);
        $query = $db->prepare('SELECT role FROM users WHERE id = ? AND deleted_at IS NULL FOR UPDATE');
        $query->execute([$id]);
        if ($query->fetchColumn() !== 'member') {
            $db->rollBack();
            return false;
        }
        $db->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
        $db->commit();
        return true;
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
}

function staff_confirm_password(string $password): bool
{
    $db = database();
    if (!$db || $password === '') return false;
    $query = $db->prepare('SELECT password_hash FROM users WHERE id = ? AND deleted_at IS NULL');
    $query->execute([current_user()['id']]);
    $hash = $query->fetchColumn();
    return is_string($hash) && password_verify($password, $hash);
}

function staff_lock(PDO $db): void
{
    // Serialize invitations, access changes and acceptance to protect the final owner.
    if ((int) $db->query('SELECT id FROM staff_access_lock WHERE id = 1 FOR UPDATE')->fetchColumn() !== 1) {
        throw new RuntimeException('Staff access locking is unavailable.');
    }
}

function staff_locked_owner(PDO $db): void
{
    $query = $db->prepare('SELECT role, staff_level, auth_version FROM users WHERE id = ? AND deleted_at IS NULL FOR UPDATE');
    $query->execute([current_user()['id']]);
    $actor = $query->fetch();
    if (!$actor || $actor['role'] !== 'admin' || $actor['staff_level'] !== 'owner'
        || (int) $actor['auth_version'] !== (int) current_user()['auth_version']) {
        throw new DomainException('Your owner access changed. Sign in again before continuing.');
    }
}

function staff_revoke_sessions(PDO $db, int $id): void
{
    $db->prepare('UPDATE auth_sessions SET revoked_at = UTC_TIMESTAMP() WHERE user_id = ? AND revoked_at IS NULL')->execute([$id]);
}

function staff_set_access(int $id, string $level, int $expectedVersion, string $reason): void
{
    require_permission('staff');
    if (!isset(staff_levels()[$level]) && $level !== 'member') throw new DomainException('Choose a valid access level.');
    $db = database();
    if (!$db) throw new DomainException('Staff access requires the connected database.');
    $db->beginTransaction();
    try {
        staff_lock($db);
        staff_locked_owner($db);
        $query = $db->prepare('SELECT id, email, role, staff_level, auth_version FROM users WHERE id = ? AND deleted_at IS NULL FOR UPDATE');
        $query->execute([$id]);
        $target = $query->fetch();
        if (!$target || $target['role'] !== 'admin') throw new DomainException('Only existing staff can be changed here. Invite a new staff member instead.');
        if ((int) $target['auth_version'] !== $expectedVersion) throw new DomainException('This account changed in another session. Reload before trying again.');
        if ($target['staff_level'] === 'owner' && $level !== 'owner') {
            $owners = (int) $db->query("SELECT COUNT(*) FROM users WHERE role = 'admin' AND staff_level = 'owner' AND deleted_at IS NULL")->fetchColumn();
            if ($owners <= 1) throw new DomainException('The last owner cannot be removed. Invite another owner and wait for them to accept first.');
        }
        $role = $level === 'member' ? 'member' : 'admin';
        $newLevel = $level === 'member' ? 'viewer' : $level;
        if ($target['role'] === $role && $target['staff_level'] === $newLevel) throw new DomainException('That account already has this access level.');
        $db->prepare('UPDATE users SET role = ?, staff_level = ?, auth_version = auth_version + 1 WHERE id = ?')->execute([$role, $newLevel, $id]);
        staff_revoke_sessions($db, $id);
        $db->prepare('UPDATE staff_invitations SET revoked_at = UTC_TIMESTAMP() WHERE email = ? AND accepted_at IS NULL AND revoked_at IS NULL')->execute([$target['email']]);
        admin_audit_log('staff_access_changed', 'user', $id,
            ['role' => $target['role'], 'staff_level' => $target['staff_level']], ['role' => $role, 'staff_level' => $newLevel], $reason);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
}

function staff_create_invitation(string $email, string $level, string $reason): string
{
    require_permission('staff');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 190 || !isset(staff_levels()[$level])) throw new DomainException('Enter a valid email address and access level.');
    $db = database();
    if (!$db) throw new DomainException('Staff invitations require the connected database.');
    $code = bin2hex(random_bytes(32));
    $db->beginTransaction();
    try {
        staff_lock($db);
        staff_locked_owner($db);
        $existing = $db->prepare("SELECT id FROM users WHERE email = ? AND role = 'admin' AND deleted_at IS NULL");
        $existing->execute([$email]);
        if ($existing->fetchColumn()) throw new DomainException('This person already has staff access. Use the staff list to change their level.');
        $db->prepare('UPDATE staff_invitations SET revoked_at = UTC_TIMESTAMP() WHERE email = ? AND accepted_at IS NULL AND revoked_at IS NULL')->execute([$email]);
        $db->prepare('INSERT INTO staff_invitations(email, staff_level, token_hash, invited_by, expires_at) VALUES (?, ?, ?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 48 HOUR))')
            ->execute([$email, $level, hash('sha256', $code), current_user()['id']]);
        admin_audit_log('staff_invited', 'staff_invitation', (int) $db->lastInsertId(), null, ['email' => $email, 'staff_level' => $level], $reason);
        $db->commit();
        return $code;
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
}

function staff_accept_invitation(string $code): void
{
    require_login();
    if (!preg_match('/^[a-f0-9]{64}$/D', $code)) throw new DomainException('The invitation code is invalid or has expired.');
    $db = database();
    if (!$db) throw new DomainException('Staff invitations require the connected database.');
    $db->beginTransaction();
    try {
        staff_lock($db);
        $query = $db->prepare('SELECT * FROM staff_invitations WHERE token_hash = ? AND accepted_at IS NULL AND revoked_at IS NULL AND expires_at > UTC_TIMESTAMP() FOR UPDATE');
        $query->execute([hash('sha256', $code)]);
        $invite = $query->fetch();
        $accountQuery = $db->prepare('SELECT id, email, role, auth_version FROM users WHERE id = ? AND deleted_at IS NULL FOR UPDATE');
        $accountQuery->execute([current_user()['id']]);
        $account = $accountQuery->fetch();
        if (!$invite || !$account || !hash_equals($invite['email'], strtolower($account['email']))
            || (int) $account['auth_version'] !== (int) current_user()['auth_version']) throw new DomainException('The invitation is invalid, expired, or belongs to a different email address.');
        $owner = $db->prepare("SELECT id FROM users WHERE id = ? AND role = 'admin' AND staff_level = 'owner' AND deleted_at IS NULL");
        $owner->execute([$invite['invited_by']]);
        if (!$owner->fetchColumn()) throw new DomainException('The person who invited you is no longer an owner. Request a new invitation.');
        if ($account['role'] === 'admin') throw new DomainException('You already have staff access. Ask the owner to change your level instead.');
        $db->prepare("UPDATE users SET role = 'admin', staff_level = ?, auth_version = auth_version + 1 WHERE id = ?")->execute([$invite['staff_level'], $account['id']]);
        staff_revoke_sessions($db, (int) $account['id']);
        $db->prepare('UPDATE staff_invitations SET accepted_at = UTC_TIMESTAMP() WHERE id = ?')->execute([$invite['id']]);
        admin_audit_log('staff_invitation_accepted', 'user', (int) $account['id'], ['role' => 'member'], ['staff_level' => $invite['staff_level']]);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
}

function staff_revoke_invitation(int $id, string $reason): void
{
    require_permission('staff');
    $db = database();
    if (!$db) throw new DomainException('The database is unavailable.');
    $db->beginTransaction();
    try {
        staff_lock($db);
        staff_locked_owner($db);
        $statement = $db->prepare('UPDATE staff_invitations SET revoked_at = UTC_TIMESTAMP() WHERE id = ? AND accepted_at IS NULL AND revoked_at IS NULL');
        $statement->execute([$id]);
        if (!$statement->rowCount()) throw new DomainException('That invitation is no longer pending.');
        admin_audit_log('staff_invitation_revoked', 'staff_invitation', $id, null, null, $reason);
        $db->commit();
    } catch (Throwable $e) {
        if ($db->inTransaction()) $db->rollBack();
        throw $e;
    }
}
