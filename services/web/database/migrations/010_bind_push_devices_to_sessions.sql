-- Existing devices must re-register on their next app launch. Until then they
-- cannot receive pushes, which is safer than guessing which session owns them.
ALTER TABLE devices
    ADD COLUMN session_id BIGINT UNSIGNED NULL AFTER user_id,
    ADD INDEX idx_device_session (session_id),
    ADD CONSTRAINT fk_device_session FOREIGN KEY (session_id)
        REFERENCES auth_sessions(id) ON DELETE SET NULL;
