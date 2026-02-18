const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import database connection
const db = require('./config/database');

// Make database available to routes
app.locals.db = db;

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/fielding-scoring', require('./routes/fieldingScoring'));
app.use('/api/fielding-plans', require('./routes/fieldingPlans'));
app.use('/api/fielding-templates', require('./routes/fieldingTemplates'));
app.use('/api/lookups', require('./routes/lookups'));
app.use('/api/matches', require('./routes/matches'));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date(),
        database: process.env.DB_NAME,
        environment: process.env.NODE_ENV
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Cricket Fielding Scoring System API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            auth: '/api/auth',
            users: '/api/users',
            fieldingScoring: '/api/fielding-scoring',
            fieldingPlans: '/api/fielding-plans',
            fieldingTemplates: '/api/fielding-templates',
            matches: '/api/matches'
        }
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(err.status || 500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'An error occurred'
    });
});

// Start server only when running locally (not on Vercel serverless)
if (!process.env.VERCEL) {
    const HOST = process.env.HOST || '0.0.0.0';
    app.listen(PORT, HOST, () => {
        console.log('🚀 Cricket Fielding Scoring System API');
        console.log(`📡 Server running on ${HOST}:${PORT}`);
        console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
        console.log(`🔗 CORS Origin: ${process.env.CORS_ORIGIN}`);
        console.log(`⏰ JWT Expiry: ${process.env.JWT_EXPIRES_IN}`);
        console.log(`📊 Database: ${process.env.DB_NAME}`);
        console.log('');
        console.log(`🔗 API URL: http://${HOST}:${PORT}`);
        console.log(`🏥 Health Check: http://${HOST}:${PORT}/health`);
    });
}

module.exports = app;
