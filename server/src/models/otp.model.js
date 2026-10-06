const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class OtpModel {
  /**
   * Store a newly generated OTP hash
   */
  static async createOtp({ email, otpHash, purpose = 'AUTH', expiresAt }) {
    const id = generateUuid();
    const normalizedEmail = email.toLowerCase().trim();
    const now = new Date();

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO otps (id, email, otp_hash, purpose, attempts, is_used, expires_at, created_at)
         VALUES (?, ?, ?, ?, 0, FALSE, ?, ?)`,
        [id, normalizedEmail, otpHash, purpose, expiresAt, now]
      );
      return { id, email: normalizedEmail, otp_hash: otpHash, purpose, attempts: 0, is_used: false, expires_at: expiresAt, created_at: now };
    }

    // In-memory fallback
    const otpRecord = {
      id,
      email: normalizedEmail,
      otp_hash: otpHash,
      purpose,
      attempts: 0,
      is_used: false,
      expires_at: expiresAt,
      created_at: now,
    };
    db.inMemoryStore.otps.set(id, otpRecord);
    return otpRecord;
  }

  /**
   * Get the most recent active OTP for an email
   */
  static async getLatestActiveOtp(email, purpose = 'AUTH') {
    const normalizedEmail = email.toLowerCase().trim();
    const now = new Date();

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT * FROM otps 
         WHERE email = ? AND purpose = ? AND is_used = FALSE AND expires_at > ?
         ORDER BY created_at DESC 
         LIMIT 1`,
        [normalizedEmail, purpose, now]
      );
      return rows[0] || null;
    }

    // In-memory fallback
    const matching = [];
    for (const record of db.inMemoryStore.otps.values()) {
      if (
        record.email === normalizedEmail &&
        record.purpose === purpose &&
        !record.is_used &&
        new Date(record.expires_at) > now
      ) {
        matching.push(record);
      }
    }
    matching.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    return matching[0] || null;
  }

  /**
   * Get the latest OTP record (including recently sent for cooldown verification)
   */
  static async getLatestOtp(email, purpose = 'AUTH') {
    const normalizedEmail = email.toLowerCase().trim();

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT * FROM otps 
         WHERE email = ? AND purpose = ? 
         ORDER BY created_at DESC 
         LIMIT 1`,
        [normalizedEmail, purpose]
      );
      return rows[0] || null;
    }

    // In-memory fallback
    const matching = [];
    for (const record of db.inMemoryStore.otps.values()) {
      if (record.email === normalizedEmail && record.purpose === purpose) {
        matching.push(record);
      }
    }
    matching.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    return matching[0] || null;
  }

  /**
   * Increment failed verification attempts
   */
  static async incrementAttempts(id) {
    if (db.isConnected()) {
      await db.query('UPDATE otps SET attempts = attempts + 1 WHERE id = ?', [id]);
      const rows = await db.query('SELECT * FROM otps WHERE id = ?', [id]);
      return rows[0] || null;
    }

    // In-memory fallback
    const record = db.inMemoryStore.otps.get(id);
    if (record) {
      record.attempts += 1;
      db.inMemoryStore.otps.set(id, record);
      return record;
    }
    return null;
  }

  /**
   * Invalidate/mark OTP as used
   */
  static async markAsUsed(id) {
    if (db.isConnected()) {
      await db.query('UPDATE otps SET is_used = TRUE WHERE id = ?', [id]);
      return true;
    }

    // In-memory fallback
    const record = db.inMemoryStore.otps.get(id);
    if (record) {
      record.is_used = true;
      db.inMemoryStore.otps.set(id, record);
      return true;
    }
    return false;
  }

  /**
   * Invalidate all existing OTPs for an email
   */
  static async invalidateAllForEmail(email, purpose = 'AUTH') {
    const normalizedEmail = email.toLowerCase().trim();
    if (db.isConnected()) {
      await db.query('UPDATE otps SET is_used = TRUE WHERE email = ? AND purpose = ?', [normalizedEmail, purpose]);
      return true;
    }

    // In-memory fallback
    for (const record of db.inMemoryStore.otps.values()) {
      if (record.email === normalizedEmail && record.purpose === purpose) {
        record.is_used = true;
      }
    }
    return true;
  }
}

module.exports = OtpModel;
