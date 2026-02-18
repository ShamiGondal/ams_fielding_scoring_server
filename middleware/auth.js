const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'feilding_ams_ec2';

/**
 * Middleware to verify JWT token
 */
const verifyToken = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: 'No authorization header provided'
            });
        }

        const token = authHeader.split(' ')[1]; // Bearer <token>

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'No token provided'
            });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token has expired'
            });
        }

        return res.status(401).json({
            success: false,
            message: 'Invalid token'
        });
    }
};

/**
 * Middleware to check if user is admin
 */
const isAdmin = (req, res, next) => {
    if (req.user && req.user.type === 'admin') {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: 'Access denied. Admin privileges required.'
        });
    }
};

/**
 * Middleware to check if user is supervisor
 */
const isSupervisor = (req, res, next) => {
    if (req.user && (req.user.type === 'admin' || req.user.isSupervisor)) {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: 'Access denied. Supervisor privileges required.'
        });
    }
};

/**
 * Middleware to check specific role
 */
const hasRole = (allowedRoles) => {
    return (req, res, next) => {
        if (req.user && allowedRoles.includes(req.user.role)) {
            next();
        } else {
            res.status(403).json({
                success: false,
                message: `Access denied. Required role: ${allowedRoles.join(' or ')}`
            });
        }
    };
};

module.exports = {
    verifyToken,
    isAdmin,
    isSupervisor,
    hasRole
};
