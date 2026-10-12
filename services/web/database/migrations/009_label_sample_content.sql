DROP PROCEDURE IF EXISTS label_sample_content;
DELIMITER //
CREATE PROCEDURE label_sample_content()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'discounts' AND column_name = 'is_demo'
    ) THEN
        ALTER TABLE discounts ADD COLUMN is_demo BOOLEAN NOT NULL DEFAULT FALSE AFTER is_active;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'local_services' AND column_name = 'is_demo'
    ) THEN
        ALTER TABLE local_services ADD COLUMN is_demo BOOLEAN NOT NULL DEFAULT FALSE AFTER is_active;
    END IF;
END//
DELIMITER ;
CALL label_sample_content();
DROP PROCEDURE label_sample_content;

-- Match the exact fixture identity, not an ID or store name alone. Do not mark
-- a future independently approved offer from the same business as a demo.
UPDATE discounts SET is_demo = TRUE
WHERE (store_name = 'Clicks' AND title = '10% off selected prescriptions'
       AND details = 'Selected prescription items qualify for a pensioner discount.')
   OR (store_name = 'Checkers' AND title = 'Tuesday senior savings'
       AND details = 'Save 5% on qualifying grocery purchases every Tuesday.')
   OR (store_name = 'Wimpy' AND title = 'Senior breakfast special'
       AND details = 'A reduced-price breakfast before 10:00 on weekdays.');

UPDATE local_services SET is_demo = TRUE
WHERE (name = 'BKK Community Clinic' AND address = '12 Main Road, BKK' AND phone = '011 555 0101')
   OR (name = 'Community Pharmacy' AND address = '18 Main Road, BKK' AND phone = '011 555 0102')
   OR (name = 'BKK Community Support Desk' AND address = 'BKK Community Hall, Main Road'
       AND phone = '072 888 5030');
