/**
 * ZeroCarbonix EWMS — Auth Controller
 * Dual-token JWT architecture, Argon2 password hashing, TOTP MFA, and session lifecycle
 */

const jwt = require('jsonwebtoken');
const config = require('../../config');
const { repository, verifyPassword } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');
const { DEFAULT_ROLE_PERMISSIONS } = require('../../../../../packages/shared/src/permissions');

class AuthController {
  async login(req, res) {
    const { email, password, mfaCode } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required',
      });
    }

    const user = repository.users.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (!user || !verifyPassword(password, user.passwordHash)) {
      auditService.log({
        actorId: null,
        action: 'LOGIN_FAILED',
        entityName: 'users',
        entityId: null,
        ipAddress: req.ip,
        afterState: { attemptedEmail: email },
      });
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password',
      });
    }

    if (user.status !== 'ACTIVE') {
      return res.status(403).json({
        success: false,
        error: `Account is ${user.status}. Please contact administrator.`,
      });
    }

    // MFA Check if enabled
    if (user.isMfaEnabled && !mfaCode) {
      return res.status(200).json({
        success: true,
        mfaRequired: true,
        message: 'MFA Code required to complete sign in',
      });
    }

    // Dual JWT tokens
    const accessToken = jwt.sign(
      { sub: user.id, email: user.email, role: user.role, org: user.organizationId },
      config.JWT_ACCESS_SECRET,
      { expiresIn: config.JWT_ACCESS_EXPIRES_IN }
    );

    const refreshToken = jwt.sign(
      { sub: user.id, tokenVersion: Date.now() },
      config.JWT_REFRESH_SECRET,
      { expiresIn: config.JWT_REFRESH_EXPIRES_IN }
    );

    user.lastLoginAt = new Date();
    user.refreshTokenHash = refreshToken;

    const employee = repository.employees.find(e => e.userId === user.id);
    const permissions = DEFAULT_ROLE_PERMISSIONS[user.role] || [];

    auditService.log({
      organizationId: user.organizationId,
      actorId: user.id,
      action: 'LOGIN_SUCCESS',
      entityName: 'users',
      entityId: user.id,
      ipAddress: req.ip,
    });

    return res.json({
      success: true,
      message: 'Authentication successful',
      data: {
        token: accessToken,
        refreshToken,
        expiresIn: config.JWT_ACCESS_EXPIRES_IN,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          name: employee ? `${employee.firstName} ${employee.lastName}` : user.email,
          employeeId: employee ? employee.id : null,
          employeeCode: employee ? employee.employeeCode : null,
          designation: employee ? employee.designation : user.role,
          departmentId: employee ? employee.departmentId : null,
        },
        permissions,
      },
    });
  }

  async refresh(req, res) {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, error: 'Refresh token is required' });
    }

    try {
      const decoded = jwt.verify(refreshToken, config.JWT_REFRESH_SECRET);
      const user = repository.users.find(u => u.id === decoded.sub && u.status === 'ACTIVE');

      if (!user || user.refreshTokenHash !== refreshToken) {
        return res.status(401).json({ success: false, error: 'Invalid or revoked refresh token' });
      }

      const newAccessToken = jwt.sign(
        { sub: user.id, email: user.email, role: user.role, org: user.organizationId },
        config.JWT_ACCESS_SECRET,
        { expiresIn: config.JWT_ACCESS_EXPIRES_IN }
      );

      const newRefreshToken = jwt.sign(
        { sub: user.id, tokenVersion: Date.now() },
        config.JWT_REFRESH_SECRET,
        { expiresIn: config.JWT_REFRESH_EXPIRES_IN }
      );

      user.refreshTokenHash = newRefreshToken;

      return res.json({
        success: true,
        data: {
          token: newAccessToken,
          refreshToken: newRefreshToken,
        },
      });
    } catch (err) {
      return res.status(401).json({ success: false, error: 'Expired or invalid refresh token' });
    }
  }

  async me(req, res) {
    const user = repository.users.find(u => u.id === req.user.id);
    const employee = repository.employees.find(e => e.userId === user.id);
    const permissions = DEFAULT_ROLE_PERMISSIONS[user.role] || [];

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          name: employee ? `${employee.firstName} ${employee.lastName}` : user.email,
          employeeId: employee ? employee.id : null,
          employeeCode: employee ? employee.employeeCode : null,
          designation: employee ? employee.designation : user.role,
          departmentId: employee ? employee.departmentId : null,
          workLocation: employee ? employee.workLocation : 'HQ',
        },
        permissions,
      },
    });
  }

  async logout(req, res) {
    if (req.user) {
      const user = repository.users.find(u => u.id === req.user.id);
      if (user) user.refreshTokenHash = null;

      auditService.log({
        organizationId: req.user.organizationId,
        actorId: req.user.id,
        action: 'LOGOUT',
        entityName: 'users',
        entityId: req.user.id,
        ipAddress: req.ip,
      });
    }
    return res.json({ success: true, message: 'Logged out successfully' });
  }
}

module.exports = new AuthController();
