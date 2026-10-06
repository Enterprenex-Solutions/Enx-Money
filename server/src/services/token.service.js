const jwt = require('jsonwebtoken');
const config = require('../config/env.config');
const TokenBlacklistModel = require('../models/tokenBlacklist.model');

class TokenService {
  /**
   * Generate a JWT access token for an authenticated user
   */
  static signAccessToken(user) {
    const crypto = require('crypto');
    const payload = {
      sub: user.id || user.sub,
      email: user.email,
      name: user.name,
      role: user.role || 'user',
      status: user.status || 'active',
      jti: crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2),
    };

    return jwt.sign(payload, config.JWT.SECRET, {
      expiresIn: config.JWT.EXPIRES_IN,
    });
  }

  static generateAccessToken(user) {
    return this.signAccessToken(user);
  }

  static generateTokens(user) {
    const accessToken = this.signAccessToken(user);
    return { accessToken };
  }

  /**
   * Verify a JWT token string
   */
  static async verifyAccessToken(token) {
    // 1. Check if blacklisted
    const isBlacklisted = await TokenBlacklistModel.isBlacklisted(token);
    if (isBlacklisted) {
      throw new Error('Token has been revoked/logged out');
    }

    // 2. Verify signature & expiration
    return jwt.verify(token, config.JWT.SECRET);
  }

  /**
   * Generate a temporary JWT reset token after OTP is verified (valid for 15 minutes)
   */
  static signResetToken(user) {
    const payload = {
      sub: user.id || user.sub,
      email: (user.email || '').toLowerCase().trim(),
      purpose: 'RESET_PASSWORD',
    };

    return jwt.sign(payload, config.JWT.SECRET, {
      expiresIn: '15m',
    });
  }

  /**
   * Verify a temporary JWT reset token
   */
  static async verifyResetToken(token) {
    if (!token) {
      throw new Error('Reset token is required');
    }

    const isBlacklisted = await TokenBlacklistModel.isBlacklisted(token);
    if (isBlacklisted) {
      throw new Error('Reset token has already been used or expired');
    }

    const decoded = jwt.verify(token, config.JWT.SECRET);
    if (decoded.purpose !== 'RESET_PASSWORD') {
      throw new Error('Invalid token purpose');
    }
    return decoded;
  }

  /**
   * Revoke token upon user logout
   */
  static async revokeToken(token, userId = null) {
    try {
      const decoded = jwt.decode(token);
      const expiresAt = decoded && decoded.exp ? new Date(decoded.exp * 1000) : null;
      await TokenBlacklistModel.blacklistToken(token, userId, expiresAt);
      return true;
    } catch {
      await TokenBlacklistModel.blacklistToken(token, userId);
      return true;
    }
  }
}

module.exports = TokenService;
