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

// ─── AUTHENTICATION & SESSIONS ──────────────────────────
router.post('/auth/login', PortalAuthController.login);
router.post('/auth/refresh', PortalAuthController.refresh);
router.get('/auth/me', authenticatePortalToken, PortalAuthController.me);
router.post('/auth/forgot-password', PortalAuthController.forgotPassword);
router.post('/auth/reset-password', PortalAuthController.resetPassword);
router.get('/auth/sessions', authenticatePortalToken, PortalAuthController.getSessions);
router.post('/auth/sessions/revoke', authenticatePortalToken, PortalAuthController.revokeSession);
router.get('/auth/login-history', authenticatePortalToken, PortalAuthController.getLoginHistory);
router.post('/auth/logout', PortalAuthController.logout);

// ─── USER & RBAC MANAGEMENT ─────────────────────────────
router.get(
  '/users',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR),
  PortalManagementController.getUsers
);

router.post(
  '/users',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN),
  PortalManagementController.createUser
);

router.patch(
  '/users/:id',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN),
  PortalManagementController.updateUser
);

router.delete(
  '/users/:id',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN),
  PortalManagementController.deleteUser
);

router.get(
  '/roles',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO),
  PortalManagementController.getRoles
);

router.patch(
  '/roles/:role/permissions',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN),
  PortalManagementController.updateRolePermissions
);

router.get(
  '/permissions',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO),
  PortalManagementController.getPermissions
);

// ─── HR & EMPLOYEE DIRECTORY ────────────────────────────
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

// ─── DEPARTMENTS & DESIGNATIONS ─────────────────────────
router.get(
  '/departments',
  authenticatePortalToken,
  PortalManagementController.getDepartments
);

router.post(
  '/departments',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR),
  PortalManagementController.createDepartment
);

router.get(
  '/designations',
  authenticatePortalToken,
  PortalManagementController.getDesignations
);

router.post(
  '/designations',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR),
  PortalManagementController.createDesignation
);

// ─── ONBOARDING & OFFBOARDING ───────────────────────────
router.get(
  '/onboarding',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR),
  PortalManagementController.getOnboarding
);

router.post(
  '/onboarding',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR),
  PortalManagementController.createOnboarding
);

router.patch(
  '/onboarding/:id/step',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR),
  PortalManagementController.advanceOnboardingStep
);

router.get(
  '/offboarding',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR),
  PortalManagementController.getOffboarding
);

router.post(
  '/offboarding',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR),
  PortalManagementController.createOffboarding
);

router.patch(
  '/offboarding/:id/step',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR, ROLES.MANAGER),
  PortalManagementController.advanceOffboardingStep
);

// ─── ATTENDANCE & LEAVES ────────────────────────────────
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

router.get(
  '/attendance/calendar',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_ATTENDANCE),
  PortalManagementController.getAttendanceCalendar
);

router.get(
  '/leave-types',
  authenticatePortalToken,
  PortalManagementController.getLeaveTypes
);

router.post(
  '/leave-types',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.HR),
  PortalManagementController.createLeaveType
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

// ─── TASKS & KANBAN ─────────────────────────────────────
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

router.patch(
  '/tasks/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.EDIT_TASK),
  PortalManagementController.updateTaskStatus
);

// ─── PROJECTS & MILESTONES ──────────────────────────────
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

router.patch(
  '/projects/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.EDIT_PROJECT),
  PortalManagementController.updateEmployee // fallback or project update
);

router.get(
  '/milestones',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_PROJECTS),
  PortalManagementController.getMilestones
);

router.post(
  '/milestones',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CREATE_PROJECT),
  PortalManagementController.createMilestone
);

router.patch(
  '/milestones/:id',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.EDIT_PROJECT),
  PortalManagementController.updateMilestone
);

// ─── TIME TRACKING ──────────────────────────────────────
router.post(
  '/time-tracking/start',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.TRACK_TIME),
  PortalManagementController.startTimeTracking
);

router.post(
  '/time-tracking/stop',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.TRACK_TIME),
  PortalManagementController.stopTimeTracking
);

router.get(
  '/time-tracking/summary',
  authenticatePortalToken,
  PortalManagementController.getTimeTrackingSummary
);

// ─── DOCUMENTS VAULT ────────────────────────────────────
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

// ─── KPIS & PERFORMANCE ─────────────────────────────────
router.get(
  '/kpis',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_KPIS),
  PortalManagementController.getKpis
);

router.post(
  '/kpis',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.MANAGE_KPIS),
  PortalManagementController.createKpi
);

router.get(
  '/goals',
  authenticatePortalToken,
  PortalManagementController.getGoals
);

router.post(
  '/goals',
  authenticatePortalToken,
  PortalManagementController.createGoal
);

router.get(
  '/performance/reviews',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_PERFORMANCE),
  PortalManagementController.getPerformanceReviews
);

router.post(
  '/performance/reviews',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.MANAGE_PERFORMANCE),
  PortalManagementController.createPerformanceReview
);

// ─── ANNOUNCEMENTS & NOTIFICATIONS ──────────────────────
router.get(
  '/announcements',
  authenticatePortalToken,
  PortalManagementController.getAnnouncements
);

router.post(
  '/announcements',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CREATE_ANNOUNCEMENT),
  PortalManagementController.createAnnouncement
);

router.get(
  '/notifications',
  authenticatePortalToken,
  PortalManagementController.getNotifications
);

router.patch(
  '/notifications/:id/read',
  authenticatePortalToken,
  PortalManagementController.markNotificationRead
);

// ─── CLIENT PORTAL (STRICT ISOLATION) ───────────────────
router.get(
  '/client/projects',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CLIENT_ACCESS),
  PortalManagementController.getClientProjects
);

router.get(
  '/client/tasks',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CLIENT_ACCESS),
  PortalManagementController.getClientTasks
);

router.get(
  '/client/documents',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.CLIENT_ACCESS),
  PortalManagementController.getClientDocuments
);

// ─── ANALYTICS & EXECUTIVE COCKPITS ─────────────────────
router.get(
  '/analytics/company',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_ANALYTICS),
  PortalManagementController.getCompanyAnalytics
);

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

// ─── SUPER ADMIN SETTINGS & AUDIT LOGS ──────────────────
router.get(
  '/admin/settings',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN, ROLES.CEO),
  PortalManagementController.getSettings
);

router.patch(
  '/admin/settings',
  authenticatePortalToken,
  requireRole(ROLES.SUPER_ADMIN),
  PortalManagementController.updateSettings
);

router.get(
  '/audit-logs',
  authenticatePortalToken,
  requirePermission(PERMISSIONS.VIEW_AUDIT_LOGS),
  PortalManagementController.getAuditLogs
);

module.exports = router;
