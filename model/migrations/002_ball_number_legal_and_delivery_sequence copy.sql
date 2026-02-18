-- ============================================================================
-- Migration: ball_number 1-6 only; delivery_sequence for order within over
-- Run after 001. Adds delivery_sequence, backfills ball_number to legal index.
-- ============================================================================

-- 1. Add delivery_sequence column (default 1 for existing rows)
ALTER TABLE fielding_scoring
    ADD COLUMN delivery_sequence INT UNSIGNED NOT NULL DEFAULT 1
    COMMENT '1-based delivery index within the over'
    AFTER ball_number;

-- 2. Preserve current order: set delivery_sequence = current ball_number
UPDATE fielding_scoring SET delivery_sequence = ball_number;

-- 3. Backfill ball_number to legal index (1-6) per over
--    Legal slot = 1 + (count of previous legal deliveries in same over)
CREATE TEMPORARY TABLE IF NOT EXISTS _fs_ball_backfill AS
SELECT
    id,
    LEAST(
        1 + COALESCE(
            SUM(CASE WHEN ball_type_id NOT IN (2, 3) THEN 1 ELSE 0 END) OVER (
                PARTITION BY match_id, inning_number, over_number
                ORDER BY delivery_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
        ),
        6
    ) AS new_ball_number
FROM fielding_scoring;

UPDATE fielding_scoring fs
INNER JOIN _fs_ball_backfill b ON fs.id = b.id
SET fs.ball_number = b.new_ball_number;

DROP TEMPORARY TABLE IF EXISTS _fs_ball_backfill;

-- 4. Drop old unique key, add new one on delivery_sequence
ALTER TABLE fielding_scoring
    DROP INDEX unique_match_ball,
    ADD UNIQUE KEY unique_match_delivery (match_id, inning_number, over_number, delivery_sequence);

-- 5. Comment: ball_number is legal 1-6
ALTER TABLE fielding_scoring
    MODIFY COLUMN ball_number INT UNSIGNED NOT NULL
    COMMENT 'Legal ball index 1-6; same number for extra and replacement (order by delivery_sequence)';
