const mysql = require('mysql2/promise');
require('dotenv').config();

const poolConfig = {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    connectTimeout: 15000,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
};

// Enable SSL only for cloud DBs (e.g. TiDB Cloud); disable for local/private MySQL
if (process.env.DB_SSL === 'true' || (process.env.DB_HOST && process.env.DB_HOST.includes('tidbcloud.com'))) {
    poolConfig.ssl = { rejectUnauthorized: true };
}

const pool = mysql.createPool(poolConfig);

// Test connection (non-blocking; do not exit in serverless - Vercel kills the function)
pool.getConnection()
    .then(connection => {
        console.log('✅ Database connected successfully');
        console.log(`📊 Database: ${process.env.DB_NAME}`);
        connection.release();
    })
    .catch(err => {
        console.error('❌ Database connection failed:', err.message);
        // Do not process.exit(1) - crashes serverless functions on Vercel
    });

module.exports = pool;
