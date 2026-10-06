/**
 * server/config/env.js — Compatibility shim for WhatsApp Chatbot scripts.
 *
 * Anjali's migrate_whatsapp.js and related scripts use require('../config/env').
 * The active production config lives in server/src/config/env.config.js.
 * This shim re-exports an object in the same shape Anjali's code expects.
 */

const dotenv = require('dotenv');
const path = require('path');

// Load .env from server root
dotenv.config({ path: path.join(__dirname, '../.env') });

const config = {
  env:  process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 5000,
  host: process.env.HOST || '0.0.0.0',

  db: {
    host:             process.env.DB_HOST     || '127.0.0.1',
    port:             parseInt(process.env.DB_PORT, 10) || 3306,
    user:             process.env.DB_USER     || 'root',
    password:         process.env.DB_PASSWORD || '',
    database:         process.env.DB_NAME     || 'enx_money_db',
    connectionLimit:  parseInt(process.env.DB_CONNECTION_LIMIT, 10) || 10,
    queueLimit:       parseInt(process.env.DB_QUEUE_LIMIT, 10) || 0,
    waitForConnections: true,
  },

  jwt: {
    secret:         process.env.JWT_SECRET         || 'enx_default_jwt_secret_fallback_key_2026',
    expiresIn:      process.env.JWT_EXPIRES_IN     || '7d',
    refreshSecret:  process.env.JWT_REFRESH_SECRET || 'enx_default_refresh_secret_key_2026',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },
};

module.exports = config;
