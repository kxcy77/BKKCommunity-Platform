DROP PROCEDURE IF EXISTS add_staff_permissions;
DELIMITER //
CREATE PROCEDURE add_staff_permissions()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE()
        AND table_name = 'users' AND column_name = 'staff_level') THEN
        ALTER TABLE users ADD COLUMN staff_level ENUM('owner','editor','support','viewer') NOT NULL DEFAULT 'viewer' AFTER role;
        UPDATE users SET staff_level = 'owner' WHERE role = 'admin';
    END IF;
    ALTER TABLE users ALTER COLUMN staff_level SET DEFAULT 'viewer';
    CREATE TABLE IF NOT EXISTS staff_access_lock (id TINYINT UNSIGNED PRIMARY KEY);
    INSERT IGNORE INTO staff_access_lock(id) VALUES (1);
    CREATE TABLE IF NOT EXISTS staff_invitations (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(190) NOT NULL,
        staff_level ENUM('owner','editor','support','viewer') NOT NULL,
        token_hash CHAR(64) NOT NULL UNIQUE,
        invited_by BIGINT UNSIGNED NULL,
        expires_at DATETIME NOT NULL,
        accepted_at DATETIME NULL,
        revoked_at DATETIME NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_staff_inviter FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL,
        INDEX idx_staff_invite_email (email, expires_at)
    );
END//
DELIMITER ;
CALL add_staff_permissions();
DROP PROCEDURE add_staff_permissions;
