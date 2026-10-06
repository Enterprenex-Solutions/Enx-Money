const OtpModel = require('../models/otp.model');
const { generateSixDigitOtp, hashValue, compareHash } = require('../utils/crypto.util');
const config = require('../config/env.config');

function normalizePurpose(p) {
  if (!p) return 'AUTH';
  const up = String(p).toUpperCase().trim();
  if (up === 'PASSWORD_RESET') return 'RESET_PASSWORD';
  if (up === 'SIGNUP_VERIFICATION') return 'REGISTRATION';
  return up;
}

class OtpService {
  /**
   * Check if a resend request is rate-limited by cooldown
   */
  static async checkResendCooldown(emailOrPhone, purpose = 'AUTH') {
    const normalized = (emailOrPhone || '').toLowerCase().trim();
    const resolvedPurpose = normalizePurpose(purpose);
    const latest = await OtpModel.getLatestOtp(normalized, resolvedPurpose);
    if (!latest) return { allowed: true, remainingSeconds: 0 };

    const createdAt = new Date(latest.created_at).getTime();
    const elapsedSeconds = Math.floor((Date.now() - createdAt) / 1000);
    const cooldown = config.OTP.RESEND_COOLDOWN_SECONDS;

    if (elapsedSeconds < cooldown) {
      return {
        allowed: false,
        remainingSeconds: cooldown - elapsedSeconds,
      };
    }
    return { allowed: true, remainingSeconds: 0 };
  }

  /**
   * Generate, hash, and persist a new OTP
   */
  static async createAndStoreOtp(emailOrPhone, purpose = 'AUTH') {
    const normalized = (emailOrPhone || '').toLowerCase().trim();
    const resolvedPurpose = normalizePurpose(purpose);
    // 1. Invalidate any existing active OTPs for clean state
    await OtpModel.invalidateAllForEmail(normalized, resolvedPurpose);

    // 2. Generate raw 6-digit OTP
    const rawOtp = generateSixDigitOtp();

    // 3. Hash OTP before storing
    const otpHash = await hashValue(rawOtp);

    // 4. Calculate expiration (default: 5 minutes)
    const expiresAt = new Date(Date.now() + config.OTP.EXPIRY_MINUTES * 60 * 1000);

    // 5. Store record
    await OtpModel.createOtp({
      email: normalized,
      otpHash,
      purpose: resolvedPurpose,
      expiresAt,
    });

    return {
      rawOtp,
      expiresAt,
      expiryMinutes: config.OTP.EXPIRY_MINUTES,
    };
  }

  /**
   * Verify an OTP provided by the user
   */
  static async verifyOtp(emailOrPhone, plainOtp, purpose = 'AUTH') {
    const normalizedIdentifier = (emailOrPhone || '').toLowerCase().trim();
    const cleanOtp = (plainOtp || '').toString().trim();
    const resolvedPurpose = normalizePurpose(purpose);

    if (!cleanOtp || cleanOtp.length !== 6 || !/^\d+$/.test(cleanOtp)) {
      return {
        success: false,
        error: 'INVALID_FORMAT',
        message: 'Please enter a valid 6-digit verification code.',
      };
    }

    const activeOtp = await OtpModel.getLatestActiveOtp(normalizedIdentifier, resolvedPurpose);

    if (!activeOtp) {
      const latestOtp = await OtpModel.getLatestOtp(normalizedIdentifier, resolvedPurpose);
      if (latestOtp) {
        if (latestOtp.is_used) {
          return {
            success: false,
            error: 'ALREADY_USED',
            message: 'This verification code has already been used. Please request a new code.',
          };
        }
        if (new Date(latestOtp.expires_at) <= new Date()) {
          return {
            success: false,
            error: 'EXPIRED',
            message: 'This verification code has expired. Please request a new one.',
          };
        }
        if (latestOtp.attempts >= config.OTP.MAX_VERIFY_ATTEMPTS) {
          return {
            success: false,
            error: 'MAX_ATTEMPTS_EXCEEDED',
            message: 'Maximum verification attempts exceeded. Please request a new OTP.',
          };
        }
      }

      return {
        success: false,
        error: 'NOT_FOUND',
        message: 'No active verification code found for this email. Please request a new code.',
      };
    }

    // Check if max attempts reached
    if (activeOtp.attempts >= config.OTP.MAX_VERIFY_ATTEMPTS) {
      await OtpModel.markAsUsed(activeOtp.id);
      return {
        success: false,
        error: 'MAX_ATTEMPTS_EXCEEDED',
        message: 'Maximum verification attempts exceeded. Please request a new OTP.',
      };
    }

    // Check expiration
    if (new Date(activeOtp.expires_at) <= new Date()) {
      await OtpModel.markAsUsed(activeOtp.id);
      return {
        success: false,
        error: 'EXPIRED',
        message: 'This verification code has expired. Please request a new one.',
      };
    }

    // Compare hash securely
    const isValid = await compareHash(cleanOtp, activeOtp.otp_hash);

    if (!isValid) {
      // Increment attempt counter
      const updated = await OtpModel.incrementAttempts(activeOtp.id);
      const remainingAttempts = Math.max(0, config.OTP.MAX_VERIFY_ATTEMPTS - (updated ? updated.attempts : 1));

      return {
        success: false,
        error: 'INVALID_CODE',
        message: remainingAttempts > 0 
          ? `Invalid verification code. ${remainingAttempts} attempts remaining.`
          : 'Invalid verification code. Maximum attempts reached.',
        remainingAttempts,
      };
    }

    // Mark as used to prevent replay attacks
    await OtpModel.markAsUsed(activeOtp.id);

    return {
      success: true,
      message: 'OTP verified successfully.',
    };
  }
}

module.exports = OtpService;
