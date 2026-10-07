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

      // Generate signed JWT
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
