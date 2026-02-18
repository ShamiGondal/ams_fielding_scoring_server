const express = require('express');
const router = express.Router();
const db = require('../config/database');

// ============================================================================
// VALIDATION HELPER FUNCTIONS - Using actual database codes
// ============================================================================

function isWicketkeeper(positionCode) {
    return positionCode === 'BWK';  // Database code for Wicket Keeper
}

function isBowler(positionCode) {
    return positionCode === 'B';  // Database code for Bowler
}

function isBehindSquare(positionCode) {
    // Behind square leg positions (6:00-9:00 clock angle)
    // F = Fine Leg, SA = Square Leg
    return ['F', 'SA'].includes(positionCode);
}

function isLegSide(positionCode) {
    if (positionCode === 'BWK') return false;  // Keeper doesn't count
    // Leg side positions: MW, MC, SA, F
    return ['MW', 'MC', 'SA', 'F'].includes(positionCode);
}

function isOutsideCircle(positionCode) {
    // Boundary/Deep positions: DC, DP, L (Long), F (Fine Leg)
    return ['DC', 'DP', 'L', 'F'].includes(positionCode);
}

/**
 * Validate cricket fielding rules for a set of positions
 * Returns { valid: boolean, errors: string[] }
 */
async function validateFieldingRules(positions, matchTypeId, battingContextId, connection) {
    const errors = [];

    // Fetch position codes for validation
    const positionIds = positions.map(p => p.fielding_position_id);
    if (positionIds.length === 0) {
        return { valid: true, errors: [] };
    }

    const [positionData] = await connection.query(
        'SELECT id, position_code FROM fielding_positions WHERE id IN (?)',
        [positionIds]
    );

    // Create lookup map
    const positionMap = {};
    positionData.forEach(p => {
        positionMap[p.id] = p.position_code;
    });

    // Add position codes to positions array
    const positionsWithCodes = positions.map(p => ({
        ...p,
        position_code: positionMap[p.fielding_position_id]
    }));

    // Rule 1: Only 1 wicketkeeper
    const keeperCount = positionsWithCodes.filter(p => isWicketkeeper(p.position_code)).length;
    if (keeperCount === 0) {
        errors.push('At least 1 wicketkeeper is required');
    } else if (keeperCount > 1) {
        errors.push('Only 1 wicketkeeper is allowed');
    }

    // Rule 1.5: Only 1 bowler
    const bowlerCount = positionsWithCodes.filter(p => isBowler(p.position_code)).length;
    if (bowlerCount > 1) {
        errors.push('Only 1 bowler is allowed in the fielding setup');
    }

    // Rule 2: Max 2 fielders behind square leg (Bodyline Law)
    const behindSquareCount = positionsWithCodes.filter(p => isBehindSquare(p.position_code)).length;
    if (behindSquareCount > 2) {
        errors.push('Maximum 2 fielders allowed behind square leg (Bodyline Law)');
    }

    // Rule 3: Max 5 fielders on leg side (ODI/T20 only, not Test)
    if (matchTypeId !== 3) { // 3 = Test cricket
        const legSideCount = positionsWithCodes.filter(p => isLegSide(p.position_code)).length;
        if (legSideCount > 5) {
            errors.push('Maximum 5 fielders allowed on leg side (excluding keeper)');
        }
    }

    // Rule 4: Circle restrictions (T20/ODI powerplay)
    const outsideCircleCount = positionsWithCodes.filter(p => isOutsideCircle(p.position_code)).length;
    let maxOutside = 5; // Default

    if (matchTypeId == 1) { // T20
        if (battingContextId == 1) {
            maxOutside = 2; // Powerplay (1-6 overs)
        } else {
            maxOutside = 5; // Middle/Death (7-20 overs)
        }
    } else if (matchTypeId == 2) { // ODI
        if (battingContextId == 1) {
            maxOutside = 2; // Powerplay 1 (1-10)
        } else if (battingContextId == 2) {
            maxOutside = 4; // Powerplay 2 (11-40)
        } else {
            maxOutside = 5; // Powerplay 3 (41-50)
        }
    }

    if (matchTypeId !== 3 && outsideCircleCount > maxOutside) {
        errors.push(`Maximum ${maxOutside} fielders allowed outside circle for this match type/phase`);
    }

    return {
        valid: errors.length === 0,
        errors: errors
    };
}

/**
 * GET /api/fielding-templates
 * List all fielding templates with filters
 */
router.get('/', async (req, res) => {
    try {
        const { match_type_id, team_id, is_template, batting_context_id, page = 1, limit = 20 } = req.query;

        let query = `
            SELECT 
                fp.id,
                fp.plan_name,
                fp.plan_description,
                fp.match_type_id,
                ANY_VALUE(mt.description) as match_type_name,
                fp.batting_context_id,
                ANY_VALUE(bc.context_name) as batting_context,
                fp.bowler_type_id,
                ANY_VALUE(bt.type) as bowler_type,
                fp.batsman_handedness_id,
                ANY_VALUE(ht.handedness_name) as batsman_handedness,
                fp.team_id,
                ANY_VALUE(t.name_in_club) as team_name,
                fp.is_template,
                fp.is_active,
                fp.created_at,
                ANY_VALUE(CONCAT(u.first_name, ' ', u.last_name)) as created_by_name,
                COUNT(DISTINCT fpp.id) as total_positions
            FROM fielding_plans fp
            LEFT JOIN match_types mt ON fp.match_type_id = mt.id
            LEFT JOIN batting_context_types bc ON fp.batting_context_id = bc.id
            LEFT JOIN bowling_types bt ON fp.bowler_type_id = bt.id
            LEFT JOIN handedness_types ht ON fp.batsman_handedness_id = ht.id
            LEFT JOIN teams t ON fp.team_id = t.id
            LEFT JOIN users u ON fp.created_by = u.id
            LEFT JOIN fielding_plan_positions fpp ON fp.id = fpp.fielding_plan_id
            WHERE fp.is_active = 1
        `;

        const params = [];

        if (match_type_id) {
            query += ' AND fp.match_type_id = ?';
            params.push(match_type_id);
        }

        if (team_id) {
            query += ' AND (fp.team_id = ? OR fp.team_id IS NULL)';
            params.push(team_id);
        }

        if (is_template !== undefined) {
            query += ' AND fp.is_template = ?';
            // Convert string 'true'/'false' to integer 1/0 for TINYINT column
            const isTemplateInt = is_template === 'true' || is_template === true || is_template === 1 ? 1 : 0;
            params.push(isTemplateInt);
        }

        if (batting_context_id) {
            query += ' AND fp.batting_context_id = ?';
            params.push(batting_context_id);
        }

        query += ' GROUP BY fp.id ORDER BY fp.created_at DESC';

        // Add pagination
        const offset = (page - 1) * limit;
        query += ' LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        console.log('🔍 GET Templates Query:', query);
        console.log('📊 Query Params:', params);

        const [templates] = await db.query(query, params);

        console.log(`✅ Found ${templates.length} templates`);

        // Get total count for pagination
        let countQuery = `
            SELECT COUNT(DISTINCT fp.id) as total
            FROM fielding_plans fp
            WHERE fp.is_active = 1
        `;
        const countParams = [];

        if (match_type_id) {
            countQuery += ' AND fp.match_type_id = ?';
            countParams.push(match_type_id);
        }
        if (team_id) {
            countQuery += ' AND (fp.team_id = ? OR fp.team_id IS NULL)';
            countParams.push(team_id);
        }
        if (is_template !== undefined) {
            countQuery += ' AND fp.is_template = ?';
            const isTemplateInt = is_template === 'true' || is_template === true || is_template === 1 ? 1 : 0;
            countParams.push(isTemplateInt);
        }
        if (batting_context_id) {
            countQuery += ' AND fp.batting_context_id = ?';
            countParams.push(batting_context_id);
        }

        const [countResult] = await db.query(countQuery, countParams);
        const total = countResult[0].total;

        res.json({
            templates,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total
            }
        });
    } catch (error) {
        console.error('Get templates error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-templates/:id
 * Get complete template details including all position assignments
 */
router.get('/:id', async (req, res) => {
    try {
        const [plan] = await db.query(
            `SELECT 
                fp.id,
                fp.plan_name,
                fp.plan_description,
                fp.match_type_id,
                mt.description as match_type_name,
                fp.batting_context_id,
                bc.context_name as batting_context,
                fp.batsman_handedness_id,
                ht.handedness_name as batsman_handedness,
                fp.bowler_type_id,
                bt.type as bowler_type,
                fp.team_id,
                t.name_in_club as team_name,
                fp.is_template,
                fp.is_active,
                fp.created_at,
                fp.updated_at,
                CONCAT(u.first_name, ' ', u.last_name) as created_by
            FROM fielding_plans fp
            LEFT JOIN match_types mt ON fp.match_type_id = mt.id
            LEFT JOIN batting_context_types bc ON fp.batting_context_id = bc.id
            LEFT JOIN handedness_types ht ON fp.batsman_handedness_id = ht.id
            LEFT JOIN bowling_types bt ON fp.bowler_type_id = bt.id
            LEFT JOIN teams t ON fp.team_id = t.id
            LEFT JOIN users u ON fp.created_by = u.id
            WHERE fp.id = ?`,
            [req.params.id]
        );

        if (plan.length === 0) {
            return res.status(404).json({ error: 'Fielding template not found' });
        }

        // Get position assignments
        const [positions] = await db.query(
            `SELECT 
                fpp.id,
                fpp.position_number,
                fpp.fielding_position_id,
                fpos.position_code,
                fpos.position_name,
                pc.category_name as category,
                fpp.coordinate_x,
                fpp.coordinate_y,
                fpp.is_primary,
                fpp.notes
            FROM fielding_plan_positions fpp
            JOIN fielding_positions fpos ON fpp.fielding_position_id = fpos.id
            JOIN position_categories pc ON fpos.position_category_id = pc.id
            WHERE fpp.fielding_plan_id = ?
            ORDER BY fpp.position_number`,
            [req.params.id]
        );

        res.json({
            ...plan[0],
            positions
        });
    } catch (error) {
        console.error('Get template details error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/fielding-templates
 * Create new fielding template
 */
router.post('/', async (req, res) => {
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        const {
            plan_name,
            plan_description,
            match_type_id,
            batting_context_id,
            batsman_handedness_id,
            bowler_type_id,
            team_id,
            is_template,
            positions,
            created_by,
            updated_by
        } = req.body;

        // Validation
        if (!plan_name || !match_type_id || !created_by || !updated_by) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({
                error: 'Missing required fields: plan_name, match_type_id, created_by, updated_by'
            });
        }

        if (positions && positions.length > 11) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({
                error: 'Cannot have more than 11 fielding positions'
            });
        }

        // Insert fielding plan
        const [result] = await connection.execute(
            `INSERT INTO fielding_plans (
                plan_name, plan_description, match_type_id,
                batting_context_id, batsman_handedness_id, bowler_type_id,
                team_id, is_template, is_active,
                created_at, updated_at, created_by, updated_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, NOW(), NOW(), ?, ?)`,
            [
                plan_name,
                plan_description,
                match_type_id,
                batting_context_id || null,
                batsman_handedness_id || null,
                bowler_type_id || null,
                team_id || null,
                is_template ? 1 : 0,
                created_by,
                updated_by
            ]
        );

        const plan_id = result.insertId;

        // Validate cricket fielding rules
        if (positions && positions.length > 0) {
            const validation = await validateFieldingRules(
                positions,
                match_type_id,
                batting_context_id,
                connection
            );

            if (!validation.valid) {
                await connection.rollback();
                connection.release();
                return res.status(400).json({
                    error: 'Cricket fielding rule violations',
                    violations: validation.errors
                });
            }
        }

        // Insert template positions (NOT player assignments)
        if (positions && positions.length > 0) {
            for (const pos of positions) {
                await connection.execute(
                    `INSERT INTO fielding_plan_positions (
                        fielding_plan_id, fielding_position_id,
                        position_number, coordinate_x, coordinate_y,
                        is_primary, notes, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
                    [
                        plan_id,
                        pos.fielding_position_id,
                        pos.position_number,
                        pos.coordinate_x || null,
                        pos.coordinate_y || null,
                        pos.is_primary || 0,
                        pos.notes || null
                    ]
                );
            }
        }

        await connection.commit();
        connection.release();

        res.status(201).json({
            success: true,
            id: plan_id,
            message: 'Fielding template created successfully'
        });
    } catch (error) {
        await connection.rollback();
        connection.release();
        console.error('Create template error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * PUT /api/fielding-templates/:id
 * Update existing fielding template
 */
router.put('/:id', async (req, res) => {
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        const {
            plan_name,
            plan_description,
            match_type_id,
            batting_context_id,
            batsman_handedness_id,
            bowler_type_id,
            team_id,
            is_template,
            positions,
            updated_by
        } = req.body;

        // Check if template exists
        const [existing] = await connection.query(
            'SELECT id FROM fielding_plans WHERE id = ?',
            [req.params.id]
        );

        if (existing.length === 0) {
            await connection.rollback();
            connection.release();
            return res.status(404).json({ error: 'Fielding template not found' });
        }

        // Validate positions
        if (positions && positions.length > 11) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({
                error: 'Cannot have more than 11 fielding positions'
            });
        }

        // Validate cricket fielding rules
        if (positions && positions.length > 0) {
            const validation = await validateFieldingRules(
                positions,
                match_type_id,
                batting_context_id,
                connection
            );

            if (!validation.valid) {
                await connection.rollback();
                connection.release();
                return res.status(400).json({
                    error: validation.errors.join(', ')
                });
            }
        }

        // Update fielding plan
        await connection.query(
            `UPDATE fielding_plans SET
                plan_name = ?,
                plan_description = ?,
                match_type_id = ?,
                batting_context_id = ?,
                batsman_handedness_id = ?,
                bowler_type_id = ?,
                team_id = ?,
                is_template = ?,
                updated_at = NOW(),
                updated_by = ?
            WHERE id = ?`,
            [
                plan_name,
                plan_description,
                match_type_id,
                batting_context_id || null,
                batsman_handedness_id || null,
                bowler_type_id || null,
                team_id || null,
                is_template ? 1 : 0,
                updated_by,
                req.params.id
            ]
        );

        // Delete existing positions
        await connection.query(
            'DELETE FROM fielding_plan_positions WHERE fielding_plan_id = ?',
            [req.params.id]
        );

        // Insert new positions
        if (positions && positions.length > 0) {
            for (const pos of positions) {
                await connection.query(
                    `INSERT INTO fielding_plan_positions (
                        fielding_plan_id, fielding_position_id,
                        position_number, coordinate_x, coordinate_y,
                        is_primary, notes, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
                    [
                        req.params.id,
                        pos.fielding_position_id,
                        pos.position_number,
                        pos.coordinate_x || null,
                        pos.coordinate_y || null,
                        pos.is_primary || 0,
                        pos.notes || null
                    ]
                );
            }
        }

        await connection.commit();
        connection.release();

        res.json({
            success: true,
            id: req.params.id,
            message: 'Fielding template updated successfully'
        });
    } catch (error) {
        await connection.rollback();
        connection.release();
        console.error('Update template error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * DELETE /api/fielding-templates/:id
 * Delete fielding template
 */
router.delete('/:id', async (req, res) => {
    try {
        const [result] = await db.execute(
            'DELETE FROM fielding_plans WHERE id = ?',
            [req.params.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Fielding template not found' });
        }

        res.json({
            success: true,
            deleted_id: req.params.id,
            message: 'Fielding template deleted successfully'
        });
    } catch (error) {
        console.error('Delete template error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-templates/positions/all
 * Get all available fielding positions grouped by category
 */
router.get('/positions/all', async (req, res) => {
    try {
        const [positions] = await db.execute(
            `SELECT 
                pc.id as category_id,
                pc.category_name,
                pc.category_description,
                fp.id,
                fp.position_code,
                fp.position_name,
                fp.display_order
            FROM position_categories pc
            LEFT JOIN fielding_positions fp ON pc.id = fp.position_category_id
            WHERE pc.is_active = 1 AND fp.is_active = 1
            ORDER BY pc.id, fp.display_order`
        );

        // Group by category
        const categories = [];
        const categoryMap = new Map();

        for (const pos of positions) {
            if (!categoryMap.has(pos.category_id)) {
                const category = {
                    category_id: pos.category_id,
                    category_name: pos.category_name,
                    category_description: pos.category_description,
                    positions: []
                };
                categories.push(category);
                categoryMap.set(pos.category_id, category);
            }

            categoryMap.get(pos.category_id).positions.push({
                id: pos.id,
                position_code: pos.position_code,
                position_name: pos.position_name,
                display_order: pos.display_order
            });
        }

        res.json({ categories });
    } catch (error) {
        console.error('Get positions error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-templates/lookups/match-types
 * Get all match types
 */
router.get('/lookups/match-types', async (req, res) => {
    try {
        const [matchTypes] = await db.execute(
            'SELECT id, description as name FROM match_types ORDER BY description'
        );
        res.json({ matchTypes });
    } catch (error) {
        console.error('Get match types error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-templates/lookups/batting-contexts
 * Get all batting context types
 */
router.get('/lookups/batting-contexts', async (req, res) => {
    try {
        const [battingContexts] = await db.execute(
            'SELECT id, context_name as name FROM batting_context_types WHERE is_active = 1 ORDER BY id'
        );
        res.json({ battingContexts });
    } catch (error) {
        console.error('Get batting contexts error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-templates/lookups/bowling-types
 * Get all bowling types
 */
router.get('/lookups/bowling-types', async (req, res) => {
    try {
        const [bowlingTypes] = await db.execute(
            'SELECT id, type as name, code FROM bowling_types ORDER BY id'
        );
        res.json({ bowlingTypes });
    } catch (error) {
        console.error('Get bowling types error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
