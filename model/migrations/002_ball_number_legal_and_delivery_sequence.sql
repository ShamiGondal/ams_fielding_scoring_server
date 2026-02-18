USE crictest;

-- ============================================================================
-- Migration: Recreate fielding_scoring with delivery_sequence
-- ============================================================================

-- 1. Create new table with complete structure from your schema
CREATE TABLE fielding_scoring_new (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    
    -- Match context
    match_id INT UNSIGNED NOT NULL,
    inning_number INT UNSIGNED NOT NULL,
    over_number INT UNSIGNED NOT NULL,
    ball_number INT UNSIGNED NOT NULL COMMENT 'Legal ball index 1-6; same number repeated for extra and replacement (use delivery_sequence for order)',
    delivery_sequence INT UNSIGNED NOT NULL COMMENT '1-based delivery index within the over; order of deliveries',
    
    -- Batsman and ball type
    striker_id INT UNSIGNED NULL COMMENT 'Batsman on strike this ball',
    dismissed_batsman_id INT UNSIGNED NULL COMMENT 'Batsman dismissed on this ball when resulted_in_wicket=1',
    ball_type_id INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK to ball_types (NORMAL/WIDE/NO_BALL)',
    
    -- Primary fielder details
    primary_fielder_id INT UNSIGNED NOT NULL COMMENT 'Main fielder involved',
    primary_fielder_position_id INT UNSIGNED NOT NULL COMMENT 'Position of primary fielder',
    
    -- Secondary fielders (for relay/assists)
    relay_fielder_id INT UNSIGNED NULL COMMENT 'Fielder who relayed the ball',
    relay_fielder_position_id INT UNSIGNED NULL,
    receiver_fielder_id INT UNSIGNED NULL COMMENT 'Fielder who received throw',
    receiver_fielder_position_id INT UNSIGNED NULL,
    
    -- Fielding Action
    fielding_action_type_id INT UNSIGNED NOT NULL COMMENT 'FK to fielding_action_types',
    
    -- Runs Impact
    actual_runs_scored INT NOT NULL DEFAULT 0 COMMENT 'Actual runs scored on this ball',
    runs_saved INT NOT NULL DEFAULT 0 COMMENT 'Runs saved by good fielding',
    runs_cost INT NOT NULL DEFAULT 0 COMMENT 'Extra runs due to poor fielding',
    potential_runs INT NOT NULL DEFAULT 0 COMMENT 'What could have been scored without fielding',
    net_fielding_impact INT GENERATED ALWAYS AS (runs_saved - runs_cost) STORED,
    
    -- Ground Fielding Details
    pickup_type_id INT UNSIGNED NULL COMMENT 'FK to pickup_types',
    
    -- Catching Details
    catch_difficulty_id INT UNSIGNED NULL COMMENT 'FK to catch_difficulty_levels',
    catch_result_id INT UNSIGNED NULL COMMENT 'FK to fielding_action_types for result',
    
    -- Throwing Details
    throw_type_id INT UNSIGNED NULL COMMENT 'FK to throw_types',
    throw_technique_id INT UNSIGNED NULL COMMENT 'FK to throw_techniques',
    throw_accuracy_id INT UNSIGNED NULL COMMENT 'FK to athletic_quality_ratings',
    
    -- Athletic Assessment
    anticipation_rating_id INT UNSIGNED NULL COMMENT 'FK to athletic_quality_ratings',
    agility_rating_id INT UNSIGNED NULL COMMENT 'FK to athletic_quality_ratings',
    
    -- Backup & Error
    backup_observation_id INT UNSIGNED NULL COMMENT 'FK to backup_observation_types',
    error_type_id INT UNSIGNED NULL COMMENT 'FK to error_types',

    -- Batsman & Keeper Context
    handedness_id INT UNSIGNED NULL COMMENT 'FK to handedness_types',
    batting_context_id INT UNSIGNED NULL COMMENT 'FK to batting_context_types',
    keeper_context_id INT UNSIGNED NULL COMMENT 'FK to keeper_context_types',
    keeper_standing_position_id INT UNSIGNED NULL COMMENT 'FK to keeper_standing_positions',
    
    -- Ball Trajectory
    ball_arrival_x DECIMAL(5,2) NULL COMMENT 'X coordinate where ball arrived',
    ball_arrival_y DECIMAL(5,2) NULL COMMENT 'Y coordinate where ball arrived',
    wagon_wheel_x DECIMAL(5,2) NULL,
    wagon_wheel_y DECIMAL(5,2) NULL,
    
    -- Outcome flags
    resulted_in_wicket TINYINT(1) NOT NULL DEFAULT 0,
    resulted_in_boundary TINYINT(1) NOT NULL DEFAULT 0,
    is_dot_ball TINYINT(1) NOT NULL DEFAULT 0,
    
    -- Notes & Media
    fielding_notes TEXT NULL,
    video_timestamp DATETIME NULL,
    
    -- Quality Assessment
    fielding_quality_score DECIMAL(3,2) NULL COMMENT '0.00 to 1.00',
    
    -- Metadata
    recorded_by_user_id INT UNSIGNED NOT NULL,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    verified_by_user_id INT UNSIGNED NULL,
    verified_at DATETIME NULL,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY unique_match_delivery (match_id, inning_number, over_number, delivery_sequence),
    KEY idx_primary_fielder (primary_fielder_id),
    KEY idx_relay_fielder (relay_fielder_id),
    KEY idx_receiver_fielder (receiver_fielder_id),
    KEY idx_action_type (fielding_action_type_id),
    KEY idx_runs_impact (actual_runs_scored, runs_saved, runs_cost),
    KEY idx_wicket_boundary (resulted_in_wicket, resulted_in_boundary),
    KEY idx_handedness (handedness_id),
    KEY idx_batting_context (batting_context_id),
    KEY idx_keeper_context (keeper_context_id),
    KEY idx_keeper_position (keeper_standing_position_id),
    KEY idx_fielding_scoring_striker (striker_id),
    KEY idx_fielding_scoring_dismissed (dismissed_batsman_id),
    KEY idx_fielding_scoring_ball_type (ball_type_id),
    
    CONSTRAINT fk_fielding_scoring_new_match FOREIGN KEY (match_id) 
        REFERENCES matches (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_primary_fielder FOREIGN KEY (primary_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_primary_position FOREIGN KEY (primary_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_relay_fielder FOREIGN KEY (relay_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_relay_position FOREIGN KEY (relay_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_receiver_fielder FOREIGN KEY (receiver_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_receiver_position FOREIGN KEY (receiver_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_action_type FOREIGN KEY (fielding_action_type_id) 
        REFERENCES fielding_action_types (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_pickup_type FOREIGN KEY (pickup_type_id) 
        REFERENCES pickup_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_catch_difficulty FOREIGN KEY (catch_difficulty_id) 
        REFERENCES catch_difficulty_levels (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_throw_type FOREIGN KEY (throw_type_id) 
        REFERENCES throw_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_throw_technique FOREIGN KEY (throw_technique_id) 
        REFERENCES throw_techniques (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_backup_obs FOREIGN KEY (backup_observation_id) 
        REFERENCES backup_observation_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_error_type FOREIGN KEY (error_type_id) 
        REFERENCES error_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_handedness FOREIGN KEY (handedness_id) 
        REFERENCES handedness_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_batting_context FOREIGN KEY (batting_context_id) 
        REFERENCES batting_context_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_keeper_context FOREIGN KEY (keeper_context_id) 
        REFERENCES keeper_context_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_keeper_position FOREIGN KEY (keeper_standing_position_id) 
        REFERENCES keeper_standing_positions (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_striker FOREIGN KEY (striker_id) 
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_dismissed_batsman FOREIGN KEY (dismissed_batsman_id) 
        REFERENCES players (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_new_ball_type FOREIGN KEY (ball_type_id) 
        REFERENCES ball_types (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Main fielding scoring table - one record per ball with fielding action';

-- 2. Copy data with delivery_sequence and recalculated ball_number
CREATE TEMPORARY TABLE _fs_ball_backfill (
    id INT UNSIGNED PRIMARY KEY,
    new_ball_number INT UNSIGNED NOT NULL
) ENGINE=MEMORY;

INSERT INTO _fs_ball_backfill (id, new_ball_number)
SELECT
    id,
    LEAST(
        1 + COALESCE(
            SUM(CASE WHEN ball_type_id NOT IN (2, 3) THEN 1 ELSE 0 END) OVER (
                PARTITION BY match_id, inning_number, over_number
                ORDER BY ball_number
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
        ),
        6
    ) AS new_ball_number
FROM fielding_scoring;

-- 3. Copy all data to new table (explicitly list columns, excluding generated column)
INSERT INTO fielding_scoring_new (
    id,
    match_id,
    inning_number,
    over_number,
    ball_number,
    delivery_sequence,
    striker_id,
    dismissed_batsman_id,
    ball_type_id,
    primary_fielder_id,
    primary_fielder_position_id,
    relay_fielder_id,
    relay_fielder_position_id,
    receiver_fielder_id,
    receiver_fielder_position_id,
    fielding_action_type_id,
    actual_runs_scored,
    runs_saved,
    runs_cost,
    potential_runs,
    -- skip net_fielding_impact (generated column)
    pickup_type_id,
    catch_difficulty_id,
    catch_result_id,
    throw_type_id,
    throw_technique_id,
    throw_accuracy_id,
    anticipation_rating_id,
    agility_rating_id,
    backup_observation_id,
    error_type_id,
    handedness_id,
    batting_context_id,
    keeper_context_id,
    keeper_standing_position_id,
    ball_arrival_x,
    ball_arrival_y,
    wagon_wheel_x,
    wagon_wheel_y,
    resulted_in_wicket,
    resulted_in_boundary,
    is_dot_ball,
    fielding_notes,
    video_timestamp,
    fielding_quality_score,
    recorded_by_user_id,
    is_verified,
    verified_by_user_id,
    verified_at,
    created_at,
    updated_at,
    created_by,
    updated_by
)
SELECT 
    fs.id,
    fs.match_id,
    fs.inning_number,
    fs.over_number,
    b.new_ball_number,  -- recalculated ball_number
    fs.ball_number AS delivery_sequence,  -- old ball_number becomes delivery_sequence
    fs.striker_id,
    fs.dismissed_batsman_id,
    fs.ball_type_id,
    fs.primary_fielder_id,
    fs.primary_fielder_position_id,
    fs.relay_fielder_id,
    fs.relay_fielder_position_id,
    fs.receiver_fielder_id,
    fs.receiver_fielder_position_id,
    fs.fielding_action_type_id,
    fs.actual_runs_scored,
    fs.runs_saved,
    fs.runs_cost,
    fs.potential_runs,
    -- net_fielding_impact is auto-calculated
    fs.pickup_type_id,
    fs.catch_difficulty_id,
    fs.catch_result_id,
    fs.throw_type_id,
    fs.throw_technique_id,
    fs.throw_accuracy_id,
    fs.anticipation_rating_id,
    fs.agility_rating_id,
    fs.backup_observation_id,
    fs.error_type_id,
    fs.handedness_id,
    fs.batting_context_id,
    fs.keeper_context_id,
    fs.keeper_standing_position_id,
    fs.ball_arrival_x,
    fs.ball_arrival_y,
    fs.wagon_wheel_x,
    fs.wagon_wheel_y,
    fs.resulted_in_wicket,
    fs.resulted_in_boundary,
    fs.is_dot_ball,
    fs.fielding_notes,
    fs.video_timestamp,
    fs.fielding_quality_score,
    fs.recorded_by_user_id,
    fs.is_verified,
    fs.verified_by_user_id,
    fs.verified_at,
    fs.created_at,
    fs.updated_at,
    fs.created_by,
    fs.updated_by
FROM fielding_scoring fs
INNER JOIN _fs_ball_backfill b ON fs.id = b.id;

DROP TEMPORARY TABLE _fs_ball_backfill;

-- 4. Drop foreign keys from child tables
ALTER TABLE ball_fielding_positions DROP FOREIGN KEY fk_ball_positions_fielding_scoring;
ALTER TABLE wicketkeeping_details DROP FOREIGN KEY fk_wk_details_fielding_scoring;

-- 5. Swap tables
DROP TABLE fielding_scoring;
RENAME TABLE fielding_scoring_new TO fielding_scoring;

-- 6. Recreate foreign keys from child tables
ALTER TABLE ball_fielding_positions
    ADD CONSTRAINT fk_ball_positions_fielding_scoring 
    FOREIGN KEY (fielding_scoring_id) 
    REFERENCES fielding_scoring (id) 
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE wicketkeeping_details
    ADD CONSTRAINT fk_wk_details_fielding_scoring 
    FOREIGN KEY (fielding_scoring_id) 
    REFERENCES fielding_scoring (id) 
    ON DELETE CASCADE ON UPDATE CASCADE;

-- 7. Recreate performance indexes
CREATE INDEX idx_fielding_scoring_player_match ON fielding_scoring(primary_fielder_id, match_id);
CREATE INDEX idx_fielding_scoring_runs_analysis ON fielding_scoring(actual_runs_scored, runs_saved, runs_cost);
CREATE INDEX idx_fielding_scoring_quality ON fielding_scoring(fielding_quality_score);