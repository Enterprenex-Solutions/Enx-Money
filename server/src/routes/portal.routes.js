/**
 * Enterprenex Solutions — Company Management Portal Unified Routes
 * 
 * All protected endpoints enforce RBAC & Granular Permission verification.
 * Any unauthorized API request directly returns 403 Forbidden.
 */

const express = require('express');
const router = express.Router();

const PortalAuthController = require('../controllers/portal_auth.controller');
const PortalManagementController = require('../controllers/portal_management.controller');
const {
  authenticatePortalToken,
  requirePermission,
  requireRole,
  scopeDepartmentAccess,
} = require('../middleware/portal_rbac.middleware');
const { ROLES, PERMISSIONS } = require('../models/portal.model');

// ─── AUTHENTICATION (UNIFIED ENTRYPOINT) ────────────────
router.post('/auth/login', PortalAuthController.login);
router.get('/auth/me', authenticatePortalToken, PortalAuthController.me);
router.post('/auth/forgot-password', PortalAuthController.forgotPassword);
router.post('/auth/logout', PortalAuthController.logout);

// ─── HR & EMPLOYEE MANAGEMENT ──────────────────────────
router.get(
  '/employees',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_EMPLOYEES),
  scopeDepartmentAccess,
  PortalManagementController.getEmployees
);

router.post(
  '/employees',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CREATE_EMPLOYEE),
  PortalManagementController.createEmployee
);

router.patch(
  '/employees/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.EDIT_EMPLOYEE),
  PortalManagementController.updateEmployee
);

router.delete(
  '/employees/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.DELETE_EMPLOYEE),
  PortalManagementController.deleteEmployee
);

// ─── ATTENDANCE & LEAVES ───────────────────────────────
router.post(
  '/attendance/clock-in',
  authenticatePortalToken,
  PortalManagementController.clockIn
);

router.post(
  '/attendance/clock-out',
  authenticatePortalToken,
  PortalManagementController.clockOut
);

router.get(
  '/attendance/my-history',
  authenticatePortalToken,
  PortalManagementController.getMyAttendanceHistory
);

router.get(
  '/attendance/live',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_ATTENDANCE),
  scopeDepartmentAccess,
  PortalManagementController.getLiveAttendance
);

router.post(
  '/leaves',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.APPLY_LEAVE),
  PortalManagementController.applyLeave
);

router.get(
  '/leaves',
  authenticatePortalToken,
  scopeDepartmentAccess,
  PortalManagementController.getLeaves
);

router.patch(
  '/leaves/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.MANAGE_LEAVES),
  PortalManagementController.updateLeaveStatus
);

// ─── TASKS & KANBAN ────────────────────────────────────
router.get(
  '/tasks',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_TASKS),
  scopeDepartmentAccess,
  PortalManagementController.getTasks
);

router.post(
  '/tasks',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CREATE_TASK),
  PortalManagementController.createTask
);

router.patch(
  '/tasks/:id/status',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.EDIT_TASK),
  PortalManagementController.updateTaskStatus
);

// ─── PROJECTS ──────────────────────────────────────────
router.get(
  '/projects',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_PROJECTS),
  scopeDepartmentAccess,
  PortalManagementController.getProjects
);

router.post(
  '/projects',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CREATE_PROJECT),
  PortalManagementController.createProject
);

// ─── DOCUMENTS VAULT ───────────────────────────────────
router.get(
  '/documents',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_DOCUMENTS),
  PortalManagementController.getDocuments
);

router.post(
  '/documents',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.UPLOAD_DOCUMENT),
  PortalManagementController.uploadDocument
);

// ─── EXECUTIVE SPECIALIZED COCKPITS ────────────────────
router.get(
  '/executive/ceo',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO),
  requirePermission(PERMISSIONS.VIEW_ANALYTICS),
  PortalManagementController.getCeoOverview
);

router.get(
  '/executive/cto',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CTO),
  requirePermission(PERMISSIONS.VIEW_TECH_SYSTEMS),
  PortalManagementController.getCtoOverview
);

router.get(
  '/executive/cfo',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CFO),
  requirePermission(PERMISSIONS.VIEW_FINANCE),
  PortalManagementController.getCfoOverview
);

// ─── SECURITY AUDIT LOGS ───────────────────────────────
router.get(
  '/audit-logs',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_AUDIT_LOGS),
  PortalManagementController.getAuditLogs
);

module.exports = router;
