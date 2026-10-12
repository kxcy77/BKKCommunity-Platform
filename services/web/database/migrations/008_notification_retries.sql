ALTER TABLE notification_log
    ADD COLUMN attempt_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ADD COLUMN next_attempt_at DATETIME NULL,
    ADD COLUMN last_error_code VARCHAR(40) NULL;
