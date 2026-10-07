/**
 * Enterprenex Solutions — Company Management Portal RBAC & Security Middleware
 * 
 * Enforces strict backend authorization:
 * 1. Token authentication (JWT verify)
 * 2. Granular permission checking (requirePermission)
 * 3. Role enforcement (requireRole)
 * 4. Multi-tenancy & Department data scoping (scopeDepartmentAccess)
 * 5. Self-only data restriction for staff (scopeSelfOrElevated)
 */

const jwt = require('jsonwebtoken');
const config = require('../config/env.config');
const { PortalModel, ROLES, PERMISSIONS } = require('../models/portal.model');

/**
 * Authenticate JWT token and attach user + permissions to req.portalUser
 */
function authenticatePortalToken(req, res, next) {
  let token = null;
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.split(' ')[1];
  } else if (req.cookies && req.cookies.portal_token) {
    token = req.cookies.portal_token;
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required. Please log in to Enterprenex Portal.'
    });
  }

  try {
    const jwtSecret = config.JWT?.SECRET || config.JWT_SECRET || process.env.JWT_SECRET || 'enx_money_super_secret_jwt_key_2026';
    const decoded = jwt.verify(token, jwtSecret);
    const emp = PortalModel.getEmployeeById(decoded.employeeId || decoded.id);
    const role = decoded.role || (emp ? emp.role : ROLES.EMPLOYEE);
    const permissions = PortalModel.getRolePermissions(role);

    req.portalUser = {
      id: decoded.id,
      employeeId: decoded.employeeId || decoded.id,
      email: decoded.email,
      name: decoded.name || (emp ? emp.name : 'Enterprenex User'),
      role,
      department: decoded.department || (emp ? emp.department : 'GENERAL'),
      permissions,
    };
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired portal session. Please log in again.'
    });
  }
}

/**
 * Require a specific granular permission
 * Unauthorized requests return 403 Forbidden and record security audit log
 */
function requirePermission(requiredPermission) {
  return (req, res, next) => {
    if (!req.portalUser) {
      return res.status(401).json({ success: false, error: 'Unauthorized session' });
    }

    const { role, permissions, email, id } = req.portalUser;

    // Super Admin has universal override
    if (role === ROLES.SUPER_ADMIN || (permissions && permissions.includes(requiredPermission))) {
      return next();
    }

    // Log security violation audit trail
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
    PortalModel.logAudit({
      userId: id,
      userEmail: email,
      role,
      action: 'PERMISSION_DENIED',
      resourceType: 'API_ENDPOINT',
      resourceId: req.originalUrl,
      ipAddress: clientIp,
      details: { requiredPermission, method: req.method }
    });

    return res.status(403).json({
      success: false,
      error: `Forbidden: Missing required permission [${requiredPermission}]`
    });
  };
}

/**
 * Require one or more specific roles
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.portalUser) {
      return res.status(401).json({ success: false, error: 'Unauthorized session' });
    }

    const { role, email, id } = req.portalUser;

    if (role === ROLES.SUPER_ADMIN || allowedRoles.includes(role)) {
      return next();
    }

    // Log security violation audit trail
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || req.ip;
    PortalModel.logAudit({
      userId: id,
      userEmail: email,
      role,
      action: 'ROLE_DENIED',
      resourceType: 'API_ENDPOINT',
      resourceId: req.originalUrl,
      ipAddress: clientIp,
      details: { allowedRoles, actualRole: role, method: req.method }
    });

    return res.status(403).json({
      success: false,
      error: `Forbidden: Access restricted to roles [${allowedRoles.join(', ')}]`
    });
  };
}

/**
 * Department scoping:
 * If Department Head, restrict queries to their own department
 */
function scopeDepartmentAccess(req, res, next) {
  if (!req.portalUser) return next();
  const { role, department } = req.portalUser;

  if (role === ROLES.DEPT_HEAD) {
    req.departmentScope = department;
  }
  next();
}

/**
 * Self-or-Elevated scoping:
 * Regular Employees & Interns can only view or modify their own records
 */
function scopeSelfOrElevated(paramName = 'employeeId') {
  return (req, res, next) => {
    if (!req.portalUser) return next();
    const { role, id, employeeId, permissions } = req.portalUser;

    const elevatedRoles = [ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR];
    if (elevatedRoles.includes(role) || permissions.includes(PERMISSIONS.VIEW_EMPLOYEES)) {
      return next();
    }

    const targetId = req.params[paramName] || req.query[paramName] || req.body[paramName];
    if (targetId && targetId !== id && targetId !== employeeId) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You are only authorized to view or manage your own records.'
      });
    }

    next();
  };
}

module.exports = {
  authenticatePortalToken,
  requirePermission,
  requireRole,
  scopeDepartmentAccess,
  scopeSelfOrElevated,
};
