const db = require('../config/db.config');
const { generateUuid, sha256Hash } = require('../utils/crypto.util');

class TokenBlacklistModel {
  /**
   * Blacklist a token on logout
   */
  static async blacklistToken(token, userId = null, expiresAt = null) {
    const id = generateUuid();
    const tokenHash = sha256Hash(token);
    const exp = expiresAt ? new Date(expiresAt) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const now = new Date();

    if (db.isConnected()) {
      await db.query(
        `INSERT IGNORE INTO token_blacklist (id, token_hash, user_id, expires_at, created_at)
         VALUES (?, ?, ?, ?, ?)`,
        [id, tokenHash, userId, exp, now]
      );
      return true;
    }

    // In-memory fallback
    db.inMemoryStore.tokenBlacklist.add(tokenHash);
    return true;
  }

  /**
   * Check if token is blacklisted
   */
  static async isBlacklisted(token) {
    const tokenHash = sha256Hash(token);

    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT id FROM token_blacklist WHERE token_hash = ? AND expires_at > ? LIMIT 1',
        [tokenHash, new Date()]
      );
      return rows.length > 0;
    }

    // In-memory fallback
    return db.inMemoryStore.tokenBlacklist.has(tokenHash);
  }
}

module.exports = TokenBlacklistModel;
