-- ============================================================================
-- CRICKET FIELDING ANALYSIS SCHEMA - PRODUCTION READY
-- Integrated with existing match_scorings table
-- All lookups use IDs instead of ENUMs for maximum flexibility
-- Ready to execute directly in MySQL Workbench
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. POSITION CATEGORIES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE position_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL COMMENT 'CLOSE_IN, INFIELD, OUTFIELD, KEEPER',
    category_description VARCHAR(255) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Categories for fielding positions';

-- ----------------------------------------------------------------------------
-- 2. FIELDING POSITIONS MASTER DATA
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_positions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    position_code VARCHAR(10) NOT NULL COMMENT 'BWK, SL, S, C, MC, B, MW, M, F, S/A, L',
    position_name VARCHAR(100) NOT NULL COMMENT 'Wicket Keeper, Slip, Short Cover, etc.',
    position_category_id INT UNSIGNED NOT NULL COMMENT 'FK to position_categories',
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_position_code (position_code),
    KEY idx_position_category (position_category_id),
    CONSTRAINT fk_fielding_positions_category FOREIGN KEY (position_category_id) 
        REFERENCES position_categories (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Master table for all fielding positions on cricket ground';

-- ----------------------------------------------------------------------------
-- 3. FIELDING ACTION CATEGORIES
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_action_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL COMMENT 'GROUND_FIELDING, CATCH, THROW, RUN_OUT, KEEPER',
    category_description VARCHAR(255) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Categories for fielding actions';

-- ----------------------------------------------------------------------------
-- 4. FIELDING ACTION TYPES
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_action_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    action_category_id INT UNSIGNED NOT NULL,
    action_code VARCHAR(50) NOT NULL,
    action_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_positive TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 for good action, 0 for error',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_action_code (action_code),
    KEY idx_action_category (action_category_id),
    CONSTRAINT fk_action_types_category FOREIGN KEY (action_category_id) 
        REFERENCES fielding_action_categories (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Master data for all types of fielding actions';

-- ----------------------------------------------------------------------------
-- 5. PICKUP TYPES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE pickup_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    pickup_code VARCHAR(30) NOT NULL,
    pickup_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_pickup_code (pickup_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Types of pickups: clean, one-hand, two-hand, slide, dive';

-- ----------------------------------------------------------------------------
-- 6. THROW TYPES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE throw_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    throw_code VARCHAR(30) NOT NULL,
    throw_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_throw_code (throw_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Types of throws: direct hit, one bounce, missed, overthrow';

-- ----------------------------------------------------------------------------
-- 7. THROW TECHNIQUES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE throw_techniques (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    technique_code VARCHAR(30) NOT NULL,
    technique_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_technique_code (technique_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Throwing techniques: overarm, underarm, sidearm, resolvers';

-- ----------------------------------------------------------------------------
-- 8. CATCH DIFFICULTY LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE catch_difficulty_levels (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    difficulty_code VARCHAR(30) NOT NULL,
    difficulty_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_difficulty_code (difficulty_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Catch difficulty levels: easy, medium, hard';

-- ----------------------------------------------------------------------------
-- 9. ATHLETIC QUALITY RATINGS LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE athletic_quality_ratings (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    rating_code VARCHAR(30) NOT NULL,
    rating_name VARCHAR(100) NOT NULL,
    rating_value DECIMAL(3,2) NOT NULL COMMENT 'Numeric value for calculations',
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_rating_code (rating_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Athletic quality ratings: excellent, good, balanced, poor';

-- ----------------------------------------------------------------------------
-- 10. BACKUP OBSERVATION TYPES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE backup_observation_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    observation_code VARCHAR(50) NOT NULL,
    observation_name VARCHAR(100) NOT NULL,
    is_positive TINYINT(1) NOT NULL DEFAULT 1,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_observation_code (observation_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Backup observations: in position, late reaction, not in position, etc.';

-- ----------------------------------------------------------------------------
-- 11. ERROR TYPES LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE error_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    error_code VARCHAR(50) NOT NULL,
    error_name VARCHAR(100) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_error_code (error_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Error types: misjudge, fumble, overthrow, ball through legs, wrong footwork';

-- ----------------------------------------------------------------------------
-- 12. KEEPER CONTEXT LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE keeper_context_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    context_code VARCHAR(30) NOT NULL,
    context_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_context_code (context_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Keeper context: PACER, SPINNER';

-- ----------------------------------------------------------------------------
-- 13. KEEPER STANDING POSITION LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE keeper_standing_positions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    position_code VARCHAR(30) NOT NULL,
    position_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_position_code (position_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Keeper standing: UP_TO_STUMPS, BACK';

-- ----------------------------------------------------------------------------
-- 14. BATTING CONTEXT TYPES
-- ----------------------------------------------------------------------------

CREATE TABLE batting_context_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    context_code VARCHAR(30) NOT NULL,
    context_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_context_code (context_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Batting context: POWERPLAY, MIDDLE_OVERS, DEATH_OVERS, GENERAL';

-- ----------------------------------------------------------------------------
-- 15. HANDEDNESS LOOKUP
-- ----------------------------------------------------------------------------

CREATE TABLE handedness_types (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    handedness_code VARCHAR(30) NOT NULL,
    handedness_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_handedness_code (handedness_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Handedness: LEFT_HAND, RIGHT_HAND, BOTH';

-- ----------------------------------------------------------------------------
-- 16. FIELDING_SCORING - MAIN TABLE (Links to match_scorings)
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_scoring (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    
    -- Match context (no FK to match_scorings - standalone fielding analysis)
    match_id INT UNSIGNED NOT NULL,
    inning_number INT UNSIGNED NOT NULL,
    over_number INT UNSIGNED NOT NULL,
    ball_number INT UNSIGNED NOT NULL,
    
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
    
    -- Runs Impact (MOST IMPORTANT FOR YOUR REQUIREMENT)
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
    UNIQUE KEY unique_match_ball (match_id, inning_number, over_number, ball_number),
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
    
    CONSTRAINT fk_fielding_scoring_match FOREIGN KEY (match_id) 
        REFERENCES matches (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_primary_fielder FOREIGN KEY (primary_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_primary_position FOREIGN KEY (primary_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_relay_fielder FOREIGN KEY (relay_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_relay_position FOREIGN KEY (relay_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_receiver_fielder FOREIGN KEY (receiver_fielder_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_receiver_position FOREIGN KEY (receiver_fielder_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_action_type FOREIGN KEY (fielding_action_type_id) 
        REFERENCES fielding_action_types (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_pickup_type FOREIGN KEY (pickup_type_id) 
        REFERENCES pickup_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_catch_difficulty FOREIGN KEY (catch_difficulty_id) 
        REFERENCES catch_difficulty_levels (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_throw_type FOREIGN KEY (throw_type_id) 
        REFERENCES throw_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_throw_technique FOREIGN KEY (throw_technique_id) 
        REFERENCES throw_techniques (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_backup_obs FOREIGN KEY (backup_observation_id) 
        REFERENCES backup_observation_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_error_type FOREIGN KEY (error_type_id) 
        REFERENCES error_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_handedness FOREIGN KEY (handedness_id) 
        REFERENCES handedness_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_batting_context FOREIGN KEY (batting_context_id) 
        REFERENCES batting_context_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_keeper_context FOREIGN KEY (keeper_context_id) 
        REFERENCES keeper_context_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_scoring_keeper_position FOREIGN KEY (keeper_standing_position_id) 
        REFERENCES keeper_standing_positions (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Main fielding scoring table - one record per ball with fielding action';

-- ----------------------------------------------------------------------------
-- 17. BALL_FIELDING_POSITIONS - All fielder positions for each ball
-- ----------------------------------------------------------------------------

CREATE TABLE ball_fielding_positions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    
    -- Link to fielding_scoring
    fielding_scoring_id INT UNSIGNED NOT NULL COMMENT 'FK to fielding_scoring.id',
    
    -- Fielder details
    player_id INT UNSIGNED NOT NULL,
    fielding_position_id INT UNSIGNED NOT NULL,
    position_number TINYINT NOT NULL COMMENT '1-11 for visual display',
    
    -- Position coordinates on ground
    position_x DECIMAL(5,2) NULL COMMENT 'X coordinate on field visualization',
    position_y DECIMAL(5,2) NULL COMMENT 'Y coordinate on field visualization',
    
    -- Special roles
    is_keeper TINYINT(1) NOT NULL DEFAULT 0,
    is_primary_fielder TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'The fielder who acted on this ball',
    is_backup TINYINT(1) NOT NULL DEFAULT 0,
    
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY unique_fielding_scoring_player (fielding_scoring_id, player_id),
    KEY idx_player (player_id),
    KEY idx_position (fielding_position_id),
    KEY idx_primary_fielder (is_primary_fielder),
    
    CONSTRAINT fk_ball_positions_fielding_scoring FOREIGN KEY (fielding_scoring_id) 
        REFERENCES fielding_scoring (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ball_positions_player FOREIGN KEY (player_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ball_positions_position FOREIGN KEY (fielding_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='All 11 fielder positions for each ball - complete field setup';

-- ----------------------------------------------------------------------------
-- 18. WICKETKEEPING DETAILS (Extended from fielding_scoring)
-- ----------------------------------------------------------------------------

CREATE TABLE wicketkeeping_details (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    
    -- Link to parent fielding_scoring record
    fielding_scoring_id INT UNSIGNED NOT NULL COMMENT 'FK to fielding_scoring.id',
    
    -- Keeper specific context
    keeper_context_id INT UNSIGNED NOT NULL COMMENT 'Pacer/Spinner - FK to lookup',
    standing_position_id INT UNSIGNED NOT NULL COMMENT 'Up/Back - FK to lookup',
    
    -- Ball collection type
    collection_type_id INT UNSIGNED NULL COMMENT 'FK to fielding_action_types',
    coverage_quality_id INT UNSIGNED NULL COMMENT 'FK to athletic_quality_ratings',
    collection_error_id INT UNSIGNED NULL COMMENT 'FK to error_types',
    
    -- Run impact
    dismissal_involvement_id INT UNSIGNED NULL COMMENT 'Stumping/Caught/RunOut - FK',
    resulted_in_dismissal TINYINT(1) NOT NULL DEFAULT 0,
    dismissal_type VARCHAR(50) NULL,
    
    -- Notes
    keeper_notes TEXT NULL,
    
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    
    PRIMARY KEY (id),
    UNIQUE KEY unique_fielding_scoring (fielding_scoring_id),
    
    CONSTRAINT fk_wk_details_fielding_scoring FOREIGN KEY (fielding_scoring_id) 
        REFERENCES fielding_scoring (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wk_details_keeper_context FOREIGN KEY (keeper_context_id) 
        REFERENCES keeper_context_types (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wk_details_standing_position FOREIGN KEY (standing_position_id) 
        REFERENCES keeper_standing_positions (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Wicketkeeping specific details extending fielding_scoring';

-- ----------------------------------------------------------------------------
-- 19. FIELDING PLANS/STRATEGIES
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_plans (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    plan_name VARCHAR(100) NOT NULL COMMENT 'T-20 Aggressive, Slip Field, etc.',
    plan_description TEXT,
    match_type_id INT UNSIGNED NOT NULL,
    batting_context_id INT UNSIGNED NULL COMMENT 'FK to batting_context_types',
    batsman_handedness_id INT UNSIGNED NULL COMMENT 'FK to handedness lookup',
    bowler_type_id INT UNSIGNED NULL COMMENT 'Can use existing bowling_types table',
    team_id INT UNSIGNED NULL COMMENT 'Optional: team-specific plan',
    is_template TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    PRIMARY KEY (id),
    KEY idx_match_type (match_type_id),
    KEY idx_team (team_id),
    KEY idx_plan_name (plan_name),
    CONSTRAINT fk_fielding_plans_match_type FOREIGN KEY (match_type_id) 
        REFERENCES match_types (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_plans_team FOREIGN KEY (team_id) 
        REFERENCES teams (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_plans_bowler_type FOREIGN KEY (bowler_type_id) 
        REFERENCES bowling_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_plans_batting_context FOREIGN KEY (batting_context_id) 
        REFERENCES batting_context_types (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_plans_handedness FOREIGN KEY (batsman_handedness_id) 
        REFERENCES handedness_types (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Pre-defined fielding strategies and plans';

-- ----------------------------------------------------------------------------
-- 20. FIELDING PLAN POSITIONS
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_plan_positions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    fielding_plan_id INT UNSIGNED NOT NULL,
    fielding_position_id INT UNSIGNED NOT NULL,
    position_number TINYINT NOT NULL COMMENT '1-11 for player numbering',
    coordinate_x DECIMAL(5,2) NULL,
    coordinate_y DECIMAL(5,2) NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    notes VARCHAR(255) NULL,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_plan_position (fielding_plan_id, fielding_position_id),
    KEY idx_fielding_plan (fielding_plan_id),
    CONSTRAINT fk_plan_positions_plan FOREIGN KEY (fielding_plan_id) 
        REFERENCES fielding_plans (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_plan_positions_position FOREIGN KEY (fielding_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Positions defined in each fielding plan';

-- ----------------------------------------------------------------------------
-- 21. FIELDING PLAN PLAYERS (Player-Position Assignments in Templates)
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_plan_players (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    fielding_plan_id INT UNSIGNED NOT NULL,
    player_id INT UNSIGNED NULL COMMENT 'Can be NULL for unnamed positions in generic templates',
    fielding_position_id INT UNSIGNED NOT NULL,
    position_number TINYINT NOT NULL COMMENT '1-11 for player numbering',
    player_role VARCHAR(50) NULL COMMENT 'Batsman, Bowler, AllRounder, Keeper',
    coordinate_x DECIMAL(5,2) NULL COMMENT 'X coordinate on field visualization',
    coordinate_y DECIMAL(5,2) NULL COMMENT 'Y coordinate on field visualization',
    is_substitute TINYINT(1) DEFAULT 0,
    notes VARCHAR(255) NULL,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_plan_position_number (fielding_plan_id, position_number),
    KEY idx_plan_player (fielding_plan_id, player_id),
    KEY idx_fielding_position (fielding_position_id),
    CONSTRAINT fk_plan_players_plan FOREIGN KEY (fielding_plan_id) 
        REFERENCES fielding_plans (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_plan_players_player FOREIGN KEY (player_id) 
        REFERENCES players (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_plan_players_position FOREIGN KEY (fielding_position_id) 
        REFERENCES fielding_positions (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Player-position assignments in fielding templates';

-- -------------------------------------------------------------------------------------
-- 22. MATCH FIELDING SETUP (Which plan used in which over)
-- ----------------------------------------------------------------------------

CREATE TABLE match_fielding_setups (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    match_id INT UNSIGNED NOT NULL,
    team_id INT UNSIGNED NOT NULL,
    inning_number INT UNSIGNED NOT NULL,
    over_number INT UNSIGNED NOT NULL,
    ball_number INT UNSIGNED NULL COMMENT 'Null = applies to entire over',
    fielding_plan_id INT UNSIGNED NULL COMMENT 'Reference to predefined plan if used',
    setup_name VARCHAR(100) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    PRIMARY KEY (id),
    KEY idx_match_team_inning (match_id, team_id, inning_number),
    KEY idx_over_ball (over_number, ball_number),
    KEY idx_fielding_plan (fielding_plan_id),
    CONSTRAINT fk_fielding_setup_match FOREIGN KEY (match_id) 
        REFERENCES matches (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_setup_team FOREIGN KEY (team_id) 
        REFERENCES teams (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_setup_plan FOREIGN KEY (fielding_plan_id) 
        REFERENCES fielding_plans (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Actual fielding setup used in matches';

-- ----------------------------------------------------------------------------
-- 23. FIELDING SCORING SESSIONS (Inning-level team selection)
-- ----------------------------------------------------------------------------

CREATE TABLE fielding_scoring_sessions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    match_id INT UNSIGNED NOT NULL,
    inning_number INT UNSIGNED NOT NULL,
    batting_team_id INT UNSIGNED NOT NULL,
    bowling_team_id INT UNSIGNED NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'STARTED' COMMENT 'NOT_STARTED|STARTED|ENDED',
    started_at DATETIME DEFAULT NULL,
    ended_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    updated_by INT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY unique_match_inning (match_id, inning_number),
    KEY idx_session_match (match_id),
    KEY idx_session_status (status),
    CONSTRAINT fk_fielding_session_match FOREIGN KEY (match_id)
        REFERENCES matches (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_session_batting_team FOREIGN KEY (batting_team_id)
        REFERENCES teams (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fielding_session_bowling_team FOREIGN KEY (bowling_team_id)
        REFERENCES teams (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Inning-level fielding scoring session team selection';

-- ============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

CREATE INDEX idx_fielding_scoring_player_match ON fielding_scoring(primary_fielder_id, match_id);
CREATE INDEX idx_fielding_scoring_runs_analysis ON fielding_scoring(actual_runs_scored, runs_saved, runs_cost);
CREATE INDEX idx_fielding_scoring_quality ON fielding_scoring(fielding_quality_score);
CREATE INDEX idx_ball_positions_setup ON ball_fielding_positions(fielding_scoring_id, position_number);

-- ============================================================================
-- SAMPLE DATA INSERTION - LOOKUP TABLES
-- ============================================================================

-- Position Categories
INSERT INTO position_categories (category_name, category_description, is_active, created_at, updated_at) VALUES
('KEEPER', 'Wicket Keeper Position', 1, NOW(), NOW()),
('CLOSE_IN', 'Close In Fielding Positions', 1, NOW(), NOW()),
('INFIELD', 'Infield Positions', 1, NOW(), NOW()),
('OUTFIELD', 'Outfield/Boundary Positions', 1, NOW(), NOW());

-- Fielding Positions
INSERT INTO fielding_positions (position_code, position_name, position_category_id, display_order, is_active, created_at, updated_at, created_by, updated_by) VALUES
('BWK', 'Wicket Keeper', 1, 1, 1, NOW(), NOW(), 1, 1),
('SL', 'Slip', 2, 2, 1, NOW(), NOW(), 1, 1),
('S', 'Short Cover', 2, 3, 1, NOW(), NOW(), 1, 1),
('C', 'Cover', 3, 4, 1, NOW(), NOW(), 1, 1),
('MC', 'Mid-wicket', 3, 5, 1, NOW(), NOW(), 1, 1),
('B', 'Bowler', 2, 6, 1, NOW(), NOW(), 1, 1),
('MW', 'Mid-wicket', 3, 7, 1, NOW(), NOW(), 1, 1),
('M', 'Mid-on/Mid-off', 3, 8, 1, NOW(), NOW(), 1, 1),
('F', 'Fine Leg', 4, 9, 1, NOW(), NOW(), 1, 1),
('SA', 'Square Leg', 3, 10, 1, NOW(), NOW(), 1, 1),
('L', 'Long-on/Long-off', 4, 11, 1, NOW(), NOW(), 1, 1),
('POINT', 'Point', 3, 12, 1, NOW(), NOW(), 1, 1),
('COLSP', 'Gully/Colsp', 2, 13, 1, NOW(), NOW(), 1, 1),
('DP', 'Deep Point', 4, 14, 1, NOW(), NOW(), 1, 1),
('FLYSLIP', 'Fly Slip', 4, 15, 1, NOW(), NOW(), 1, 1),
('RP', 'Reeps Point', 3, 16, 1, NOW(), NOW(), 1, 1),
('DC', 'Deep Cover', 4, 17, 1, NOW(), NOW(), 1, 1),
('SIM', 'Silly Mid-on/off', 2, 18, 1, NOW(), NOW(), 1, 1),
('LS', 'Long Stop', 4, 19, 1, NOW(), NOW(), 1, 1),
('OS', 'Off Side', 3, 20, 1, NOW(), NOW(), 1, 1);

-- Fielding Action Categories
INSERT INTO fielding_action_categories (category_name, category_description, is_active, created_at, updated_at) VALUES
('GROUND_FIELDING', 'Ground fielding actions', 1, NOW(), NOW()),
('CATCH', 'Catching actions', 1, NOW(), NOW()),
('THROW', 'Throwing actions', 1, NOW(), NOW()),
('RUN_OUT', 'Run out involvements', 1, NOW(), NOW()),
('KEEPER', 'Wicketkeeping actions', 1, NOW(), NOW());

-- Fielding Action Types
INSERT INTO fielding_action_types (action_category_id, action_code, action_name, display_order, is_positive, is_active, created_at, updated_at) VALUES
-- Ground Fielding (category_id = 1)
(1, 'CLEAN_PICKUP', 'Clean Pickup', 1, 1, 1, NOW(), NOW()),
(1, 'ONE_HAND_PICKUP', 'One-Hand Pickup', 2, 1, 1, NOW(), NOW()),
(1, 'TWO_HAND_PICKUP', 'Two-Hand Pickup', 3, 1, 1, NOW(), NOW()),
(1, 'SLIDE_STOP', 'Slide Stop', 4, 1, 1, NOW(), NOW()),
(1, 'DIVE_STOP', 'Dive Stop', 5, 1, 1, NOW(), NOW()),
(1, 'MISJUDGE', 'Misjudge', 6, 0, 1, NOW(), NOW()),
(1, 'FUMBLE', 'Fumble', 7, 0, 1, NOW(), NOW()),
(1, 'MISS_FIELD', 'Miss Field', 8, 0, 1, NOW(), NOW()),

-- Catch (category_id = 2)
(2, 'CLEAN_CATCH', 'Clean Catch', 10, 1, 1, NOW(), NOW()),
(2, 'DROP_CATCH', 'Drop Catch', 11, 0, 1, NOW(), NOW()),
(2, 'GLEAN_CATCH', 'Glean Catch', 12, 1, 1, NOW(), NOW()),
(2, 'PARRIED_CATCH', 'Parried Catch', 13, 0, 1, NOW(), NOW()),

-- Throw (category_id = 3)
(3, 'DIRECT_HIT', 'Direct Hit', 20, 1, 1, NOW(), NOW()),
(3, 'ONE_BOUNCE', 'One Bounce', 21, 1, 1, NOW(), NOW()),
(3, 'MISSED_TARGET', 'Missed Target', 22, 0, 1, NOW(), NOW()),
(3, 'OVERTHROW', 'Overthrow', 23, 0, 1, NOW(), NOW()),
(3, 'RELAY_THROW', 'Relay Throw', 24, 1, 1, NOW(), NOW()),

-- Run Out (category_id = 4)
(4, 'DIRECT_RUNOUT', 'Direct Run Out', 30, 1, 1, NOW(), NOW()),
(4, 'ASSISTED_RUNOUT', 'Assisted Run Out', 31, 1, 1, NOW(), NOW());

-- Pickup Types
INSERT INTO pickup_types (pickup_code, pickup_name, display_order, is_active, created_at, updated_at) VALUES
('CLEAN_PICKUP', 'Clean Pickup', 1, 1, NOW(), NOW()),
('ONE_HAND', 'One-Hand Pickup', 2, 1, NOW(), NOW()),
('TWO_HAND', 'Two-Hand Pickup', 3, 1, NOW(), NOW()),
('SLIDE_STOP', 'Slide Stop', 4, 1, NOW(), NOW()),
('DIVE_STOP', 'Dive Stop', 5, 1, NOW(), NOW());

-- Throw Types
INSERT INTO throw_types (throw_code, throw_name, display_order, is_active, created_at, updated_at) VALUES
('DIRECT_HIT', 'Direct Hit', 1, 1, NOW(), NOW()),
('ONE_BOUNCE', 'One Bounce', 2, 1, NOW(), NOW()),
('MISSED_TARGET', 'Missed Target', 3, 1, NOW(), NOW()),
('OVERTHROW', 'Overthrow', 4, 1, NOW(), NOW()),
('NO_THROW', 'No Throw Required', 5, 1, NOW(), NOW());

-- Throw Techniques
INSERT INTO throw_techniques (technique_code, technique_name, display_order, is_active, created_at, updated_at) VALUES
('OVERARM', 'Overarm', 1, 1, NOW(), NOW()),
('UNDERARM', 'Underarm', 2, 1, NOW(), NOW()),
('SIDEARM', 'Sidearm', 3, 1, NOW(), NOW()),
('RESOLVERS', 'Resolvers', 4, 1, NOW(), NOW());

-- Catch Difficulty Levels
INSERT INTO catch_difficulty_levels (difficulty_code, difficulty_name, display_order, is_active, created_at, updated_at) VALUES
('EASY', 'Easy', 1, 1, NOW(), NOW()),
('MEDIUM', 'Medium', 2, 1, NOW(), NOW()),
('HARD', 'Hard', 3, 1, NOW(), NOW());

-- Athletic Quality Ratings
INSERT INTO athletic_quality_ratings (rating_code, rating_name, rating_value, display_order, is_active, created_at, updated_at) VALUES
('EXCELLENT', 'Excellent', 1.00, 1, 1, NOW(), NOW()),
('GOOD', 'Good', 0.75, 2, 1, NOW(), NOW()),
('BALANCED', 'Balanced', 0.50, 3, 1, NOW(), NOW()),
('RESTRICTED', 'Restricted', 0.30, 4, 1, NOW(), NOW()),
('POOR', 'Poor', 0.10, 5, 1, NOW(), NOW());

-- Backup Observation Types
INSERT INTO backup_observation_types (observation_code, observation_name, is_positive, display_order, is_active, created_at, updated_at) VALUES
('IN_POSITION', 'In Position', 1, 1, 1, NOW(), NOW()),
('LATE_REACTION', 'Late Reaction', 0, 2, 1, NOW(), NOW()),
('NOT_IN_POSITION', 'Not in Position', 0, 3, 1, NOW(), NOW()),
('OVERRAN_BACKUP', 'Overran Backup Line', 0, 4, 1, NOW(), NOW()),
('WRONG_ANGLE', 'Wrong Angle', 0, 5, 1, NOW(), NOW());

-- Error Types
INSERT INTO error_types (error_code, error_name, display_order, is_active, created_at, updated_at) VALUES
('MISJUDGE', 'Misjudge', 1, 1, NOW(), NOW()),
('FUMBLE', 'Fumble', 2, 1, NOW(), NOW()),
('OVERTHROW', 'Overthrow', 3, 1, NOW(), NOW()),
('BALL_THROUGH_LEGS', 'Ball Through Legs', 4, 1, NOW(), NOW()),
('WRONG_FOOTWORK', 'Wrong Footwork', 5, 1, NOW(), NOW()),
('MISFIELD_SOFT', 'Misfield (Soft)', 6, 1, NOW(), NOW()),
('MISFIELD_HARD', 'Misfield (Hard)', 7, 1, NOW(), NOW());

-- Keeper Context Types
INSERT INTO keeper_context_types (context_code, context_name, is_active, created_at, updated_at) VALUES
('PACER', 'Facing Pacer', 1, NOW(), NOW()),
('SPINNER', 'Facing Spinner', 1, NOW(), NOW());

-- Keeper Standing Positions
INSERT INTO keeper_standing_positions (position_code, position_name, is_active, created_at, updated_at) VALUES
('UP_TO_STUMPS', 'Up to the Stumps', 1, NOW(), NOW()),
('BACK', 'Standing Back', 1, NOW(), NOW());

-- Batting Context Types
INSERT INTO batting_context_types (context_code, context_name, is_active, created_at, updated_at) VALUES
('POWERPLAY', 'Powerplay', 1, NOW(), NOW()),
('MIDDLE_OVERS', 'Middle Overs', 1, NOW(), NOW()),
('DEATH_OVERS', 'Death Overs', 1, NOW(), NOW()),
('GENERAL', 'General', 1, NOW(), NOW());

-- Handedness Types
INSERT INTO handedness_types (handedness_code, handedness_name, is_active, created_at, updated_at) VALUES
('LEFT_HAND', 'Left Hand', 1, NOW(), NOW()),
('RIGHT_HAND', 'Right Hand', 1, NOW(), NOW()),
('BOTH', 'Both', 1, NOW(), NOW());

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
(9, 'Left Arm Chinaman', 'LAC', NOW(), NOW());