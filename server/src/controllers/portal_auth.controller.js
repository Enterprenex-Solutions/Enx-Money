/**
 * Enterprenex Solutions — Company Management Portal Authentication Controller
 * 
 * Implements the ONE Unified Login Engine:
 * - Single entrypoint for all employees and executives
 * - Automatic role & permissions resolution
 * - Automatic target dashboard routing
 * - Full security audit logging
 */

const jwt = require('jsonwebtoken');
const config = require('../config/env.config');
const { PortalModel } = require('../models/portal.model');
const { successResponse, errorResponse } = require('../utils/response.util');

class PortalAuthController {
  /**
   * Unified Portal Login Endpoint
   * POST /api/v1/portal/auth/login
   */
  static async login(req, res) {
    try {
      const { email, password, rememberMe } = req.body;

      if (!email || !password) {
        return errorResponse(res, {
          statusCode: 400,
          message: 'Company email and password are required'
        });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      const userAgent = req.headers['user-agent'] || '';

      const authResult = await PortalModel.authenticateUser(email, password);

      if (!authResult) {
        // Log failed attempt audit
        PortalModel.logAudit({
          userEmail: email,
          role: 'UNKNOWN',
          action: 'LOGIN_FAILED',
          resourceType: 'AUTH',
          ipAddress: clientIp,
          userAgent,
          details: { reason: 'Invalid email or password' }
        });

        return errorResponse(res, {
          statusCode: 401,
          message: 'Invalid company email or password. Please verify your credentials.'
        });
      }

      const { user, role, permissions, redirectUrl } = authResult;

      if (user.status !== 'ACTIVE') {
        PortalModel.logAudit({
          userId: user.id,
          userEmail: user.email,
          role,
          action: 'LOGIN_BLOCKED_INACTIVE',
          resourceType: 'AUTH',
          ipAddress: clientIp,
          userAgent
        });

        return errorResponse(res, {
          statusCode: 403,
          message: 'Your account is currently disabled or pending onboarding. Please contact HR.'
        });
      }

      // Generate signed Access JWT & Refresh JWT
      const expiresIn = rememberMe ? '30d' : (config.JWT?.EXPIRES_IN || config.JWT_EXPIRES_IN || '7d');
      const jwtSecret = config.JWT?.SECRET || config.JWT_SECRET || process.env.JWT_SECRET || 'enx_money_super_secret_jwt_key_2026';
      const token = jwt.sign(
        {
          id: user.id,
          employeeId: user.employeeId,
          email: user.email,
          name: user.name,
          role: user.role,
          department: user.department,
          permissions: user.permissions
        },
        jwtSecret,
        { expiresIn }
      );

      const refreshToken = jwt.sign(
        { id: user.id, email: user.email, type: 'REFRESH' },
        jwtSecret,
        { expiresIn: '30d' }
      );

      // Track active session & login history
      PortalModel.createSession({
        userId: user.id,
        email: user.email,
        role: user.role,
        token,
        refreshToken,
        ipAddress: clientIp,
        userAgent
      });

      PortalModel.recordLoginHistory({
        email: user.email,
        role: user.role,
        success: true,
        ipAddress: clientIp,
        userAgent
      });

      // Log successful login audit
      PortalModel.logAudit({
        userId: user.id,
        userEmail: user.email,
        role: user.role,
        action: 'LOGIN_SUCCESS',
        resourceType: 'AUTH',
        ipAddress: clientIp,
        userAgent,
        details: { redirectUrl, rememberMe: Boolean(rememberMe) }
      });

      return successResponse(res, {
        statusCode: 200,
        message: `Welcome back, ${user.name}! Authenticated as ${user.role}.`,
        data: {
          token,
          refreshToken,
          user: {
            id: user.id,
            employeeId: user.employeeId,
            name: user.name,
            email: user.email,
            role: user.role,
            department: user.department,
            designation: user.designation,
            permissions: user.permissions,
          },
          redirectUrl
        }
      });
    } catch (err) {
      console.error('[Portal Auth Error]', err);
      return errorResponse(res, {
        statusCode: 500,
        message: 'Internal authentication server error'
      });
    }
  }

  /**
   * Token Refresh Endpoint
   * POST /api/v1/portal/auth/refresh
   */
  static async refresh(req, res) {
    try {
      const { refreshToken } = req.body;
      if (!refreshToken) {
        return errorResponse(res, { statusCode: 400, message: 'Refresh token is required' });
      }

      const jwtSecret = config.JWT?.SECRET || config.JWT_SECRET || process.env.JWT_SECRET || 'enx_money_super_secret_jwt_key_2026';
      let decoded;
      try {
        decoded = jwt.verify(refreshToken, jwtSecret);
      } catch (e) {
        return errorResponse(res, { statusCode: 401, message: 'Invalid or expired refresh token' });
      }

      const session = PortalModel.getSessionByRefreshToken(refreshToken);
      if (!session) {
        return errorResponse(res, { statusCode: 401, message: 'Session revoked or expired' });
      }

      const user = PortalModel.getUserById(decoded.id || decoded.email);
      if (!user || user.status !== 'ACTIVE') {
        return errorResponse(res, { statusCode: 403, message: 'User account disabled' });
      }

      const permissions = PortalModel.getRolePermissions(user.role);
      const newToken = jwt.sign(
        {
          id: user.id,
          employeeId: user.employeeId,
          email: user.email,
          name: user.name,
          role: user.role,
          department: user.department,
          permissions
        },
        jwtSecret,
        { expiresIn: '7d' }
      );

      session.token = newToken;
      session.lastActiveAt = new Date().toISOString();

      return successResponse(res, {
        statusCode: 200,
        message: 'Access token renewed successfully',
        data: { token: newToken, refreshToken }
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Get Active Authenticated Profile
   * GET /api/v1/portal/auth/me
   */
  static async me(req, res) {
    try {
      const user = req.portalUser;
      const today = new Date().toISOString().split('T')[0];
      const history = PortalModel.getAttendanceHistory(user.employeeId, 1);
      const todayAttendance = history.find(h => h.date === today) || null;

      return successResponse(res, {
        statusCode: 200,
        message: 'Active session profile retrieved',
        data: {
          user,
          todayAttendance: todayAttendance ? {
            status: todayAttendance.status,
            clockInTime: todayAttendance.clockInTime,
            clockOutTime: todayAttendance.clockOutTime,
            durationMinutes: todayAttendance.durationMinutes,
            isClockedIn: !todayAttendance.clockOutTime && Boolean(todayAttendance.clockInTime)
          } : { isClockedIn: false },
          redirectUrl: PortalModel.resolveRoleRedirect(user.role)
        }
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Request Password Reset
   * POST /api/v1/portal/auth/forgot-password
   */
  static async forgotPassword(req, res) {
    try {
      const { email } = req.body;
      if (!email) {
        return errorResponse(res, { statusCode: 400, message: 'Company email is required' });
      }

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userEmail: email,
        role: 'GUEST',
        action: 'FORGOT_PASSWORD_REQUESTED',
        resourceType: 'AUTH',
        ipAddress: clientIp
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'If your email is registered with Enterprenex Solutions, password reset instructions have been forwarded to your company inbox.'
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Complete Password Reset
   * POST /api/v1/portal/auth/reset-password
   */
  static async resetPassword(req, res) {
    try {
      const { email, newPassword } = req.body;
      if (!email || !newPassword) {
        return errorResponse(res, { statusCode: 400, message: 'Email and new password are required' });
      }

      const user = PortalModel.getUserById(email);
      if (!user) {
        return errorResponse(res, { statusCode: 404, message: 'User not found' });
      }

      PortalModel.updateUser(user.id, { password: newPassword });

      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      PortalModel.logAudit({
        userId: user.id,
        userEmail: user.email,
        role: user.role,
        action: 'PASSWORD_RESET_SUCCESS',
        resourceType: 'AUTH',
        ipAddress: clientIp
      });

      return successResponse(res, {
        statusCode: 200,
        message: 'Password reset successful. Please log in with your new credentials.'
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * List Active Sessions
   * GET /api/v1/portal/auth/sessions
   */
  static async getSessions(req, res) {
    try {
      const sessions = PortalModel.getUserSessions(req.portalUser.id);
      return successResponse(res, {
        statusCode: 200,
        message: 'Active sessions retrieved',
        data: sessions
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Revoke Session
   * POST /api/v1/portal/auth/sessions/revoke
   */
  static async revokeSession(req, res) {
    try {
      const { sessionId } = req.body;
      const revoked = PortalModel.revokeSession(sessionId);
      return successResponse(res, {
        statusCode: 200,
        message: revoked ? 'Session revoked successfully' : 'Session not found'
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Get Login History
   * GET /api/v1/portal/auth/login-history
   */
  static async getLoginHistory(req, res) {
    try {
      const email = req.portalUser.role === 'SUPER_ADMIN' ? null : req.portalUser.email;
      const history = PortalModel.getLoginHistory(email);
      return successResponse(res, {
        statusCode: 200,
        message: 'Login history retrieved',
        data: history
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }

  /**
   * Logout session
   * POST /api/v1/portal/auth/logout
   */
  static async logout(req, res) {
    try {
      const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
      if (req.portalUser) {
        PortalModel.logAudit({
          userId: req.portalUser.id,
          userEmail: req.portalUser.email,
          role: req.portalUser.role,
          action: 'LOGOUT',
          resourceType: 'AUTH',
          ipAddress: clientIp
        });
      }
      return successResponse(res, {
        statusCode: 200,
        message: 'Logged out successfully from Enterprenex Portal'
      });
    } catch (err) {
      return errorResponse(res, { statusCode: 500, message: err.message });
    }
  }
}

module.exports = PortalAuthController;
