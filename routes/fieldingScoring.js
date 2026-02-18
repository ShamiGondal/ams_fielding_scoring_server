const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * POST /api/fielding-scoring/sync
 * Sync a single fielding scoring record from offline storage to cloud
 */
router.post('/sync', async (req, res) => {
    try {
        const {
            match_id, inning_number, over_number, ball_number, delivery_sequence,
            primary_fielder_id, primary_fielder_position_id,
            fielding_action_type_id,
            actual_runs_scored, runs_saved, runs_cost, potential_runs,
            pickup_type_id, throw_type_id, throw_technique_id, throw_accuracy_id,
            anticipation_rating_id, agility_rating_id,
            backup_observation_id, error_type_id,
            handedness_id, batting_context_id, keeper_context_id, keeper_standing_position_id,
            ball_arrival_x, ball_arrival_y, wagon_wheel_x, wagon_wheel_y,
            resulted_in_wicket, resulted_in_boundary, is_dot_ball,
            fielding_notes, video_timestamp, fielding_quality_score,
            recorded_by_user_id, created_by, updated_by,
            relay_fielder_id, relay_fielder_position_id,
            receiver_fielder_id, receiver_fielder_position_id,
            catch_difficulty_id, catch_result_id,
            striker_id, dismissed_batsman_id, ball_type_id
        } = req.body;

        if (delivery_sequence == null || delivery_sequence < 1) {
            return res.status(400).json({ success: false, error: 'delivery_sequence is required and must be >= 1' });
        }
        const ballNum = ball_number != null ? Number(ball_number) : 1;
        if (ballNum < 1 || ballNum > 6) {
            return res.status(400).json({ success: false, error: 'ball_number must be between 1 and 6' });
        }

        const [result] = await db.execute(
            `INSERT INTO fielding_scoring (
        match_id, inning_number, over_number, ball_number, delivery_sequence,
        striker_id, dismissed_batsman_id, ball_type_id,
        primary_fielder_id, primary_fielder_position_id,
        relay_fielder_id, relay_fielder_position_id,
        receiver_fielder_id, receiver_fielder_position_id,
        fielding_action_type_id,
        actual_runs_scored, runs_saved, runs_cost, potential_runs,
        pickup_type_id, catch_difficulty_id, catch_result_id,
        throw_type_id, throw_technique_id, throw_accuracy_id,
        anticipation_rating_id, agility_rating_id,
        backup_observation_id, error_type_id,
        handedness_id, batting_context_id, keeper_context_id, keeper_standing_position_id,
        ball_arrival_x, ball_arrival_y, wagon_wheel_x, wagon_wheel_y,
        resulted_in_wicket, resulted_in_boundary, is_dot_ball,
        fielding_notes, video_timestamp, fielding_quality_score,
        recorded_by_user_id, is_verified,
        created_at, updated_at, created_by, updated_by
      ) VALUES (
        ?, ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?,
        ?, ?,
        ?, ?,
        ?,
        ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?,
        ?, ?,
        ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?,
        ?, 0,
        NOW(), NOW(), ?, ?
      )`,
            [
                match_id, inning_number, over_number, ballNum, delivery_sequence,
                striker_id || null, dismissed_batsman_id || null, ball_type_id != null ? ball_type_id : 1,
                primary_fielder_id, primary_fielder_position_id,
                relay_fielder_id, relay_fielder_position_id,
                receiver_fielder_id, receiver_fielder_position_id,
                fielding_action_type_id,
                actual_runs_scored || 0, runs_saved || 0, runs_cost || 0, potential_runs || 0,
                pickup_type_id, catch_difficulty_id, catch_result_id,
                throw_type_id, throw_technique_id, throw_accuracy_id,
                anticipation_rating_id, agility_rating_id,
                backup_observation_id, error_type_id,
                handedness_id, batting_context_id, keeper_context_id, keeper_standing_position_id,
                ball_arrival_x, ball_arrival_y, wagon_wheel_x, wagon_wheel_y,
                resulted_in_wicket || 0, resulted_in_boundary || 0, is_dot_ball || 0,
                fielding_notes, video_timestamp, fielding_quality_score,
                recorded_by_user_id,
                created_by, updated_by
            ]
        );

        res.json({
            success: true,
            cloud_id: result.insertId,
            status: 'synced',
            synced_at: new Date()
        });
    } catch (error) {
        console.error('Sync error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            code: error.code
        });
    }
});

/**
 * POST /api/fielding-scoring/batch-sync
 * Sync multiple fielding scoring records in a batch
 */
router.post('/batch-sync', async (req, res) => {
    const { match_id, records, ball_positions } = req.body;

    const connection = await db.getConnection();
    await connection.beginTransaction();

    // ========================================================================
    // VALIDATION HELPER FUNCTIONS
    // ========================================================================

    /**
     * Check if a record exists in a table
     */
    async function checkExists(table, id) {
        if (!id || id === 0) return false;
        // Use query() instead of execute() because execute() (prepared statements) 
        // does not support ?? (identifier placeholders)
        const [rows] = await connection.query(
            `SELECT id FROM ?? WHERE id = ? LIMIT 1`,
            [table, id]
        );
        return rows.length > 0;
    }

    /**
     * Helper to list undefined fields for debugging
     */
    function getUndefinedFields(record, fields) {
        return fields.filter((field) => record[field] === undefined);
    }

    /**
     * Comprehensive validation for fielding scoring record
     */
    async function validateFieldingScoringRecord(record) {
        const errors = [];

        // Required field validation
        if (!record.match_id || record.match_id === 0) {
            errors.push('match_id is required and must be > 0');
        }
        if (!record.primary_fielder_id || record.primary_fielder_id === 0) {
            errors.push('primary_fielder_id is required and must be > 0');
        }
        if (!record.primary_fielder_position_id || record.primary_fielder_position_id === 0) {
            errors.push('primary_fielder_position_id is required and must be > 0');
        }
        if (!record.fielding_action_type_id || record.fielding_action_type_id === 0) {
            errors.push('fielding_action_type_id is required and must be > 0');
        }
        if (!record.recorded_by_user_id || record.recorded_by_user_id === 0) {
            errors.push('recorded_by_user_id is required and must be > 0');
        }
        if (record.delivery_sequence == null || record.delivery_sequence < 1) {
            errors.push('delivery_sequence is required and must be >= 1');
        }
        const bn = record.ball_number != null ? Number(record.ball_number) : 1;
        if (bn < 1 || bn > 6) {
            errors.push('ball_number must be between 1 and 6');
        }

        // FK validation (check if references exist)
        if (record.match_id && record.match_id > 0) {
            const matchExists = await checkExists('matches', record.match_id);
            if (!matchExists) {
                errors.push(`match_id ${record.match_id} not found in matches table`);
            }
        }

        if (record.primary_fielder_id && record.primary_fielder_id > 0) {
            const playerExists = await checkExists('players', record.primary_fielder_id);
            if (!playerExists) {
                errors.push(`primary_fielder_id ${record.primary_fielder_id} not found in players table`);
            }
        }

        if (record.primary_fielder_position_id && record.primary_fielder_position_id > 0) {
            const posExists = await checkExists('fielding_positions', record.primary_fielder_position_id);
            if (!posExists) {
                errors.push(`primary_fielder_position_id ${record.primary_fielder_position_id} not found in fielding_positions table`);
            }
        }

        if (record.fielding_action_type_id && record.fielding_action_type_id > 0) {
            const actionExists = await checkExists('fielding_action_types', record.fielding_action_type_id);
            if (!actionExists) {
                errors.push(`fielding_action_type_id ${record.fielding_action_type_id} not found in fielding_action_types table`);
            }
        }

        // Optional FK fields - only validate if provided and > 0
        if (record.pickup_type_id && record.pickup_type_id > 0) {
            const exists = await checkExists('pickup_types', record.pickup_type_id);
            if (!exists) errors.push(`pickup_type_id ${record.pickup_type_id} not found`);
        }

        if (record.throw_type_id && record.throw_type_id > 0) {
            const exists = await checkExists('throw_types', record.throw_type_id);
            if (!exists) errors.push(`throw_type_id ${record.throw_type_id} not found`);
        }

        if (record.backup_observation_id && record.backup_observation_id > 0) {
            const exists = await checkExists('backup_observation_types', record.backup_observation_id);
            if (!exists) errors.push(`backup_observation_id ${record.backup_observation_id} not found`);
        }

        if (record.error_type_id && record.error_type_id > 0) {
            const exists = await checkExists('error_types', record.error_type_id);
            if (!exists) errors.push(`error_type_id ${record.error_type_id} not found`);
        }

        if (record.handedness_id && record.handedness_id > 0) {
            const exists = await checkExists('handedness_types', record.handedness_id);
            if (!exists) errors.push(`handedness_id ${record.handedness_id} not found`);
        }

        if (record.batting_context_id && record.batting_context_id > 0) {
            const exists = await checkExists('batting_context_types', record.batting_context_id);
            if (!exists) errors.push(`batting_context_id ${record.batting_context_id} not found`);
        }

        if (record.keeper_context_id && record.keeper_context_id > 0) {
            const exists = await checkExists('keeper_context_types', record.keeper_context_id);
            if (!exists) errors.push(`keeper_context_id ${record.keeper_context_id} not found`);
        }

        if (record.keeper_standing_position_id && record.keeper_standing_position_id > 0) {
            const exists = await checkExists('keeper_standing_positions', record.keeper_standing_position_id);
            if (!exists) errors.push(`keeper_standing_position_id ${record.keeper_standing_position_id} not found`);
        }

        if (record.striker_id && record.striker_id > 0) {
            const exists = await checkExists('players', record.striker_id);
            if (!exists) errors.push(`striker_id ${record.striker_id} not found`);
        }
        if (record.dismissed_batsman_id && record.dismissed_batsman_id > 0) {
            const exists = await checkExists('players', record.dismissed_batsman_id);
            if (!exists) errors.push(`dismissed_batsman_id ${record.dismissed_batsman_id} not found`);
        }
        const ballTypeId = record.ball_type_id != null && record.ball_type_id > 0 ? record.ball_type_id : 1;
        const ballTypeExists = await checkExists('ball_types', ballTypeId);
        if (!ballTypeExists) errors.push(`ball_type_id ${ballTypeId} not found in ball_types`);

        return { valid: errors.length === 0, errors };
    }

    // ========================================================================
    // BATCH SYNC LOGIC
    // ========================================================================

    try {
        const synced_ids = [];
        const failed_ids = [];
        const errors = [];

        for (const record of records || []) {
            try {
                // STEP 1: Validate the record
                const validation = await validateFieldingScoringRecord(record);
                if (!validation.valid) {
                    throw new Error(`Validation failed: ${validation.errors.join('; ')}`);
                }

                // STEP 2: Helper to convert undefined/0 to null for optional FKs
                const n = (val) => {
                    if (val === undefined || val === null) return null;
                    // Treat 0 as null for FK fields (but not for runs/scores)
                    if (typeof val === 'number' && val === 0) return null;
                    return val;
                };

                // STEP 3: Insert fielding scoring record (Idempotent UPSERT)
                const recordedBy = record.recorded_by_user_id ?? record.created_by ?? record.updated_by;
                const ballTypeId = record.ball_type_id != null && record.ball_type_id > 0 ? record.ball_type_id : 1;
                const [result] = await connection.execute(
                    `INSERT INTO fielding_scoring (
            match_id, inning_number, over_number, ball_number, delivery_sequence,
            striker_id, dismissed_batsman_id, ball_type_id,
            primary_fielder_id, primary_fielder_position_id,
            relay_fielder_id, relay_fielder_position_id,
            receiver_fielder_id, receiver_fielder_position_id,
            fielding_action_type_id,
            actual_runs_scored, runs_saved, runs_cost, potential_runs,
            pickup_type_id, catch_difficulty_id, catch_result_id,
            throw_type_id, throw_technique_id, throw_accuracy_id,
            anticipation_rating_id, agility_rating_id,
            backup_observation_id, error_type_id,
            handedness_id, batting_context_id, keeper_context_id, keeper_standing_position_id,
            ball_arrival_x, ball_arrival_y, wagon_wheel_x, wagon_wheel_y,
            resulted_in_wicket, resulted_in_boundary, is_dot_ball,
            fielding_notes, video_timestamp, fielding_quality_score,
            recorded_by_user_id, created_at, updated_at, created_by, updated_by
          ) VALUES (
            ?, ?, ?, ?, ?,
            ?, ?, ?,
            ?, ?,
            ?, ?,
            ?, ?,
            ?,
            ?, ?, ?, ?,
            ?, ?, ?,
            ?, ?, ?,
            ?, ?,
            ?, ?,
            ?, ?, ?, ?,
            ?, ?, ?, ?,
            ?, ?, ?,
            ?, ?, ?,
            ?, NOW(), NOW(), ?, ?
          )
          ON DUPLICATE KEY UPDATE
            id = LAST_INSERT_ID(id),
            ball_number = VALUES(ball_number),
            striker_id = VALUES(striker_id),
            dismissed_batsman_id = VALUES(dismissed_batsman_id),
            ball_type_id = VALUES(ball_type_id),
            primary_fielder_id = VALUES(primary_fielder_id),
            primary_fielder_position_id = VALUES(primary_fielder_position_id),
            relay_fielder_id = VALUES(relay_fielder_id),
            relay_fielder_position_id = VALUES(relay_fielder_position_id),
            receiver_fielder_id = VALUES(receiver_fielder_id),
            receiver_fielder_position_id = VALUES(receiver_fielder_position_id),
            fielding_action_type_id = VALUES(fielding_action_type_id),
            actual_runs_scored = VALUES(actual_runs_scored),
            runs_saved = VALUES(runs_saved),
            runs_cost = VALUES(runs_cost),
            potential_runs = VALUES(potential_runs),
            pickup_type_id = VALUES(pickup_type_id),
            catch_difficulty_id = VALUES(catch_difficulty_id),
            catch_result_id = VALUES(catch_result_id),
            throw_type_id = VALUES(throw_type_id),
            throw_technique_id = VALUES(throw_technique_id),
            throw_accuracy_id = VALUES(throw_accuracy_id),
            anticipation_rating_id = VALUES(anticipation_rating_id),
            agility_rating_id = VALUES(agility_rating_id),
            backup_observation_id = VALUES(backup_observation_id),
            error_type_id = VALUES(error_type_id),
            handedness_id = VALUES(handedness_id),
            batting_context_id = VALUES(batting_context_id),
            keeper_context_id = VALUES(keeper_context_id),
            keeper_standing_position_id = VALUES(keeper_standing_position_id),
            ball_arrival_x = VALUES(ball_arrival_x),
            ball_arrival_y = VALUES(ball_arrival_y),
            wagon_wheel_x = VALUES(wagon_wheel_x),
            wagon_wheel_y = VALUES(wagon_wheel_y),
            resulted_in_wicket = VALUES(resulted_in_wicket),
            resulted_in_boundary = VALUES(resulted_in_boundary),
            is_dot_ball = VALUES(is_dot_ball),
            fielding_notes = VALUES(fielding_notes),
            video_timestamp = VALUES(video_timestamp),
            fielding_quality_score = VALUES(fielding_quality_score),
            recorded_by_user_id = VALUES(recorded_by_user_id),
            updated_at = NOW(),
            updated_by = VALUES(updated_by)`,
                    [
                        record.match_id, record.inning_number,
                        record.over_number, record.ball_number,
                        record.delivery_sequence ?? record.ball_number,
                        n(record.striker_id), n(record.dismissed_batsman_id), ballTypeId,
                        record.primary_fielder_id, record.primary_fielder_position_id,
                        n(record.relay_fielder_id), n(record.relay_fielder_position_id),
                        n(record.receiver_fielder_id), n(record.receiver_fielder_position_id),
                        record.fielding_action_type_id,
                        record.actual_runs_scored ?? 0, record.runs_saved ?? 0,
                        record.runs_cost ?? 0, record.potential_runs ?? 0,
                        n(record.pickup_type_id), n(record.catch_difficulty_id), n(record.catch_result_id),
                        n(record.throw_type_id), n(record.throw_technique_id), n(record.throw_accuracy_id),
                        n(record.anticipation_rating_id), n(record.agility_rating_id),
                        n(record.backup_observation_id), n(record.error_type_id),
                        n(record.handedness_id), n(record.batting_context_id),
                        n(record.keeper_context_id), n(record.keeper_standing_position_id),
                        n(record.ball_arrival_x), n(record.ball_arrival_y),
                        n(record.wagon_wheel_x), n(record.wagon_wheel_y),
                        record.resulted_in_wicket ? 1 : 0,
                        record.resulted_in_boundary ? 1 : 0,
                        record.is_dot_ball ? 1 : 0,
                        n(record.fielding_notes), n(record.video_timestamp), n(record.fielding_quality_score),
                        recordedBy, record.created_by ?? recordedBy, record.updated_by ?? recordedBy
                    ]
                );

                // For upserts, insertId might be 0. Use LAST_INSERT_ID() to get actual row id
                const actualId = result.insertId || (await connection.query('SELECT LAST_INSERT_ID() as id'))[0][0].id;
                
                synced_ids.push({
                    local_id: record.local_id,
                    cloud_id: actualId
                });
            } catch (err) {
                const undefinedFields = getUndefinedFields(record, [
                    'match_id', 'inning_number', 'over_number', 'ball_number', 'delivery_sequence',
                    'primary_fielder_id', 'primary_fielder_position_id',
                    'fielding_action_type_id', 'recorded_by_user_id'
                ]);
                if (undefinedFields.length > 0) {
                    console.warn(`⚠️ Undefined fields for record ${record.local_id}:`, undefinedFields);
                }
                console.warn(`❌ Record sync failed for local_id ${record.local_id}:`, err.message);
                failed_ids.push(record.local_id);
                errors.push({
                    record_id: record.local_id,
                    error: err.message,
                    error_type: err.code || 'VALIDATION_ERROR',
                    code: err.code
                });
            }
        }

        // ========================================================================
        // SYNC BALL POSITIONS
        // ========================================================================
        if (ball_positions && Array.isArray(ball_positions) && ball_positions.length > 0) {
            console.log(`Processing ${ball_positions.length} ball positions...`);

            for (const pos of ball_positions) {
                try {
                    // First, find the parent fielding_scoring_id
                    // Note: The position comes with a 'fielding_scoring_local_id' (UUID)
                    // We need to resolve this to the MySQL ID from the 'fielding_scoring' table
                    // We can either:
                    // 1. Look it up in the just-synced IDs list (synced_ids)
                    // 2. Or query DB by match/over/ball unique key

                    let mysql_fielding_scoring_id = null;

                    // Method 1: Check if parent was just synced in this batch
                    const parentSync = synced_ids.find(s => s.local_id === pos.fielding_scoring_local_id);
                    if (parentSync) {
                        mysql_fielding_scoring_id = parentSync.cloud_id;
                    }

                    // Method 2: If not found (maybe parent synced earlier), we need match/over/ball
                    // But ball_positions payload might not have match context.
                    // Ideally, the frontend should send positions with enough context or we assume parent is present.
                    // For now, if we can't find the parent ID, we might skip or try to look up.

                    if (!mysql_fielding_scoring_id) {
                        // Fallback: If we have match/over/ball in the position payload (frontend should send it)
                        // OR if we can query by the local UUID if we stored it (we don't store local UUID in MySQL currently)
                        // This is a known limitation. For now, we only support syncing positions if parent is also syncing OR strictly relying on the context provided.

                        // If the position object has match_id, over, ball... (it currently doesn't in BallFieldingPositionLocal)
                        // We will rely on getting the match_scoring_id or fielding_scoring_id from frontend if possible, 
                        // but frontend typically sends local IDs.

                        // CRITICAL: We need a way to link.
                        // Assumption: For this fix, we will only succeed if the parent record is EITHER in this batch OR we can find it by match/over/ball if provided.
                        // Ideally, we should add 'local_id' column to MySQL to map easily, but we can't modify schema right now easily.

                        // If parent is not in this batch, we skip for now and report error.
                        // But wait! SyncManager sends `records` (just synced) and `ball_positions` separately? 
                        // No, SyncManager.ts currently sends mixed batch or separate?
                        // The plan is to separate them.

                        // If we are syncing positions separately, we assume the parent IS ALREADY SYNCED.
                        // We need to find the parent ID.
                        // The position has `match_id`, `inning`, `over`, `ball` added by frontend SyncManager.

                        if (pos.match_id != null && (pos.delivery_sequence != null || pos.ball != null)) {
                            const deliverySeq = pos.delivery_sequence ?? pos.ball;
                            const [rows] = await connection.query(
                                `SELECT id FROM fielding_scoring 
                                  WHERE match_id = ? AND inning_number = ? AND over_number = ? AND delivery_sequence = ?
                                  LIMIT 1`,
                                [pos.match_id, pos.inning_number, pos.over_number, deliverySeq]
                            );
                            if (rows.length > 0) mysql_fielding_scoring_id = rows[0].id;
                        }
                    }

                    if (!mysql_fielding_scoring_id) {
                        throw new Error(`Parent fielding_scoring record not found for local_id ${pos.fielding_scoring_local_id}`);
                    }

                    // Insert/Update position
                    // We use DELETE + INSERT strategy for positions for a specific ball to ensure clean slate, OR upsert.
                    // Uniqueness is (fielding_scoring_id, player_id) from schema: UNIQUE KEY unique_fielding_scoring_player

                    const undefinedPosFields = getUndefinedFields(pos, [
                        'player_id',
                        'fielding_position_id',
                        'position_number',
                        'position_x',
                        'position_y',
                        'is_keeper',
                        'is_primary_fielder',
                        'is_backup'
                    ]);
                    if (undefinedPosFields.length > 0) {
                        console.warn(`⚠️ Undefined position fields for ${pos.fielding_scoring_local_id}:`, undefinedPosFields);
                    }
                    
                    console.log('📥 Server received position:', {
                        player_id: pos.player_id,
                        position_number: pos.position_number,
                        position_x: pos.position_x,
                        position_y: pos.position_y,
                        is_keeper: pos.is_keeper,
                        is_primary_fielder: pos.is_primary_fielder
                    });

                    await connection.execute(`
                        INSERT INTO ball_fielding_positions (
                            fielding_scoring_id, player_id, fielding_position_id,
                            position_number, position_x, position_y,
                            is_keeper, is_primary_fielder, is_backup,
                            created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
                        ON DUPLICATE KEY UPDATE
                            fielding_position_id = VALUES(fielding_position_id),
                            position_x = VALUES(position_x),
                            position_y = VALUES(position_y),
                            is_keeper = VALUES(is_keeper),
                            is_primary_fielder = VALUES(is_primary_fielder),
                            is_backup = VALUES(is_backup),
                            updated_at = NOW()
                    `, [
                        mysql_fielding_scoring_id,
                        pos.player_id ?? null,
                        pos.fielding_position_id ?? null,
                        pos.position_number ?? null,
                        pos.position_x ?? null,
                        pos.position_y ?? null,
                        pos.is_keeper ? 1 : 0,
                        pos.is_primary_fielder ? 1 : 0,
                        pos.is_backup ? 1 : 0
                    ]);

                    synced_ids.push({
                        local_id: pos.local_id,
                        cloud_id: 0, // No specific cloud ID needed for positions usually, or we return insertId which is less useful for bulk
                        type: 'ball_position'
                    });

                } catch (err) {
                    console.warn(`❌ Position sync failed for local_id ${pos.local_id}:`, err.message, {
                        fielding_scoring_local_id: pos.fielding_scoring_local_id,
                        player_id: pos.player_id,
                        fielding_position_id: pos.fielding_position_id,
                        position_number: pos.position_number
                    });
                    failed_ids.push(pos.local_id);
                    errors.push({
                        record_id: pos.local_id,
                        error: err.message,
                        error_type: 'POSITION_SYNC_ERROR'
                    });
                }
            }
        }

        await connection.commit();

        res.json({
            success: true,
            synced_count: synced_ids.length,
            failed_count: failed_ids.length,
            synced_ids,
            failed_ids,
            errors
        });
    } catch (error) {
        await connection.rollback();
        console.error('Batch sync error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    } finally {
        connection.release();
    }
});

/**
 * GET /api/fielding-scoring/:id
 * Get a single fielding scoring record
 */
router.get('/:id', async (req, res) => {
    try {
        const [rows] = await db.execute(
            `SELECT fs.*, 
        fp.position_name as primary_position_name,
        fat.action_name as action_name,
        p.scorecard_name as primary_fielder_name
      FROM fielding_scoring fs
      LEFT JOIN fielding_positions fp ON fs.primary_fielder_position_id = fp.id
      LEFT JOIN fielding_action_types fat ON fs.fielding_action_type_id = fat.id
      LEFT JOIN players p ON fs.primary_fielder_id = p.id
      WHERE fs.id = ?`,
            [req.params.id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Record not found' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Get record error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * PATCH /api/fielding-scoring/:id
 * Update a fielding scoring record
 */
router.patch('/:id', async (req, res) => {
    try {
        const updates = req.body;
        const allowedFields = [
            'primary_fielder_id', 'primary_fielder_position_id',
            'fielding_action_type_id', 'actual_runs_scored', 'runs_saved',
            'runs_cost', 'potential_runs', 'pickup_type_id', 'throw_type_id',
            'throw_technique_id', 'throw_accuracy_id', 'fielding_notes',
            'fielding_quality_score', 'is_verified',
            'striker_id', 'dismissed_batsman_id', 'ball_type_id'
        ];

        const filteredUpdates = {};
        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                filteredUpdates[field] = updates[field];
            }
        }

        if (Object.keys(filteredUpdates).length === 0) {
            return res.status(400).json({ error: 'No valid fields to update' });
        }

        const fields = Object.keys(filteredUpdates).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(filteredUpdates), req.params.id];

        await db.execute(
            `UPDATE fielding_scoring SET ${fields}, updated_at = NOW() WHERE id = ?`,
            values
        );

        res.json({
            success: true,
            updated_id: req.params.id,
            updated_fields: Object.keys(filteredUpdates)
        });
    } catch (error) {
        console.error('Update error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * DELETE /api/fielding-scoring/:id
 * Delete a fielding scoring record
 */
router.delete('/:id', async (req, res) => {
    try {
        const [result] = await db.execute(
            'DELETE FROM fielding_scoring WHERE id = ?',
            [req.params.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Record not found' });
        }

        res.json({
            success: true,
            deleted_id: req.params.id
        });
    } catch (error) {
        console.error('Delete error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/fielding-scoring/resolve-conflict
 * Resolve sync conflicts
 */
router.post('/resolve-conflict', async (req, res) => {
    try {
        const { ball_id, resolution, merged_data } = req.body;

        if (resolution === 'use_local') {
            // Update cloud with local data
            await db.execute(
                `UPDATE fielding_scoring SET ? WHERE id = ?`,
                [merged_data, ball_id]
            );
        } else if (resolution === 'use_cloud') {
            // Keep cloud data, just mark as resolved
            // Client will update local from cloud
        } else if (resolution === 'merge') {
            // Apply merged data
            await db.execute(
                `UPDATE fielding_scoring SET ? WHERE id = ?`,
                [merged_data, ball_id]
            );
        }

        res.json({
            success: true,
            resolved_record: ball_id,
            resolution_type: resolution
        });
    } catch (error) {
        console.error('Conflict resolution error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-scoring/match/:matchId
 * Get all fielding scoring records for a match
 */
router.get('/match/:matchId', async (req, res) => {
    try {
        const [records] = await db.execute(`
            SELECT 
                fs.*,
                p.scorecard_name as primary_fielder_name,
                fp.position_name as primary_position_name,
                fp.position_code as primary_position_code,
                fat.action_name as action_name,
                fat.action_code as action_code
            FROM fielding_scoring fs
            LEFT JOIN players p ON fs.primary_fielder_id = p.id
            LEFT JOIN fielding_positions fp ON fs.primary_fielder_position_id = fp.id
            LEFT JOIN fielding_action_types fat ON fs.fielding_action_type_id = fat.id
            WHERE fs.match_id = ?
            ORDER BY fs.inning_number, fs.over_number, fs.delivery_sequence
        `, [req.params.matchId]);

        res.json({
            success: true,
            count: records.length,
            records
        });
    } catch (error) {
        console.error('Get match fielding data error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * POST /api/fielding-scoring/ball-positions
 * Save all 11 fielder positions for a specific ball
 */
router.post('/ball-positions', async (req, res) => {
    const { fielding_scoring_id, positions } = req.body;

    if (!fielding_scoring_id || !positions || !Array.isArray(positions)) {
        return res.status(400).json({
            success: false,
            error: 'fielding_scoring_id and positions array required'
        });
    }

    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        const insertedIds = [];

        for (const pos of positions) {
            const [result] = await connection.execute(`
                INSERT INTO ball_fielding_positions (
                    fielding_scoring_id, player_id, fielding_position_id,
                    position_number, position_x, position_y,
                    is_keeper, is_primary_fielder, is_backup,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
            `, [
                fielding_scoring_id,
                pos.player_id ?? null,
                pos.fielding_position_id ?? null,
                pos.position_number ?? null,
                pos.position_x ?? null,
                pos.position_y ?? null,
                pos.is_keeper ? 1 : 0,
                pos.is_primary_fielder ? 1 : 0,
                pos.is_backup ? 1 : 0
            ]);

            insertedIds.push(result.insertId);
        }

        await connection.commit();

        res.json({
            success: true,
            message: `${insertedIds.length} positions saved`,
            inserted_ids: insertedIds
        });
    } catch (error) {
        await connection.rollback();
        console.error('Ball positions save error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    } finally {
        connection.release();
    }
});

/**
 * GET /api/fielding-scoring/ball/:fieldingScoringId/positions
 * Get all fielder positions for a specific ball
 */
router.get('/ball/:fieldingScoringId/positions', async (req, res) => {
    try {
        const [positions] = await db.execute(`
            SELECT 
                bfp.*,
                p.scorecard_name as player_name,
                fp.position_name,
                fp.position_code,
                pc.category_name as category
            FROM ball_fielding_positions bfp
            LEFT JOIN players p ON bfp.player_id = p.id
            LEFT JOIN fielding_positions fp ON bfp.fielding_position_id = fp.id
            LEFT JOIN position_categories pc ON fp.position_category_id = pc.id
            WHERE bfp.fielding_scoring_id = ?
            ORDER BY bfp.position_number
        `, [req.params.fieldingScoringId]);

        res.json({
            success: true,
            count: positions.length,
            positions
        });
    } catch (error) {
        console.error('Get ball positions error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * GET /api/fielding-scoring/match/:matchId/sessions
 * Get fielding scoring sessions for a match
 */
router.get('/match/:matchId/sessions', async (req, res) => {
    try {
        const [sessions] = await db.execute(
            `SELECT * FROM fielding_scoring_sessions WHERE match_id = ? ORDER BY inning_number`,
            [req.params.matchId]
        );

        res.json({
            success: true,
            count: sessions.length,
            sessions
        });
    } catch (error) {
        console.error('Get sessions error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * POST /api/fielding-scoring/sessions
 * Create/start a fielding scoring session (inning-level team selection)
 */
router.post('/sessions', async (req, res) => {
    try {
        const {
            match_id,
            inning_number,
            batting_team_id,
            bowling_team_id,
            striker_id,
            non_striker_id,
            status = 'STARTED',
            started_at,
            created_by,
            updated_by
        } = req.body;

        const now = new Date();
        const toMySqlDateTime = (date) => {
            if (!date) return null;
            const d = new Date(date);
            if (Number.isNaN(d.getTime())) return null;
            return d.toISOString().slice(0, 19).replace('T', ' ');
        };

        const [result] = await db.execute(
            `INSERT INTO fielding_scoring_sessions
            (match_id, inning_number, batting_team_id, bowling_team_id, striker_id, non_striker_id, status, started_at, created_at, updated_at, created_by, updated_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                match_id,
                inning_number,
                batting_team_id,
                bowling_team_id,
                striker_id || null,
                non_striker_id || null,
                status,
                toMySqlDateTime(started_at || now),
                toMySqlDateTime(now),
                toMySqlDateTime(now),
                created_by,
                updated_by
            ]
        );

        res.json({
            success: true,
            id: result.insertId
        });
    } catch (error) {
        console.error('Create session error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * PATCH /api/fielding-scoring/sessions/:id
 * Update session status (end inning / end match)
 */
router.patch('/sessions/:id', async (req, res) => {
    try {
        const { status, ended_at, updated_by, striker_id, non_striker_id } = req.body;
        const now = new Date();
        const toMySqlDateTime = (date) => {
            if (!date) return null;
            const d = new Date(date);
            if (Number.isNaN(d.getTime())) return null;
            return d.toISOString().slice(0, 19).replace('T', ' ');
        };

        const updates = [];
        const values = [];
        if (status !== undefined) { updates.push('status = ?'); values.push(status); }
        if (ended_at !== undefined) { updates.push('ended_at = ?'); values.push(toMySqlDateTime(ended_at || now)); }
        if (updated_by !== undefined) { updates.push('updated_by = ?'); values.push(updated_by); }
        if (striker_id !== undefined) { updates.push('striker_id = ?'); values.push(striker_id || null); }
        if (non_striker_id !== undefined) { updates.push('non_striker_id = ?'); values.push(non_striker_id || null); }
        updates.push('updated_at = ?');
        values.push(toMySqlDateTime(now));
        values.push(req.params.id);

        if (updates.length <= 1) {
            return res.status(400).json({ error: 'No valid fields to update' });
        }

        await db.execute(
            `UPDATE fielding_scoring_sessions SET ${updates.join(', ')} WHERE id = ?`,
            values
        );

        res.json({
            success: true
        });
    } catch (error) {
        console.error('Update session error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * POST /api/fielding-scoring/sessions/batch-sync
 * Sync fielding scoring sessions in batch
 */
router.post('/sessions/batch-sync', async (req, res) => {
    const { sessions } = req.body;
    const connection = await db.getConnection();

    try {
        await connection.beginTransaction();

        const toMySqlDateTime = (date) => {
            if (!date) return null;
            const d = new Date(date);
            if (Number.isNaN(d.getTime())) return null;
            return d.toISOString().slice(0, 19).replace('T', ' ');
        };

        const synced_ids = [];
        const failed_ids = [];
        const errors = [];

        for (const session of sessions || []) {
            try {
                await connection.execute(
                    `INSERT INTO fielding_scoring_sessions
                    (match_id, inning_number, batting_team_id, bowling_team_id, striker_id, non_striker_id, status, started_at, ended_at, created_at, updated_at, created_by, updated_by)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                        batting_team_id = VALUES(batting_team_id),
                        bowling_team_id = VALUES(bowling_team_id),
                        striker_id = VALUES(striker_id),
                        non_striker_id = VALUES(non_striker_id),
                        status = VALUES(status),
                        started_at = VALUES(started_at),
                        ended_at = VALUES(ended_at),
                        updated_at = VALUES(updated_at),
                        updated_by = VALUES(updated_by)`,
                    [
                        session.match_id,
                        session.inning_number,
                        session.batting_team_id,
                        session.bowling_team_id,
                        session.striker_id || null,
                        session.non_striker_id || null,
                        session.status || 'STARTED',
                        toMySqlDateTime(session.started_at || new Date()),
                        toMySqlDateTime(session.ended_at || null),
                        toMySqlDateTime(session.created_at || new Date()),
                        toMySqlDateTime(session.updated_at || new Date()),
                        session.created_by,
                        session.updated_by
                    ]
                );

                const [rows] = await connection.query(
                    `SELECT id FROM fielding_scoring_sessions WHERE match_id = ? AND inning_number = ? LIMIT 1`,
                    [session.match_id, session.inning_number]
                );

                const cloudId = rows.length > 0 ? rows[0].id : 0;
                const localId = session.local_id || String(session.id || `${session.match_id}-${session.inning_number}`);

                synced_ids.push({ local_id: String(localId), cloud_id: cloudId });
            } catch (err) {
                const localId = session.local_id || String(session.id || `${session.match_id}-${session.inning_number}`);
                failed_ids.push(String(localId));
                errors.push({ record_id: String(localId), error: err.message || 'Unknown error' });
            }
        }

        await connection.commit();

        res.json({
            success: failed_ids.length === 0,
            synced_count: synced_ids.length,
            failed_count: failed_ids.length,
            synced_ids,
            failed_ids,
            errors
        });
    } catch (error) {
        await connection.rollback();
        console.error('Batch session sync error:', error);
        res.status(500).json({
            success: false,
            synced_count: 0,
            failed_count: sessions?.length || 0,
            synced_ids: [],
            failed_ids: sessions?.map(s => String(s.local_id || s.id || '')) || [],
            errors: [{ record_id: '', error: error.message }]
        });
    } finally {
        connection.release();
    }
});

/**
 * GET /api/fielding-scoring/lookups
 * Get all lookup tables for fielding scoring (for offline caching)
 */
router.get('/lookups', async (req, res) => {
    try {
        // Fetch all lookup tables in parallel for performance
        const [
            fieldingActionCategories,
            fieldingActionTypes,
            pickupTypes,
            throwTypes,
            throwTechniques,
            catchDifficultyLevels,
            athleticQualityRatings,
            backupObservationTypes,
            errorTypes,
            keeperContextTypes,
            keeperStandingPositions,
            battingContextTypes,
            handednessTypes,
            ballTypes
        ] = await Promise.all([
            // 1. Fielding Action Categories
            db.execute(`
                SELECT id, category_name, category_description
                FROM fielding_action_categories
                WHERE is_active = 1
                ORDER BY id
            `),

            // 2. Fielding Action Types
            db.execute(`
                SELECT id, action_category_id, action_code, action_name, 
                       display_order, is_positive
                FROM fielding_action_types
                WHERE is_active = 1
                ORDER BY action_category_id, display_order
            `),

            // 3. Pickup Types
            db.execute(`
                SELECT id, pickup_code, pickup_name, display_order
                FROM pickup_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 4. Throw Types
            db.execute(`
                SELECT id, throw_code, throw_name, display_order
                FROM throw_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 5. Throw Techniques
            db.execute(`
                SELECT id, technique_code, technique_name, display_order
                FROM throw_techniques
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 6. Catch Difficulty Levels
            db.execute(`
                SELECT id, difficulty_code, difficulty_name, display_order
                FROM catch_difficulty_levels
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 7. Athletic Quality Ratings
            db.execute(`
                SELECT id, rating_code, rating_name, rating_value, display_order
                FROM athletic_quality_ratings
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 8. Backup Observation Types
            db.execute(`
                SELECT id, observation_code, observation_name, is_positive, display_order
                FROM backup_observation_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 9. Error Types
            db.execute(`
                SELECT id, error_code, error_name, display_order
                FROM error_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

            // 10. Keeper Context Types
            db.execute(`
                SELECT id, context_code, context_name
                FROM keeper_context_types
                WHERE is_active = 1
                ORDER BY id
            `),

            // 11. Keeper Standing Positions
            db.execute(`
                SELECT id, position_code, position_name
                FROM keeper_standing_positions
                WHERE is_active = 1
                ORDER BY id
            `),

            // 12. Batting Context Types
            db.execute(`
                SELECT id, context_code, context_name
                FROM batting_context_types
                WHERE is_active = 1
                ORDER BY id
            `),

            // 13. Handedness Types
            db.execute(`
                SELECT id, handedness_code, handedness_name
                FROM handedness_types
                WHERE is_active = 1
                ORDER BY id
            `),

            // 14. Ball Types (NORMAL, WIDE, NO_BALL)
            db.execute(`
                SELECT id, ball_type_code, ball_type_name, display_order
                FROM ball_types
                WHERE is_active = 1
                ORDER BY display_order
            `)
        ]);

        // Return all lookups in a single response
        res.json({
            success: true,
            lastUpdated: new Date().toISOString(),
            lookups: {
                fieldingActionCategories: fieldingActionCategories[0],
                fieldingActionTypes: fieldingActionTypes[0],
                pickupTypes: pickupTypes[0],
                throwTypes: throwTypes[0],
                throwTechniques: throwTechniques[0],
                catchDifficultyLevels: catchDifficultyLevels[0],
                athleticQualityRatings: athleticQualityRatings[0],
                backupObservationTypes: backupObservationTypes[0],
                errorTypes: errorTypes[0],
                keeperContextTypes: keeperContextTypes[0],
                keeperStandingPositions: keeperStandingPositions[0],
                battingContextTypes: battingContextTypes[0],
                handednessTypes: handednessTypes[0],
                ballTypes: ballTypes[0]
            }
        });
    } catch (error) {
        console.error('Get lookups error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;
