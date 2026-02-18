const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * GET /api/lookups/all
 * Get all lookup tables for offline caching
 * Response includes all 13 fielding scoring lookup tables
 */
router.get('/all', async (req, res) => {
  try {
    // Execute all queries in parallel for performance
    const [
      actionCategories,
      actions,
      positions,
      pickups,
      throws,
      techniques,
      catchDifficulty,
      ratings,
      backupObs,
      errors,
      keeperContexts,
      keeperPositions,
      battingContexts,
      handedness,
      ballTypes
    ] = await Promise.all([
      // 1. Fielding Action Categories
      db.execute(`
                SELECT id, category_name, category_description
                FROM fielding_action_categories
                WHERE is_active = 1
                ORDER BY id
            `),

      // 2. Fielding action types with categories
      db.execute(`
                SELECT 
                    fat.id, fat.action_category_id, fat.action_code, fat.action_name,
                    fat.display_order, fat.is_positive, fat.is_active,
                    fac.category_name
                FROM fielding_action_types fat
                LEFT JOIN fielding_action_categories fac ON fat.action_category_id = fac.id
                WHERE fat.is_active = 1
                ORDER BY fat.action_category_id, fat.display_order
            `),

      // 3. Fielding positions with categories
      db.execute(`
                SELECT 
                    fp.id, fp.position_code, fp.position_name, fp.position_category_id,
                    fp.display_order, fp.is_active,
                    pc.category_name
                FROM fielding_positions fp
                LEFT JOIN position_categories pc ON fp.position_category_id = pc.id
                WHERE fp.is_active = 1
                ORDER BY fp.display_order
            `),

      // 4. Pickup types
      db.execute(`
                SELECT id, pickup_code, pickup_name, display_order
                FROM pickup_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 5. Throw types
      db.execute(`
                SELECT id, throw_code, throw_name, display_order
                FROM throw_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 6. Throw techniques
      db.execute(`
                SELECT id, technique_code, technique_name, display_order
                FROM throw_techniques
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 7. Catch difficulty levels
      db.execute(`
                SELECT id, difficulty_code, difficulty_name, display_order
                FROM catch_difficulty_levels
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 8. Athletic quality ratings
      db.execute(`
                SELECT id, rating_code, rating_name, rating_value, display_order
                FROM athletic_quality_ratings
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 9. Backup observation types
      db.execute(`
                SELECT id, observation_code, observation_name, is_positive, display_order
                FROM backup_observation_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 10. Error types
      db.execute(`
                SELECT id, error_code, error_name, display_order
                FROM error_types
                WHERE is_active = 1
                ORDER BY display_order
            `),

      // 11. Keeper context types
      db.execute(`
                SELECT id, context_code, context_name
                FROM keeper_context_types
                WHERE is_active = 1
                ORDER BY id
            `),

      // 12. Keeper standing positions
      db.execute(`
                SELECT id, position_code, position_name
                FROM keeper_standing_positions
                WHERE is_active = 1
                ORDER BY id
            `),

      // 13. Batting context types
      db.execute(`
                SELECT id, context_code, context_name
                FROM batting_context_types
                WHERE is_active = 1
                ORDER BY id
            `),

      // 14. Handedness types
      db.execute(`
                SELECT id, handedness_code, handedness_name
                FROM handedness_types
                WHERE is_active = 1
                ORDER BY id
            `),

      // 15. Ball types (NORMAL, WIDE, NO_BALL)
      db.execute(`
                SELECT id, ball_type_code, ball_type_name, display_order
                FROM ball_types
                WHERE is_active = 1
                ORDER BY display_order
            `)
    ]);

    res.json({
      success: true,
      lastUpdated: new Date().toISOString(),
      lookups: {
        // New complete structure
        fieldingActionCategories: actionCategories[0],
        fieldingActionTypes: actions[0],
        pickupTypes: pickups[0],
        throwTypes: throws[0],
        throwTechniques: techniques[0],
        catchDifficultyLevels: catchDifficulty[0],
        athleticQualityRatings: ratings[0],
        backupObservationTypes: backupObs[0],
        errorTypes: errors[0],
        keeperContextTypes: keeperContexts[0],
        keeperStandingPositions: keeperPositions[0],
        battingContextTypes: battingContexts[0],
        handednessTypes: handedness[0],
        ballTypes: ballTypes[0],

        // Legacy structure for backward compatibility
        positions: positions[0],
        actions: actions[0],
        pickups: pickups[0],
        throws: throws[0],
        techniques: techniques[0],
        ratings: ratings[0],
        backupObservations: backupObs[0],
        errors: errors[0],
        catchDifficulty: catchDifficulty[0]
      }
    });
  } catch (error) {
    console.error('Lookups fetch error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/lookups/positions
 * Get fielding positions only
 */
router.get('/positions', async (req, res) => {
  try {
    const [positions] = await db.execute(`
      SELECT 
        fp.id, fp.position_code, fp.position_name, fp.position_category_id,
        fp.display_order, fp.is_active,
        pc.category_name
      FROM fielding_positions fp
      LEFT JOIN position_categories pc ON fp.position_category_id = pc.id
      WHERE fp.is_active = 1
      ORDER BY fp.display_order
    `);

    res.json({ success: true, positions });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/lookups/actions
 * Get fielding action types only
 */
router.get('/actions', async (req, res) => {
  try {
    const [actions] = await db.execute(`
      SELECT 
        fat.id, fat.action_category_id, fat.action_code, fat.action_name,
        fat.display_order, fat.is_positive, fat.is_active,
        fac.category_name
      FROM fielding_action_types fat
      LEFT JOIN fielding_action_categories fac ON fat.action_category_id = fac.id
      WHERE fat.is_active = 1
      ORDER BY fat.display_order
    `);

    res.json({ success: true, actions });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
