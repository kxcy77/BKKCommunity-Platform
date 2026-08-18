CREATE TABLE `members` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `full_name` VARCHAR(120) NOT NULL,
    `email` VARCHAR(254) NOT NULL,
    `phone` VARCHAR(30) NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `is_admin` BOOLEAN NOT NULL DEFAULT false,
    `notifications_enabled` BOOLEAN NOT NULL DEFAULT true,
    `event_reminders_enabled` BOOLEAN NOT NULL DEFAULT true,
    `discount_alerts_enabled` BOOLEAN NOT NULL DEFAULT true,
    `failed_attempts` INTEGER NOT NULL DEFAULT 0,
    `locked_until` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    UNIQUE INDEX `members_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `events` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NOT NULL,
    `start_at` DATETIME(3) NOT NULL,
    `end_at` DATETIME(3) NOT NULL,
    `location` VARCHAR(255) NOT NULL,
    `directions` TEXT NULL,
    `category` VARCHAR(100) NOT NULL,
    `colour_hex` CHAR(7) NOT NULL DEFAULT '#315C24',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `attendance` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `member_id` INTEGER NOT NULL,
    `event_id` INTEGER NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'attending',
    UNIQUE INDEX `attendance_member_id_event_id_key`(`member_id`, `event_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `discounts` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `store_name` VARCHAR(180) NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `details` TEXT NOT NULL,
    `eligibility` TEXT NOT NULL,
    `claim_instructions` TEXT NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `valid_from` DATETIME(3) NULL,
    `valid_until` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `local_services` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(100) NOT NULL,
    `name` VARCHAR(180) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(30) NOT NULL,
    `directions` TEXT NULL,
    `opening_hours` VARCHAR(255) NULL,
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `contact_messages` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(120) NOT NULL,
    `email` VARCHAR(254) NOT NULL,
    `message` TEXT NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `device_tokens` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `member_id` INTEGER NOT NULL,
    `fcm_token` VARCHAR(512) NOT NULL,
    `platform` VARCHAR(20) NOT NULL DEFAULT 'android',
    `notifications_enabled` BOOLEAN NOT NULL DEFAULT true,
    `last_seen_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    UNIQUE INDEX `device_tokens_fcm_token_key`(`fcm_token`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `password_resets` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `member_id` INTEGER NOT NULL,
    `code_hash` CHAR(64) NOT NULL,
    `failed_attempts` INTEGER NOT NULL DEFAULT 0,
    `expires_at` DATETIME(3) NOT NULL,
    `used_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `password_resets_code_hash_key`(`code_hash`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `auth_sessions` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `member_id` INTEGER NOT NULL,
    `token_id` CHAR(36) NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `revoked_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `auth_sessions_token_id_key`(`token_id`),
    INDEX `auth_sessions_member_id_expires_at_idx`(`member_id`, `expires_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `notification_logs` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `member_id` INTEGER NULL,
    `device_token_id` INTEGER NULL,
    `notification_type` VARCHAR(40) NOT NULL,
    `provider_message_id` VARCHAR(255) NULL,
    `dedupe_key` VARCHAR(191) NULL,
    `status` VARCHAR(30) NOT NULL,
    `error_code` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE INDEX `notification_logs_dedupe_key_key`(`dedupe_key`),
    INDEX `notification_logs_member_id_created_at_idx`(`member_id`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `admin_audit_logs` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `admin_member_id` INTEGER NOT NULL,
    `action` VARCHAR(60) NOT NULL,
    `entity_type` VARCHAR(60) NOT NULL,
    `entity_id` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    INDEX `admin_audit_logs_admin_member_id_created_at_idx`(`admin_member_id`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `attendance` ADD CONSTRAINT `attendance_member_id_fkey`
    FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `attendance` ADD CONSTRAINT `attendance_event_id_fkey`
    FOREIGN KEY (`event_id`) REFERENCES `events`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `device_tokens` ADD CONSTRAINT `device_tokens_member_id_fkey`
    FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `password_resets` ADD CONSTRAINT `password_resets_member_id_fkey`
    FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `auth_sessions` ADD CONSTRAINT `auth_sessions_member_id_fkey`
    FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `notification_logs` ADD CONSTRAINT `notification_logs_member_id_fkey`
    FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `notification_logs` ADD CONSTRAINT `notification_logs_device_token_id_fkey`
    FOREIGN KEY (`device_token_id`) REFERENCES `device_tokens`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
