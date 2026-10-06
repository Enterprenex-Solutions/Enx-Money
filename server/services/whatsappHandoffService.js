/**
 * WhatsApp Handoff Service
 * Creates cryptographically secure, time-expiring handoff tokens for seamless
 * transition from WhatsApp to the full ENX Money Mobile (Flutter) or Web App.
 */

const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');

const HANDOFF_EXPIRY_MINUTES = 10;

/**
 * Generates a one-time handoff token and stores it in the database.
 */
async function createHandoffToken(userId, phoneNumber, targetScreen = 'dashboard', actionType = 'view_report', payload = {}) {
  const rawToken = `enx_${crypto.randomBytes(32).toString('hex')}`;
  const id = `ho-${uuidv4().replace(/-/g, '').slice(0, 10)}`;
  const expiresAt = new Date(Date.now() + HANDOFF_EXPIRY_MINUTES * 60 * 1000);

  await query(
    `INSERT INTO whatsapp_handoff_tokens (id, token, user_id, phone_number, target_screen, action_type, payload, is_used, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)`,
    [id, rawToken, userId, phoneNumber, targetScreen, actionType, JSON.stringify(payload), expiresAt]
  );

  return {
    token: rawToken,
    targetScreen,
    actionType,
    expiresAt,
    deepLink: `enxmoney://handoff?token=${rawToken}&screen=${encodeURIComponent(targetScreen)}`,
    webLink: `/api/v1/whatsapp/handoff/open?token=${rawToken}`,
  };
}

/**
 * Validates and consumes a handoff token.
 */
async function verifyAndConsumeToken(token) {
  if (!token) return { valid: false, message: 'Missing handoff token.' };

  const rows = await query(
    `SELECT h.*, u.name, u.email, u.role
     FROM whatsapp_handoff_tokens h
     JOIN users u ON h.user_id = u.id
     WHERE h.token = ?`,
    [token]
  );

  if (rows.length === 0) {
    return { valid: false, message: 'Invalid handoff link.' };
  }

  const record = rows[0];

  if (record.is_used) {
    return { valid: false, message: 'This handoff link has already been used.' };
  }

  if (new Date() > new Date(record.expires_at)) {
    return { valid: false, message: 'This handoff link has expired. Please request a new one on WhatsApp.' };
  }

  // Mark token as used
  await query('UPDATE whatsapp_handoff_tokens SET is_used = 1 WHERE id = ?', [record.id]);

  let payload = {};
  try {
    payload = typeof record.payload === 'string' ? JSON.parse(record.payload) : (record.payload || {});
  } catch {
    payload = {};
  }

  return {
    valid: true,
    user: {
      id: record.user_id,
      name: record.name,
      email: record.email,
      role: record.role,
    },
    targetScreen: record.target_screen,
    actionType: record.action_type,
    payload,
  };
}

module.exports = {
  createHandoffToken,
  verifyAndConsumeToken,
  HANDOFF_EXPIRY_MINUTES,
};
