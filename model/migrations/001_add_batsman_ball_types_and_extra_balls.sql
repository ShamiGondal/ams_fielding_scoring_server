USE crictest;

-- ============================================================================
-- Migration: Batsman selection, ball types (WIDE/NO_BALL), dismissed per ball
-- Run this on existing databases after fielding_schema.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CREATE BALL_TYPES LOOKUP TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ball_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ball_type_code VARCHAR(30) NOT NULL,
    ball_type_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_ball_type_code (ball_type_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Ball delivery types: NORMAL, WIDE, NO_BALL';

INSERT INTO ball_types (ball_type_code, ball_type_name, display_order, is_active, created_at, updated_at) VALUES
('NORMAL', 'Normal', 1, 1, NOW(), NOW()),
('WIDE', 'Wide', 2, 1, NOW(), NOW()),
('NO_BALL', 'No Ball', 3, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE ball_type_name = VALUES(ball_type_name);

-- ----------------------------------------------------------------------------
-- 2. ALTER fielding_scoring_sessions: striker_id, non_striker_id
-- ----------------------------------------------------------------------------

-- Add striker_id column first
ALTER TABLE fielding_scoring_sessions
    ADD COLUMN striker_id INT UNSIGNED NULL COMMENT 'Batsman on strike' AFTER bowling_team_id;

-- Add non_striker_id column second
ALTER TABLE fielding_scoring_sessions
    ADD COLUMN non_striker_id INT UNSIGNED NULL COMMENT 'Non-striker' AFTER striker_id;

-- Add foreign key constraints
ALTER TABLE fielding_scoring_sessions
    ADD CONSTRAINT fk_fielding_session_striker FOREIGN KEY (striker_id)
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE fielding_scoring_sessions
    ADD CONSTRAINT fk_fielding_session_non_striker FOREIGN KEY (non_striker_id)
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE;

-- ----------------------------------------------------------------------------
-- 3. ALTER fielding_scoring: striker_id, dismissed_batsman_id, ball_type_id
-- ----------------------------------------------------------------------------

-- Add striker_id column first
ALTER TABLE fielding_scoring
    ADD COLUMN striker_id INT UNSIGNED NULL COMMENT 'Batsman on strike this ball' AFTER ball_number;

-- Add dismissed_batsman_id column second
ALTER TABLE fielding_scoring
    ADD COLUMN dismissed_batsman_id INT UNSIGNED NULL COMMENT 'Batsman dismissed on this ball when resulted_in_wicket=1' AFTER striker_id;

-- Add ball_type_id column third
ALTER TABLE fielding_scoring
    ADD COLUMN ball_type_id INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK to ball_types' AFTER dismissed_batsman_id;

-- Add foreign key constraints
ALTER TABLE fielding_scoring
    ADD CONSTRAINT fk_fielding_scoring_striker FOREIGN KEY (striker_id)
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE fielding_scoring
    ADD CONSTRAINT fk_fielding_scoring_dismissed_batsman FOREIGN KEY (dismissed_batsman_id)
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE fielding_scoring
    ADD CONSTRAINT fk_fielding_scoring_ball_type FOREIGN KEY (ball_type_id)
        REFERENCES ball_types (id) ON DELETE RESTRICT ON UPDATE CASCADE;

-- Optional: indexes for common queries
CREATE INDEX idx_fielding_scoring_striker ON fielding_scoring(striker_id);
CREATE INDEX idx_fielding_scoring_dismissed ON fielding_scoring(dismissed_batsman_id);
CREATE INDEX idx_fielding_scoring_ball_type ON fielding_scoring(ball_type_id);