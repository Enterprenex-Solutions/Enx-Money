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
const kpiController = require('./modules/kpi/kpi.controller');
const goalsController = require('./modules/goals/goals.controller');
const leaveController = require('./modules/leave/leave.controller');
const timesheetController = require('./modules/timesheet/timesheet.controller');
const skillsController = require('./modules/skills/skills.controller');
const documentsController = require('./modules/documents/documents.controller');
const meetingsController = require('./modules/meetings/meetings.controller');
const notificationsController = require('./modules/notifications/notifications.controller');
const calendarController = require('./modules/calendar/calendar.controller');
const workflowController = require('./modules/workflow/workflow.controller');
const risksController = require('./modules/risks/risks.controller');

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

  // 11. KPI & Performance (Phase 2)
  api.get('/kpi/templates', authenticateJwt, tenantGuard, kpiController.getTemplates);
  api.get('/kpi/employee/:employeeId?', authenticateJwt, tenantGuard, kpiController.getEmployeeKpis);
  api.post('/kpi/evaluate', authenticateJwt, tenantGuard, requirePermissions(Permissions.KPI_EVALUATE), kpiController.evaluateKpi);

  // 12. Goals & OKRs (Phase 2)
  api.get('/goals', authenticateJwt, tenantGuard, goalsController.list);
  api.post('/goals/objectives', authenticateJwt, tenantGuard, requirePermissions(Permissions.GOALS_MANAGE), goalsController.create);
  api.patch('/goals/key-results/:id', authenticateJwt, tenantGuard, requirePermissions(Permissions.GOALS_MANAGE), goalsController.updateKeyResult);

  // 13. Leave Management (Phase 2)
  api.get('/leave/balance/:employeeId?', authenticateJwt, tenantGuard, leaveController.getBalance);
  api.get('/leave/requests', authenticateJwt, tenantGuard, leaveController.list);
  api.post('/leave/apply', authenticateJwt, tenantGuard, requirePermissions(Permissions.LEAVE_REQUEST), leaveController.apply);
  api.patch('/leave/requests/:id/review', authenticateJwt, tenantGuard, requirePermissions(Permissions.LEAVE_APPROVE), leaveController.review);

  // 14. Timesheets (Phase 2)
  api.get('/timesheets', authenticateJwt, tenantGuard, timesheetController.list);
  api.post('/timesheets/submit', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIME_TRACK), timesheetController.submit);
  api.patch('/timesheets/:id/review', authenticateJwt, tenantGuard, requirePermissions(Permissions.TIMESHEET_APPROVE), timesheetController.review);

  // 15. Skills Matrix (Phase 2)
  api.get('/skills/matrix', authenticateJwt, tenantGuard, skillsController.getMatrix);
  api.post('/skills', authenticateJwt, tenantGuard, skillsController.addOrUpdate);
  api.patch('/skills/:id/verify', authenticateJwt, tenantGuard, requirePermissions(Permissions.SKILLS_MANAGE), skillsController.verify);

  // 16. Documents & Knowledge Base (Phase 3)
  api.get('/documents', authenticateJwt, tenantGuard, requirePermissions(Permissions.DOCUMENT_VIEW), documentsController.list);
  api.post('/documents/upload', authenticateJwt, tenantGuard, requirePermissions(Permissions.DOCUMENT_UPLOAD), documentsController.create);

  // 17. Meetings & Action Items (Phase 3)
  api.get('/meetings', authenticateJwt, tenantGuard, requirePermissions(Permissions.MEETING_VIEW), meetingsController.list);
  api.post('/meetings/schedule', authenticateJwt, tenantGuard, requirePermissions(Permissions.MEETING_MANAGE), meetingsController.create);
  api.post('/meetings/:id/action-items', authenticateJwt, tenantGuard, requirePermissions(Permissions.MEETING_MANAGE), meetingsController.addActionItem);
  api.post('/meetings/:id/action-items/:itemId/convert-to-task', authenticateJwt, tenantGuard, requirePermissions(Permissions.TASK_CREATE), meetingsController.convertActionItemToTask);

  // 18. Notifications (Phase 3)
  api.get('/notifications', authenticateJwt, tenantGuard, notificationsController.list);
  api.patch('/notifications/:id/read', authenticateJwt, tenantGuard, notificationsController.markRead);
  api.post('/notifications/read-all', authenticateJwt, tenantGuard, notificationsController.markAllRead);

  // 19. Calendar Aggregator (Phase 3)
  api.get('/calendar/events', authenticateJwt, tenantGuard, calendarController.getEvents);

  // 20. Workflow Automation (Phase 3)
  api.get('/workflow/rules', authenticateJwt, tenantGuard, workflowController.getRules);
  api.post('/workflow/scan', authenticateJwt, tenantGuard, requirePermissions(Permissions.WORKFLOW_MANAGE), workflowController.runAutomationScan);

  // 21. Project Risks & Health (Phase 3)
  api.get('/risks', authenticateJwt, tenantGuard, requirePermissions(Permissions.PROJECT_VIEW), risksController.list);
  api.post('/risks', authenticateJwt, tenantGuard, requirePermissions(Permissions.RISK_MANAGE), risksController.create);

  app.use('/api/v1', api);

  return app;
}

module.exports = { createApp };
