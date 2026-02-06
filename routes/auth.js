const express = require('express');
const router = express.Router();
const db = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');

/**
 * POST /api/auth/admin-login
 * Admin login with hardcoded credentials
 */
router.post(
    '/admin-login',
    [
        body('email').isEmail().normalizeEmail(),
        body('password').isLength({ min: 6 })
    ],
    async (req, res) => {
        // Validate input
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, password } = req.body;

        try {
            // Hardcoded admin credentials
            const adminEmail = 'admin@pcb.com.pk';
            const adminHashedPassword = '$2a$10$wIuorsZoC49i8hbvTnWjLOKv.Rj9T/89k2snOXsvwQQx.aT7/ezVq';

            // Verify email
            if (email !== adminEmail) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid email or password'
                });
            }

            // Verify password
            const isMatch = await bcrypt.compare(password, adminHashedPassword);
            if (!isMatch) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid email or password'
                });
            }

            // Generate JWT token
            const token = jwt.sign(
                {
                    email: adminEmail,
                    role: 'admin',
                    type: 'admin'
                },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '72h' }
            );

            res.json({
                success: true,
                message: 'Login successful',
                token,
                user: {
                    email: adminEmail,
                    role: 'admin'
                }
            });
        } catch (error) {
            console.error('Admin login error:', error);
            res.status(500).json({
                success: false,
                message: 'Server error during login'
            });
        }
    }
);

/**
 * POST /api/auth/user-login
 * User login with database verification
 */
router.post(
    '/user-login',
    [
        body('email').isEmail().normalizeEmail(),
        body('password').isLength({ min: 6 })
    ],
    async (req, res) => {
        // Validate input
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, password } = req.body;

        try {
            // Fetch user by email
            const [userRows] = await db.execute(
                `SELECT u.*, r.name as role_name 
         FROM users u
         LEFT JOIN roles r ON u.role_id = r.id
         WHERE u.email = ? AND u.active = 1`,
                [email]
            );

            if (userRows.length === 0) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid email or password'
                });
            }

            const user = userRows[0];

            // Verify password
            const isMatch = await bcrypt.compare(
                password,
                user.password.toString('utf-8')
            );

            if (!isMatch) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid email or password'
                });
            }

            // Generate JWT token
            const token = jwt.sign(
                {
                    id: user.id,
                    email: user.email,
                    role: user.role_name,
                    roleId: user.role_id,
                    type: 'user'
                },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '72h' }
            );

            // Update last login timestamp (optional)
            await db.execute(
                'UPDATE users SET updated_at = NOW() WHERE id = ?',
                [user.id]
            );

            res.json({
                success: true,
                message: 'Login successful',
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    role: user.role_name,
                    roleId: user.role_id,
                    isSupervisor: user.is_supervisor
                }
            });
        } catch (error) {
            console.error('User login error:', error);
            res.status(500).json({
                success: false,
                message: 'Server error during login'
            });
        }
    }
);

/**
 * POST /api/auth/reset-password
 * Reset user password (requires email and userId for verification)
 */
router.post(
    '/reset-password',
    [
        body('email').isEmail().normalizeEmail(),
        body('userId').isNumeric(),
        body('newPassword').isLength({ min: 6 })
    ],
    async (req, res) => {
        // Validate input
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, userId, newPassword } = req.body;

        try {
            // Verify user exists
            const [userRows] = await db.execute(
                'SELECT * FROM users WHERE id = ? AND email = ?',
                [userId, email]
            );

            if (userRows.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found with provided email and ID'
                });
            }

            const user = userRows[0];

            // Generate salt and hash new password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(newPassword, salt);

            // Update password
            const [updateResult] = await db.execute(
                'UPDATE users SET password = ?, password_salt = ?, updated_at = NOW() WHERE id = ?',
                [hashedPassword, salt, userId]
            );

            if (updateResult.affectedRows === 0) {
                return res.status(500).json({
                    success: false,
                    message: 'Failed to update password'
                });
            }

            res.json({
                success: true,
                message: 'Password reset successfully',
                userId: userId
            });
        } catch (error) {
            console.error('Password reset error:', error);
            res.status(500).json({
                success: false,
                message: 'An error occurred while resetting the password',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

/**
 * GET /api/auth/verify-token
 * Verify JWT token validity
 */
router.get('/verify-token', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'No token provided'
            });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        res.json({
            success: true,
            message: 'Token is valid',
            user: {
                id: decoded.id,
                email: decoded.email,
                role: decoded.role,
                type: decoded.type
            }
        });
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token has expired'
            });
        }

        res.status(401).json({
            success: false,
            message: 'Invalid token'
        });
    }
});

/**
 * POST /api/auth/logout
 * Logout endpoint (client-side token removal)
 */
router.post('/logout', (req, res) => {
    // In JWT-based auth, logout is handled client-side by removing the token
    // This endpoint can be used for logging purposes
    res.json({
        success: true,
        message: 'Logout successful. Please remove token from client.'
    });
});

module.exports = router;
