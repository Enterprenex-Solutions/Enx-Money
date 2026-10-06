const rateLimit = require('express-rate-limit');
const { errorResponse } = require('../utils/response.util');

/**
 * Rate limiter for OTP generation/sending
 * Limit: 10 requests per 15 minutes per IP
 */
const isTestEnv = process.env.NODE_ENV === 'test' || process.env.JEST_WORKER_ID !== undefined;

const otpRateLimiter = isTestEnv
  ? (req, res, next) => next()
  : rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 30,
      standardHeaders: true,
      legacyHeaders: false,
      validate: { xForwardedForHeader: false },
      handler: (req, res) => {
        return errorResponse(res, {
          statusCode: 429,
          message: 'Too many OTP requests from this IP address. Please try again after 15 minutes.',
        });
      },
    });

/**
 * General API Rate Limiter
 * Limit: 300 requests per 15 minutes per IP
 */
const apiRateLimiter = isTestEnv
  ? (req, res, next) => next()
  : rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 300,
      standardHeaders: true,
      legacyHeaders: false,
      validate: { xForwardedForHeader: false },
      handler: (req, res) => {
        return errorResponse(res, {
          statusCode: 429,
          message: 'Too many requests. Please slow down.',
        });
      },
    });

module.exports = {
  otpRateLimiter,
  apiRateLimiter,
};
