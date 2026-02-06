const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * GET /api/fielding-plans/templates
 * Get all fielding plan templates
 */
router.get('/templates', async (req, res) => {
    try {
        const { match_type, scenario, bowler_type } = req.query;

        let query = `
      SELECT fp.*, 
        mt.description as match_type_name,
        bc.context_name as batting_context_name,
        bt.type as bowler_type_name,
        ht.handedness_name as batsman_handedness_name
      FROM fielding_plans fp
      LEFT JOIN match_types mt ON fp.match_type_id = mt.id
      LEFT JOIN batting_context_types bc ON fp.batting_context_id = bc.id
      LEFT JOIN bowling_types bt ON fp.bowler_type_id = bt.id
      LEFT JOIN handedness_types ht ON fp.batsman_handedness_id = ht.id
      WHERE fp.is_template = 1 AND fp.is_active = 1
    `;

        const params = [];

        if (match_type) {
            query += ' AND fp.match_type_id = ?';
            params.push(match_type);
        }

        if (scenario) {
            query += ' AND fp.batting_context_id = ?';
            params.push(scenario);
        }

        if (bowler_type) {
            query += ' AND fp.bowler_type_id = ?';
            params.push(bowler_type);
        }

        query += ' ORDER BY fp.plan_name';

        const [templates] = await db.execute(query, params);

        // Get positions for each template
        for (let template of templates) {
            const [positions] = await db.execute(
                `SELECT fpp.*, fpos.position_name, fpos.position_code
         FROM fielding_plan_positions fpp
         JOIN fielding_positions fpos ON fpp.fielding_position_id = fpos.id
         WHERE fpp.fielding_plan_id = ?
         ORDER BY fpp.position_number`,
                [template.id]
            );
            template.positions = positions;
        }

        res.json({ templates });
    } catch (error) {
        console.error('Get templates error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-plans/:id
 * Get a specific fielding plan
 */
router.get('/:id', async (req, res) => {
    try {
        const [plan] = await db.execute(
            `SELECT fp.*, 
        mt.description as match_type_name,
        bc.context_name as batting_context_name
       FROM fielding_plans fp
       LEFT JOIN match_types mt ON fp.match_type_id = mt.id
       LEFT JOIN batting_context_types bc ON fp.batting_context_id = bc.id
       WHERE fp.id = ?`,
            [req.params.id]
        );

        if (plan.length === 0) {
            return res.status(404).json({ error: 'Fielding plan not found' });
        }

        const [positions] = await db.execute(
            `SELECT fpp.*, fpos.position_name, fpos.position_code
       FROM fielding_plan_positions fpp
       JOIN fielding_positions fpos ON fpp.fielding_position_id = fpos.id
       WHERE fpp.fielding_plan_id = ?
       ORDER BY fpp.position_number`,
            [req.params.id]
        );

        res.json({
            plan: plan[0],
            positions
        });
    } catch (error) {
        console.error('Get plan error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/fielding-plans
 * Create a new custom fielding plan
 */
router.post('/', async (req, res) => {
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        const {
            plan_name, plan_description, match_type_id,
            batting_context_id, batsman_handedness_id, bowler_type_id,
            team_id, is_template, positions, created_by, updated_by
        } = req.body;

        // Insert fielding plan
        const [result] = await connection.execute(
            `INSERT INTO fielding_plans (
        plan_name, plan_description, match_type_id,
        batting_context_id, batsman_handedness_id, bowler_type_id,
        team_id, is_template, is_active,
        created_at, updated_at, created_by, updated_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, NOW(), NOW(), ?, ?)`,
            [
                plan_name, plan_description, match_type_id,
                batting_context_id, batsman_handedness_id, bowler_type_id,
                team_id, is_template || 0, created_by, updated_by
            ]
        );

        const plan_id = result.insertId;

        // Insert positions
        if (positions && positions.length > 0) {
            for (const pos of positions) {
                await connection.execute(
                    `INSERT INTO fielding_plan_positions (
            fielding_plan_id, fielding_position_id, position_number,
            coordinate_x, coordinate_y, is_primary, notes,
            created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
                    [
                        plan_id, pos.fielding_position_id, pos.position_number,
                        pos.coordinate_x, pos.coordinate_y, pos.is_primary || 0, pos.notes
                    ]
                );
            }
        }

        await connection.commit();

        res.json({
            success: true,
            plan_id,
            message: 'Fielding plan created successfully'
        });
    } catch (error) {
        await connection.rollback();
        console.error('Create plan error:', error);
        res.status(500).json({ error: error.message });
    } finally {
        connection.release();
    }
});

/**
 * PATCH /api/fielding-plans/:id
 * Update a fielding plan
 */
router.patch('/:id', async (req, res) => {
    try {
        const updates = req.body;
        const allowedFields = [
            'plan_name', 'plan_description', 'is_active', 'is_template'
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
            `UPDATE fielding_plans SET ${fields}, updated_at = NOW() WHERE id = ?`,
            values
        );

        res.json({
            success: true,
            updated_id: req.params.id
        });
    } catch (error) {
        console.error('Update plan error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * DELETE /api/fielding-plans/:id
 * Delete a fielding plan
 */
router.delete('/:id', async (req, res) => {
    try {
        const [result] = await db.execute(
            'DELETE FROM fielding_plans WHERE id = ?',
            [req.params.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Fielding plan not found' });
        }

        res.json({
            success: true,
            deleted_id: req.params.id
        });
    } catch (error) {
        console.error('Delete plan error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/fielding-plans
 * Get all fielding plans (including custom ones)
 */
router.get('/', async (req, res) => {
    try {
        const { team_id, is_template } = req.query;

        let query = `
      SELECT fp.*, 
        mt.description as match_type_name,
        t.name_in_club as team_name
      FROM fielding_plans fp
      LEFT JOIN match_types mt ON fp.match_type_id = mt.id
      LEFT JOIN teams t ON fp.team_id = t.id
      WHERE fp.is_active = 1
    `;

        const params = [];

        if (team_id) {
            query += ' AND (fp.team_id = ? OR fp.team_id IS NULL)';
            params.push(team_id);
        }

        if (is_template !== undefined) {
            query += ' AND fp.is_template = ?';
            params.push(is_template);
        }

        query += ' ORDER BY fp.is_template DESC, fp.plan_name';

        const [plans] = await db.execute(query, params);

        res.json({ plans });
    } catch (error) {
        console.error('Get plans error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
