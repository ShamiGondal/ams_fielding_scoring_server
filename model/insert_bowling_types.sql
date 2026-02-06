-- ============================================================================
-- BOWLING TYPES DATA - Insert Sample Data
-- ============================================================================

-- Insert bowling types (if they don't exist)
INSERT INTO bowling_types (id, type, code, created_at, updated_at) VALUES
(1, 'Fast', 'FAST', NOW(), NOW()),
(2, 'Fast Medium', 'FM', NOW(), NOW()),
(3, 'Medium', 'MED', NOW(), NOW()),
(4, 'Medium Slow', 'MS', NOW(), NOW()),
(5, 'Slow', 'SLOW', NOW(), NOW()),
(6, 'Off Spin', 'OS', NOW(), NOW()),
(7, 'Leg Spin', 'LS', NOW(), NOW()),
(8, 'Left Arm Orthodox', 'LAO', NOW(), NOW()),
(9, 'Left Arm Chinaman', 'LAC', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    type = VALUES(type),
    code = VALUES(code),
    updated_at = NOW();

-- Verify insertion
SELECT * FROM bowling_types;
