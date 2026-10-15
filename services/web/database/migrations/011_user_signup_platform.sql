-- Preserve existing accounts without guessing their original signup channel.
SET @signup_column_exists = (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'signup_platform');
SET @signup_ddl = IF(@signup_column_exists = 0,
    'ALTER TABLE users ADD COLUMN signup_platform ENUM(''website'',''android'',''unknown'') NOT NULL DEFAULT ''unknown'', ADD INDEX idx_users_signup_created (signup_platform, created_at, id)',
    'SELECT 1');
PREPARE signup_stmt FROM @signup_ddl;
EXECUTE signup_stmt;
DEALLOCATE PREPARE signup_stmt;
