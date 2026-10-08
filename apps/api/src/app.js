/**
 * ZeroCarbonix EWMS — Modular Monolith Application Assembly
 * Mounts domain modules under /api/v1 with global guards, error handling, and security headers
 */

const express = require('express');
const {
  authenticateJwt,
  requirePermissions,
  tenantGuard,
} = require('./common/guards/auth_rbac.guard');
const { Permissions } = require('../../../packages/shared/src/permissions');

// Domain Controllers
const authController = require('./modules/auth/auth.controller');
const employeesController = require('./modules/employees/employees.controller');
const organizationController = require('./modules/organization/organization.controller');
const projectsController = require('./modules/projects/projects.controller');
const tasksController = require('./modules/tasks/tasks.controller');
const timeController = require('./modules/time/time.controller');
const attendanceController = require('./modules/attendance/attendance.controller');
const reportingController = require('./modules/reporting/reporting.controller');
const auditController = require('./modules/audit/audit.controller');

function createApp() {
  const app = express();

  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // CORS Middleware
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Organization-Id');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
  });

  const api = express.Router();

  // 1. Healthcheck
  api.get('/health', (req, res) => {
    res.json({
      status: 'UP',
      service: 'ZeroCarbonix EWMS Modular Monolith',
      timestamp: new Date().toISOString(),
      architecture: 'NestJS/Express Modular Monolith with PostgreSQL & Redis/BullMQ readiness',
    });
  });

  // 2. Authentication
  api.post('/auth/login', authController.login);
  api.post('/auth/refresh', authController.refresh);
  api.get('/auth/me', authenticateJwt, tenantGuard, authController.me);
  api.post('/auth/logout', authenticateJwt, tenantGuard, authController.logout);

  // 3. Organization & Hierarchy
  api.get('/departments', authenticateJwt, tenantGuard, organizationController.getDepartments);
  api.post('/departments', authenticateJwt, tenantGuard, requirePermissions(Permissions.ORG_MANAGE), organizationController.createDepartment);
  api.get('/teams', authenticateJwt, tenantGuard, organizationController.getTeams);
  api.post('/teams', authenticateJwt, tenantGuard, requirePermissions(Permissions.ORG_MANAGE), organizationController.createTeam);

  // 4. Employees & Directory
  api.get('/employees', authenticateJwt, tenantGuard, requirePermissions(Permissions.EMPLOYEE_VIEW), employeesController.list);
  api.get('/employees/:id', authenticateJwt, tenantGuard, requirePermissions(Permissions.EMPLOYEE_VIEW), employeesController.getById);
  api.post('/employees', authenticateJwt, tenantGuard, requirePermissions(Permissions.EMPLOYEE_CREATE), employeesController.create);

  // 5. Projects
  api.get('/projects', authenticateJwt, tenantGuard, requirePermissions(Permissions.PROJECT_VIEW), projectsController.list);
  api.get('/projects/:id', authenticateJwt, tenantGuard, requirePermissions(Permissions.PROJECT_VIEW), projectsController.getById);
  api.post('/projects', authenticateJwt, tenantGuard, requirePermissions(Permissions.PROJECT_CREATE), projectsController.create);

  // 6. Tasks & Dependencies
  api.get('/tasks', authenticateJwt, tenantGuard, tasksController.list);
  api.get('/tasks/:id', authenticateJwt, tenantGuard, tasksController.getById);
  api.post('/tasks', authenticateJwt, tenantGuard, requirePermissions(Permissions.TASK_CREATE), tasksController.create);
  api.post('/tasks/:id/assign', authenticateJwt, tenantGuard, requirePermissions(Permissions.TASK_ASSIGN), tasksController.assign);
  api.post('/tasks/:id/accept', authenticateJwt, tenantGuard, tasksController.accept);
  api.patch('/tasks/:id/status', authenticateJwt, tenantGuard, requirePermissions(Permissions.TASK_STATUS_UPDATE), tasksController.updateStatus);
  api.get('/tasks/workload/:employeeId', authenticateJwt, tenantGuard, tasksController.checkWorkload);

  // 7. Time Tracking
  api.post('/time/session/start', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), timeController.startSession);
  api.post('/time/session/stop', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), timeController.stopSession);
  api.get('/time/session/active', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), timeController.getActiveSession);
  api.get('/time/summary', authenticateJwt, tenantGuard, timeController.getSummary);

  // 8. Attendance
  api.post('/attendance/clock-in', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), attendanceController.clockIn);
  api.post('/attendance/clock-out', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), attendanceController.clockOut);
  api.get('/attendance/today', authenticateJwt, tenantGuard, attendanceController.getToday);
  api.get('/attendance/roster', authenticateJwt, tenantGuard, requirePermissions(Permissions.ATTENDANCE_VIEW), attendanceController.getRoster);

  // 9. Reporting & Dashboards
  api.get('/reporting/employee', authenticateJwt, tenantGuard, reportingController.getEmployeeDashboard);
  api.get('/reporting/manager', authenticateJwt, tenantGuard, requirePermissions(Permissions.REPORT_VIEW), reportingController.getManagerDashboard);

  // 10. Audit Logs
  api.get('/audit-logs', authenticateJwt, tenantGuard, requirePermissions(Permissions.AUDIT_VIEW), auditController.getLogs);

  app.use('/api/v1', api);

  return app;
}

module.exports = { createApp };
