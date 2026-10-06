const app = require('./src/app');
const config = require('./src/config/env.config');
const { initDb, getPool } = require('./src/config/db.config');

let server;

async function startServer() {
  try {
    // 1. Initialize MySQL Database and schema
    await initDb();

    // 2. Start Express HTTP Server
    const HOST = '0.0.0.0';
    server = app.listen(config.PORT, HOST, () => {
      console.log(`
======================================================
🚀 ENX Money Backend Server Running
📡 Host & Port:  ${HOST}:${config.PORT}
🌍 Environment:  ${config.NODE_ENV}
🛡️  Security:     JWT + 6-digit OTP + Helmet + CORS
💾 Database:     ${config.DB.HOST}:${config.DB.PORT}/${config.DB.NAME}
======================================================
      `);
    });

    // 3. Keep-Alive Self-Ping (Prevents Render Free Tier Cold Sleep)
    const https = require('https');
    const http = require('http');
    const KEEP_ALIVE_URL = process.env.KEEP_ALIVE_URL || 'https://enx-money-api.onrender.com/health';
    const keepAliveTimer = setInterval(() => {
      const client = KEEP_ALIVE_URL.startsWith('https') ? https : http;
      client.get(KEEP_ALIVE_URL, (res) => {
        console.log(`[Keep-Alive] Pinged ${KEEP_ALIVE_URL} - Status: ${res.statusCode}`);
      }).on('error', (err) => {
        console.warn(`[Keep-Alive] Ping notice:`, err.message);
      });
    }, 8 * 60 * 1000); // Ping every 8 minutes (Render sleeps at 15 min)
    if (keepAliveTimer.unref) keepAliveTimer.unref();

    // 4. Graceful Shutdown Handlers
    const handleShutdown = async (signal) => {
      console.log(`\n[Server] Received ${signal}. Shutting down gracefully...`);
      if (keepAliveTimer) clearInterval(keepAliveTimer);
      if (server) {
        server.close(async () => {
          console.log('[Server] HTTP server closed.');
          const pool = getPool();
          if (pool) {
            await pool.end();
            console.log('[Database] MySQL pool closed.');
          }
          process.exit(0);
        });
      } else {
        process.exit(0);
      }
    };

    process.on('SIGTERM', () => handleShutdown('SIGTERM'));
    process.on('SIGINT', () => handleShutdown('SIGINT'));
  } catch (error) {
    console.error('[Server Error] Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
