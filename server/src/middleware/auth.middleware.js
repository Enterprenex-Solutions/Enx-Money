const TokenService = require('../services/token.service');
const { errorResponse } = require('../utils/response.util');

/**
 * Authentication Middleware
 * Protects endpoints by validating JWT Bearer token
 */
async function authenticateToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Authentication required. Missing or malformed Bearer token.',
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Invalid authorization token.',
      });
    }

    // Verify token & blacklist state
    const decoded = await TokenService.verifyAccessToken(token);

    // Attach decoded user info and raw token to request object
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      name: decoded.name,
      role: decoded.role || 'user',
      status: decoded.status,
    };
    req.token = token;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Session has expired. Please log in again.',
      });
    }
    return errorResponse(res, {
      statusCode: 401,
      message: error.message || 'Invalid or revoked authentication token.',
    });
  }
}

/**
 * Admin Authorization Middleware
 * Guarantees only authorized admin accounts can access administrative analytics & endpoints
 */
async function requireAdmin(req, res, next) {
  try {
    if (!req.user || !req.user.id) {
      return errorResponse(res, {
        statusCode: 401,
        message: 'Authentication required. Missing admin credentials.',
      });
    }

    const adminEmails = (process.env.ADMIN_EMAIL || process.env.ADMIN_EMAILS || 'admin@enxmoney.com')
      .split(',')
      .map(e => e.trim().toLowerCase())
      .filter(Boolean);

    const userEmail = (req.user.email || '').toLowerCase().trim();

    // 1. Check if token already contains admin role or email is an authorized admin
    if (req.user.role === 'admin' || adminEmails.includes(userEmail)) {
      req.user.role = 'admin';
      return next();
    }

    // 2. Query database/in-memory store to check if role was elevated dynamically
    const UserModel = require('../models/user.model');
    const dbUser = await UserModel.findById(req.user.id);
    if (dbUser && (dbUser.role === 'admin' || adminEmails.includes((dbUser.email || '').toLowerCase().trim()))) {
      req.user.role = 'admin';
      return next();
    }

    // Reject non-admin users with 403 Forbidden
    return errorResponse(res, {
      statusCode: 403,
      message: 'Admin authorization required. Access denied.',
    });
  } catch (error) {
    return errorResponse(res, {
      statusCode: 500,
      message: 'Internal authorization error.',
    });
  }
}

async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      if (token) {
        const decoded = await TokenService.verifyAccessToken(token);
        req.user = {
          id: decoded.sub,
          email: decoded.email,
          name: decoded.name,
          role: decoded.role || 'user',
          status: decoded.status,
        };
        req.token = token;
      }
    }
  } catch (_) {
    // If token invalid, proceed with default user
  }
  next();
}

module.exports = {
  authenticateToken,
  authenticate: authenticateToken,
  requireAdmin,
  optionalAuth,
};
