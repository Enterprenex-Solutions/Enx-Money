/**
 * ZeroCarbonix EWMS — Authentication, RBAC & Tenant Guards
 * Enforces fine-grained permissions, tenant isolation, and sensitive field masking.
 */

const jwt = require('jsonwebtoken');
const config = require('../../config');
const { repository } = require('../../database/ewms_repository');
const encryptionService = require('../../database/encryption.service');
const { DEFAULT_ROLE_PERMISSIONS } = require('../../../../../packages/shared/src/permissions');

/**
 * Authentication Middleware:
 * Validates the JWT Bearer token and attaches user profile + permissions to req.user
 */
function authenticateJwt(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Missing or malformed Bearer token',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.JWT_ACCESS_SECRET);
    const user = repository.users.find(u => u.id === decoded.sub && u.status === 'ACTIVE');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: User account inactive or does not exist',
      });
    }

    const employee = repository.employees.find(e => e.userId === user.id);
    const permissions = DEFAULT_ROLE_PERMISSIONS[user.role] || [];

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organizationId,
      employeeId: employee ? employee.id : null,
      employeeCode: employee ? employee.employeeCode : null,
      permissions,
    };

    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Invalid or expired access token',
      details: err.message,
    });
  }
}

/**
 * Permission Guard:
 * Validates that the user holds every specified permission.
 * Returns 403 Forbidden on violation.
 */
function requirePermissions(...requiredPermissions) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized: No active session' });
    }

    const userPermissions = new Set(req.user.permissions || []);
    const missing = requiredPermissions.filter(p => !userPermissions.has(p));

    if (missing.length > 0) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Insufficient permissions',
        required: requiredPermissions,
        missing,
      });
    }

    next();
  };
}

/**
 * Role Guard:
 * Validates that user holds one of the specified roles.
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized: No active session' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: Role unauthorized for this endpoint',
        userRole: req.user.role,
        allowedRoles,
      });
    }

    next();
  };
}

/**
 * Tenant Guard:
 * Ensures all operations are scoped strictly to the user's organizationId
 */
function tenantGuard(req, res, next) {
  if (!req.user) return next();
  const orgHeader = req.headers['x-organization-id'];
  if (orgHeader && orgHeader !== req.user.organizationId && req.user.role !== 'SUPER_ADMIN') {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Cross-organization access denied',
    });
  }
  req.organizationId = req.user.organizationId;
  next();
}

/**
 * Sensitive Fields Filter:
 * Enforces business rule:
 * - Managers cannot see salary or identity documents.
 * - HR sees HR data but not technical project details by default.
 * - Employees see only their own documents and salary.
 * - Clients see only their assigned projects.
 */
function sanitizeEmployeeProfile(employee, requestingUser) {
  if (!employee) return null;
  const clone = { ...employee };

  const isSelf = requestingUser && requestingUser.employeeId === employee.id;
  const isHrOrAdmin = requestingUser && ['HR_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN'].includes(requestingUser.role);

  if (isHrOrAdmin || isSelf) {
    clone.salary = clone.salaryEncrypted ? encryptionService.decrypt(clone.salaryEncrypted) : null;
    clone.bankAccount = clone.bankAccountEncrypted ? encryptionService.decrypt(clone.bankAccountEncrypted) : null;
    clone.taxId = clone.taxIdEncrypted ? encryptionService.decrypt(clone.taxIdEncrypted) : null;
  } else {
    // Explicitly masked for Managers, Team Leads, Peers, and Clients
    clone.salary = null;
    clone.bankAccount = null;
    clone.taxId = null;
  }

  delete clone.salaryEncrypted;
  delete clone.bankAccountEncrypted;
  delete clone.taxIdEncrypted;

  return clone;
}

module.exports = {
  authenticateJwt,
  requirePermissions,
  requireRole,
  tenantGuard,
  sanitizeEmployeeProfile,
};
