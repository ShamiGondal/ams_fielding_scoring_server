const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { verifyToken, isAdmin } = require('../middleware/auth');

/**
 * GET /api/users
 * Get all users (admin only)
 */
router.get('/', verifyToken, isAdmin, async (req, res) => {
    try {
        const { role_id, active, limit = 50, offset = 0 } = req.query;

        let query = `
      SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.active,
        u.is_supervisor,
        u.is_email_verify,
        u.is_root,
        u.created_at,
        u.updated_at,
        r.name as role_name,
        r.id as role_id
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      WHERE 1=1
    `;

        const params = [];

        if (role_id) {
            query += ' AND u.role_id = ?';
            params.push(role_id);
        }

        if (active !== undefined) {
            query += ' AND u.active = ?';
            params.push(active);
        }

        query += ' ORDER BY u.created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [users] = await db.execute(query, params);

        res.json({
            success: true,
            message: 'Users retrieved successfully',
            count: users.length,
            users: users.map(user => ({
                ...user,
                password: undefined,
                password_salt: undefined
            }))
        });
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while retrieving users',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * GET /api/users/:id
 * Get single user by ID (admin or own profile)
 */
router.get('/:id', verifyToken, async (req, res) => {
    try {
        const userId = req.params.id;

        // Check if user is accessing their own profile or is admin
        if (req.user.type !== 'admin' && req.user.id !== parseInt(userId)) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You can only view your own profile.'
            });
        }

        const [users] = await db.execute(
            `SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.active,
        u.is_supervisor,
        u.is_email_verify,
        u.is_root,
        u.created_at,
        u.updated_at,
        r.name as role_name,
        r.id as role_id
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      WHERE u.id = ?`,
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        const user = users[0];
        delete user.password;
        delete user.password_salt;

        res.json({
            success: true,
            user
        });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while retrieving user',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * PATCH /api/users/:id
 * Update user details (admin or own profile)
 */
router.patch('/:id', verifyToken, async (req, res) => {
    try {
        const userId = req.params.id;

        // Check if user is accessing their own profile or is admin
        if (req.user.type !== 'admin' && req.user.id !== parseInt(userId)) {
            return res.status(403).json({
                success: false,
                message: 'Access denied. You can only update your own profile.'
            });
        }

        const updates = req.body;
        const allowedFields = ['first_name', 'last_name', 'contact', 'address'];

        // Admin can update additional fields
        if (req.user.type === 'admin') {
            allowedFields.push('active', 'is_supervisor', 'role_id');
        }

        const filteredUpdates = {};
        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                filteredUpdates[field] = updates[field];
            }
        }

        if (Object.keys(filteredUpdates).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No valid fields to update'
            });
        }

        const fields = Object.keys(filteredUpdates).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(filteredUpdates), userId];

        await db.execute(
            `UPDATE users SET ${fields}, updated_at = NOW() WHERE id = ?`,
            values
        );

        res.json({
            success: true,
            message: 'User updated successfully',
            updated_id: userId,
            updated_fields: Object.keys(filteredUpdates)
        });
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while updating user',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * GET /api/users/role/:roleId
 * Get users by role ID (admin only)
 */
router.get('/role/:roleId', verifyToken, isAdmin, async (req, res) => {
    try {
        const roleId = req.params.roleId;

        const [users] = await db.execute(
            `SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.active,
        u.is_supervisor,
        u.is_email_verify,
        u.created_at,
        r.name as role_name
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      WHERE u.role_id = ?
      ORDER BY u.created_at DESC`,
            [roleId]
        );

        res.json({
            success: true,
            message: 'Users retrieved successfully',
            count: users.length,
            users: users.map(user => ({
                ...user,
                password: undefined,
                password_salt: undefined
            }))
        });
    } catch (error) {
        console.error('Get users by role error:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while retrieving users',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

module.exports = router;
