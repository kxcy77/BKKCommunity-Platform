DROP PROCEDURE IF EXISTS add_admin_security_and_audit;
DELIMITER //
CREATE PROCEDURE add_admin_security_and_audit()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = 'users'
          AND column_name = 'auth_version'
    ) THEN
        ALTER TABLE users
            ADD COLUMN auth_version INT UNSIGNED NOT NULL DEFAULT 1 AFTER role;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'events' AND column_name = 'row_version'
    ) THEN
        ALTER TABLE events ADD COLUMN row_version INT UNSIGNED NOT NULL DEFAULT 1 AFTER status;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'discounts' AND column_name = 'row_version'
    ) THEN
        ALTER TABLE discounts ADD COLUMN row_version INT UNSIGNED NOT NULL DEFAULT 1 AFTER is_active;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'local_services' AND column_name = 'row_version'
    ) THEN
        ALTER TABLE local_services ADD COLUMN row_version INT UNSIGNED NOT NULL DEFAULT 1 AFTER is_active;
    END IF;

    CREATE TABLE IF NOT EXISTS admin_audit_log (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        admin_user_id BIGINT UNSIGNED NULL,
        action VARCHAR(80) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id BIGINT UNSIGNED NULL,
        before_json JSON NULL,
        after_json JSON NULL,
        reason VARCHAR(255) NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_admin_audit_user FOREIGN KEY (admin_user_id) REFERENCES users(id) ON DELETE SET NULL,
        INDEX idx_admin_audit_created (created_at),
        INDEX idx_admin_audit_entity (entity_type, entity_id),
        INDEX idx_admin_audit_admin (admin_user_id, created_at)
    );
END//
DELIMITER ;

CALL add_admin_security_and_audit();
DROP PROCEDURE add_admin_security_and_audit;
