const crypto = require('crypto');
const bcrypt = require('bcryptjs');

/**
 * Generate a cryptographically secure 6-digit numeric OTP
 */
function generateSixDigitOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

/**
 * Hash a string (e.g. OTP) using bcrypt
 */
async function hashValue(value) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(value, salt);
}

/**
 * Compare plain value against hash
 */
async function compareHash(plainValue, hash) {
  return bcrypt.compare(plainValue, hash);
}

/**
 * Generate a SHA256 hash (e.g. for token blacklisting)
 */
function sha256Hash(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

/**
 * Generate UUID v4
 */
function generateUuid() {
  return crypto.randomUUID();
}

module.exports = {
  generateSixDigitOtp,
  hashValue,
  compareHash,
  sha256Hash,
  generateUuid,
};
