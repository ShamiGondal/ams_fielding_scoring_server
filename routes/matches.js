const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * GET /api/matches/:id/prepare
 * Pre-match data download for offline scoring
 * Downloads all necessary data to IndexedDB before match starts
 */
router.get('/:id/prepare', async (req, res) => {
    try {
        const matchId = req.params.id;

        // Get match details
        const [match] = await db.execute(
            `SELECT m.*, mt.description as match_type_name, v.name as venue_name
       FROM matches m
       LEFT JOIN match_types mt ON m.match_type_id = mt.id
       LEFT JOIN venues v ON m.venue_id = v.id
       WHERE m.id = ?`,
            [matchId]
        );

        if (match.length === 0) {
            return res.status(404).json({ error: 'Match not found' });
        }

        // Get teams
        const [teams] = await db.execute(
            `SELECT DISTINCT t.* 
       FROM teams t
       JOIN match_details md ON t.id = md.team_id
       WHERE md.match_id = ?`,
            [matchId]
        );

        // Get players with their team associations
        const [players] = await db.execute(
            `SELECT DISTINCT p.*, mp.team_id, mp.play_order
       FROM players p
       JOIN match_players mp ON p.id = mp.player_id
       WHERE mp.match_id = ?
       ORDER BY mp.team_id, mp.play_order`,
            [matchId]
        );

        // Get fielding scoring sessions for this match (if any)
        const [fielding_scoring_sessions] = await db.execute(
            `SELECT * FROM fielding_scoring_sessions WHERE match_id = ? ORDER BY inning_number`,
            [matchId]
        );

        // Get fielding plans (templates)
        const [fielding_plans] = await db.execute(
            `SELECT fp.*, mt.description as match_type_name
       FROM fielding_plans fp
       LEFT JOIN match_types mt ON fp.match_type_id = mt.id
       WHERE fp.is_active = 1 AND fp.is_template = 1`
        );

        // Get fielding plan positions for each template
        const [plan_positions] = await db.execute(
            `SELECT fpp.*, fplan.plan_name, fpos.position_name
       FROM fielding_plan_positions fpp
       JOIN fielding_plans fplan ON fpp.fielding_plan_id = fplan.id
       JOIN fielding_positions fpos ON fpp.fielding_position_id = fpos.id
       WHERE fplan.is_active = 1 AND fplan.is_template = 1
       ORDER BY fpp.fielding_plan_id, fpp.position_number`
        );

        // Get all lookup tables
        const [positions] = await db.execute(
            `SELECT fp.*, pc.category_name
       FROM fielding_positions fp
       JOIN position_categories pc ON fp.position_category_id = pc.id
       WHERE fp.is_active = 1
       ORDER BY fp.display_order`
        );

        const [action_types] = await db.execute(
            `SELECT fat.*, fac.category_name
       FROM fielding_action_types fat
       JOIN fielding_action_categories fac ON fat.action_category_id = fac.id
       WHERE fat.is_active = 1
       ORDER BY fat.display_order`
        );

        const [pickup_types] = await db.execute(
            'SELECT * FROM pickup_types WHERE is_active = 1 ORDER BY display_order'
        );

        const [throw_types] = await db.execute(
            'SELECT * FROM throw_types WHERE is_active = 1 ORDER BY display_order'
        );

        const [throw_techniques] = await db.execute(
            'SELECT * FROM throw_techniques WHERE is_active = 1 ORDER BY display_order'
        );

        const [catch_difficulties] = await db.execute(
            'SELECT * FROM catch_difficulty_levels WHERE is_active = 1 ORDER BY display_order'
        );

        const [athletic_ratings] = await db.execute(
            'SELECT * FROM athletic_quality_ratings WHERE is_active = 1 ORDER BY display_order'
        );

        const [backup_observations] = await db.execute(
            'SELECT * FROM backup_observation_types WHERE is_active = 1 ORDER BY display_order'
        );

        const [error_types] = await db.execute(
            'SELECT * FROM error_types WHERE is_active = 1 ORDER BY display_order'
        );

        const [keeper_contexts] = await db.execute(
            'SELECT * FROM keeper_context_types WHERE is_active = 1'
        );

        const [keeper_positions] = await db.execute(
            'SELECT * FROM keeper_standing_positions WHERE is_active = 1'
        );

        const [batting_contexts] = await db.execute(
            'SELECT * FROM batting_context_types WHERE is_active = 1'
        );

        const [handedness] = await db.execute(
            'SELECT * FROM handedness_types WHERE is_active = 1'
        );

        res.json({
            match: match[0],
            teams,
            players,
            fielding_plans,
            plan_positions,
            fielding_scoring_sessions,
            lookups: {
                positions,
                action_types,
                pickup_types,
                throw_types,
                throw_techniques,
                catch_difficulties,
                athletic_ratings,
                backup_observations,
                error_types,
                keeper_contexts,
                keeper_positions,
                batting_contexts,
                handedness
            },
            downloaded_at: new Date()
        });
    } catch (error) {
        console.error('Prepare match error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/matches/:id/fielding-data
 * Get all fielding data for a match
 */
router.get('/:id/fielding-data', async (req, res) => {
    try {
        const { from_ball, to_ball } = req.query;

        let query = `
      SELECT fs.*, 
        p.scorecard_name as primary_fielder_name,
        fp.position_name as primary_position_name,
        fat.action_name as action_name
      FROM fielding_scoring fs
      LEFT JOIN players p ON fs.primary_fielder_id = p.id
      LEFT JOIN fielding_positions fp ON fs.primary_fielder_position_id = fp.id
      LEFT JOIN fielding_action_types fat ON fs.fielding_action_type_id = fat.id
      WHERE fs.match_id = ?
    `;

        const params = [req.params.id];

        if (from_ball) {
            query += ' AND CONCAT(fs.over_number, ".", fs.ball_number) >= ?';
            params.push(from_ball);
        }

        if (to_ball) {
            query += ' AND CONCAT(fs.over_number, ".", fs.ball_number) <= ?';
            params.push(to_ball);
        }

        query += ' ORDER BY fs.inning_number, fs.over_number, fs.ball_number';

        const [fielding_records] = await db.execute(query, params);

        // Get ball positions for these records
        const [positions_history] = await db.execute(
            `SELECT bfp.*, p.scorecard_name as player_name, fp.position_name
       FROM ball_fielding_positions bfp
       JOIN fielding_scoring fs ON bfp.fielding_scoring_id = fs.id
       LEFT JOIN players p ON bfp.player_id = p.id
       LEFT JOIN fielding_positions fp ON bfp.fielding_position_id = fp.id
       WHERE fs.match_id = ?
       ORDER BY bfp.fielding_scoring_id, bfp.position_number`,
            [req.params.id]
        );

        res.json({
            fielding_records,
            positions_history,
            total_balls: fielding_records.length
        });
    } catch (error) {
        console.error('Get fielding data error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/matches/:id/sync-status
 * Check synchronization status for a match
 */
router.get('/:id/sync-status', async (req, res) => {
    try {
        const [total] = await db.execute(
            'SELECT COUNT(*) as count FROM match_scorings WHERE match_id = ?',
            [req.params.id]
        );

        const [synced] = await db.execute(
            'SELECT COUNT(*) as count FROM fielding_scoring WHERE match_id = ?',
            [req.params.id]
        );

        const [verified] = await db.execute(
            'SELECT COUNT(*) as count FROM fielding_scoring WHERE match_id = ? AND is_verified = 1',
            [req.params.id]
        );

        res.json({
            total_balls: total[0].count,
            synced_balls: synced[0].count,
            pending_balls: total[0].count - synced[0].count,
            verified_balls: verified[0].count,
            sync_percentage: total[0].count > 0 ?
                ((synced[0].count / total[0].count) * 100).toFixed(2) : 0
        });
    } catch (error) {
        console.error('Sync status error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/matches/:id/fielding-stats
 * Get fielding statistics for a match
 */
router.get('/:id/fielding-stats', async (req, res) => {
    try {
        // Overall stats
        const [overall] = await db.execute(
            `SELECT 
        COUNT(*) as total_actions,
        SUM(runs_saved) as total_runs_saved,
        SUM(runs_cost) as total_runs_cost,
        SUM(runs_saved - runs_cost) as net_impact,
        AVG(fielding_quality_score) as avg_quality_score,
        SUM(resulted_in_wicket) as wickets_involved
      FROM fielding_scoring
      WHERE match_id = ?`,
            [req.params.id]
        );

        // Player-wise stats
        const [player_stats] = await db.execute(
            `SELECT 
        p.id, p.scorecard_name,
        COUNT(*) as actions,
        SUM(fs.runs_saved) as runs_saved,
        SUM(fs.runs_cost) as runs_cost,
        SUM(fs.runs_saved - fs.runs_cost) as net_impact,
        AVG(fs.fielding_quality_score) as avg_quality
      FROM fielding_scoring fs
      JOIN players p ON fs.primary_fielder_id = p.id
      WHERE fs.match_id = ?
      GROUP BY p.id, p.scorecard_name
      ORDER BY net_impact DESC`,
            [req.params.id]
        );

        res.json({
            overall: overall[0],
            player_stats
        });
    } catch (error) {
        console.error('Fielding stats error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/matches
 * Get list of matches with advanced filtering and pagination
 */
router.get('/', async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            match_type_id,
            team_id,
            competition_id,
            start_date,
            end_date,
            search
        } = req.query;

        // Build WHERE conditions and parameters
        const filters = [];
        const filterParams = [];

        // Status filter - check match_status in subquery
        if (status === 'in-progress') {
            filters.push(`EXISTS (SELECT 1 FROM match_play_details mpd WHERE mpd.match_id = m.id AND mpd.match_status = ?)`);
            filterParams.push('InProgress');
        } else if (status === 'closed') {
            filters.push(`EXISTS (SELECT 1 FROM match_play_details mpd WHERE mpd.match_id = m.id AND mpd.match_status = ?)`);
            filterParams.push('Closed');
        }

        if (match_type_id) {
            filters.push('m.match_type_id = ?');
            filterParams.push(parseInt(match_type_id));
        }

        if (team_id) {
            filters.push(`EXISTS (SELECT 1 FROM match_details md WHERE md.match_id = m.id AND md.team_id = ?)`);
            filterParams.push(parseInt(team_id));
        }

        if (competition_id) {
            filters.push('m.competition_id = ?');
            filterParams.push(parseInt(competition_id));
        }

        if (start_date) {
            filters.push('m.start_date >= ?');
            filterParams.push(start_date);
        }

        if (end_date) {
            filters.push('m.start_date <= ?');
            filterParams.push(end_date);
        }

        if (search) {
            const searchTerm = `%${search}%`;
            filters.push('m.name LIKE ?');
            filterParams.push(searchTerm);
        }

        const whereClause = filters.length > 0 ? 'WHERE ' + filters.join(' AND ') : '';

        // 1. Get total count
        const countQuery = `SELECT COUNT(*) as total FROM matches m ${whereClause}`;
        const [countResult] = await db.query(countQuery, filterParams);
        const total = countResult[0].total;

        // 2. Get matches with all data using subqueries
        const matchesQuery = `
            SELECT 
                m.id,
                m.name as match_name,
                m.competition_id,
                m.match_type_id,
                m.venue_id,
                m.start_date,
                m.created_at,
                m.updated_at,
                (SELECT mt.description FROM match_types mt WHERE mt.id = m.match_type_id) as match_type_name,
                (SELECT v.name FROM venues v WHERE v.id = m.venue_id) as venue_name,
                (SELECT c.competition_name FROM competitions c WHERE c.id = m.competition_id) as competition_name,
                (SELECT mpd.match_status FROM match_play_details mpd WHERE mpd.match_id = m.id ORDER BY mpd.id DESC LIMIT 1) as match_status,
                (SELECT GROUP_CONCAT(DISTINCT t.team_name ORDER BY t.team_name SEPARATOR ' vs ')
                 FROM match_details md
                 INNER JOIN teams t ON md.team_id = t.id
                 WHERE md.match_id = m.id) as teams,
                (SELECT COUNT(*) FROM match_scorings ms WHERE ms.match_id = m.id) as total_balls,
                (SELECT COUNT(*) FROM fielding_scoring fs WHERE fs.match_id = m.id) as synced_balls
            FROM matches m
            ${whereClause}
            ORDER BY m.start_date DESC, m.id DESC
            LIMIT ? OFFSET ?
        `;

        // Calculate pagination - ensure integers
        const pageNum = Math.max(1, parseInt(page) || 1);
        const limitNum = Math.max(1, Math.min(100, parseInt(limit) || 20));
        const offsetNum = (pageNum - 1) * limitNum;

        // Build final params array - push limit and offset like the working example
        const queryParams = [...filterParams];
        queryParams.push(limitNum, offsetNum);

        // Execute with query() instead of execute()
        const [matchesRaw] = await db.query(matchesQuery, queryParams);

        // Process matches to add sync_status object
        const matches = matchesRaw.map(match => {
            const totalBalls = match.total_balls || 0;
            const syncedBalls = match.synced_balls || 0;
            const pendingBalls = totalBalls - syncedBalls;
            const syncPercentage = totalBalls > 0 ? ((syncedBalls / totalBalls) * 100).toFixed(2) : '0.00';

            return {
                ...match,
                sync_status: {
                    total_balls: totalBalls,
                    synced_balls: syncedBalls,
                    pending_balls: pendingBalls,
                    sync_percentage: syncPercentage
                },
                // Remove the raw count fields
                total_balls: undefined,
                synced_balls: undefined
            };
        });

        // Return response
        res.json({
            matches,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                totalPages: Math.ceil(total / limitNum)
            }
        });

    } catch (error) {
        console.error('Get matches error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/matches/filter-options
 * Get available filter options (cascading)
 */
router.get('/filter-options', async (req, res) => {
    try {
        const { match_type_id, team_id } = req.query;

        // Get match types
        const [match_types] = await db.execute(
            'SELECT id, description as name FROM match_types ORDER BY description'
        );

        // Get teams (filtered by match type if provided)
        let teams_query = `
            SELECT DISTINCT t.id, t.team_name as name
            FROM teams t
            JOIN match_details md ON t.id = md.team_id
            JOIN matches m ON md.match_id = m.id
        `;
        let teams_params = [];

        if (match_type_id) {
            teams_query += ' WHERE m.match_type_id = ?';
            teams_params.push(parseInt(match_type_id));
        }

        teams_query += ' ORDER BY t.team_name';
        const [teams] = await db.execute(teams_query, teams_params);

        // Get competitions (filtered by team if provided)
        let competitions_query = `
            SELECT DISTINCT c.id, c.competition_name as name
            FROM competitions c
            JOIN matches m ON c.id = m.competition_id
        `;
        let competitions_params = [];

        if (team_id) {
            competitions_query += `
                JOIN match_details md ON m.id = md.match_id
                WHERE md.team_id = ?
            `;
            competitions_params.push(parseInt(team_id));
        } else if (match_type_id) {
            competitions_query += ' WHERE m.match_type_id = ?';
            competitions_params.push(parseInt(match_type_id));
        }

        competitions_query += ' ORDER BY c.competition_name';
        const [competitions] = await db.execute(competitions_query, competitions_params);

        res.json({
            match_types,
            teams,
            competitions
        });
    } catch (error) {
        console.error('Get filter options error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
