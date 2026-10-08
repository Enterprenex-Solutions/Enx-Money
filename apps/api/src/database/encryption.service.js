/**
 * ZeroCarbonix EWMS — Field-Level Encryption Service
 * Implements AES-256-GCM for sensitive fields (salary, bank details, tax IDs)
 */

const crypto = require('crypto');
const config = require('../config');

class EncryptionService {
  constructor() {
    this.algorithm = 'aes-256-gcm';
    // Ensure key is 32 bytes
    this.key = crypto.createHash('sha256').update(String(config.FIELD_ENCRYPTION_KEY)).digest();
  }

  encrypt(text) {
    if (!text) return null;
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    let encrypted = cipher.update(String(text), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag().toString('hex');
    return `${iv.toString('hex')}:${authTag}:${encrypted}`;
  }

  decrypt(cipherText) {
    if (!cipherText || !cipherText.includes(':')) return cipherText;
    try {
      const [ivHex, authTagHex, encryptedText] = cipherText.split(':');
      const iv = Buffer.from(ivHex, 'hex');
      const authTag = Buffer.from(authTagHex, 'hex');
      const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
      decipher.setAuthTag(authTag);
      let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      return decrypted;
    } catch (_) {
      return '[ENCRYPTED_DATA]';
    }
  }
}

module.exports = new EncryptionService();
