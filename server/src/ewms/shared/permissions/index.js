/**
 * ZeroCarbonix EWMS — Permissions and Role-Permission Mappings (CommonJS)
 */

const { Role } = require('../enums');

const Permissions = {
  // Organization & Admin
  ORG_MANAGE: 'org.manage',
  USER_MANAGE: 'user.manage',
  AUDIT_VIEW: 'audit.view',

  // Employees & Profiles
  EMPLOYEE_VIEW: 'employee.view',
  EMPLOYEE_EDIT: 'employee.edit',
  EMPLOYEE_CREATE: 'employee.create',
  SALARY_VIEW: 'salary.view',

  // Projects
  PROJECT_CREATE: 'project.create',
  PROJECT_VIEW: 'project.view',
  PROJECT_EDIT: 'project.edit',
  PROJECT_DELETE: 'project.delete',

  // Tasks
  TASK_CREATE: 'task.create',
  TASK_ASSIGN: 'task.assign',
  TASK_EDIT: 'task.edit',
  TASK_DELETE: 'task.delete',
  TASK_REVIEW: 'task.review',
  TASK_STATUS_UPDATE: 'task.status.update',

  // Time & Attendance
  TIME_TRACK: 'time.track',
  TIMESHEET_APPROVE: 'timesheet.approve',
  ATTENDANCE_VIEW: 'attendance.view',
  ATTENDANCE_MANAGE: 'attendance.manage',

  // Leaves
  LEAVE_REQUEST: 'leave.request',
  LEAVE_APPROVE: 'leave.approve',

  // KPIs & Performance
  KPI_CREATE: 'kpi.create',
  KPI_EVALUATE: 'kpi.evaluate',
  PERFORMANCE_REVIEW: 'performance.review',
  GOALS_MANAGE: 'goals.manage',
  GOALS_VIEW: 'goals.view',

  // Skills
  SKILLS_MANAGE: 'skills.manage',

  // Documents
  DOCUMENT_UPLOAD: 'document.upload',
  DOCUMENT_VIEW: 'document.view',
  DOCUMENT_CONFIDENTIAL_VIEW: 'document.confidential.view',

  // Meetings
  MEETING_MANAGE: 'meeting.manage',
  MEETING_VIEW: 'meeting.view',

  // Workflow Automation
  WORKFLOW_MANAGE: 'workflow.manage',

  // Risks
  RISK_MANAGE: 'risk.manage',

  // Reports
  REPORT_VIEW: 'report.view',
};

const DEFAULT_ROLE_PERMISSIONS = {
  [Role.SUPER_ADMIN]: Object.values(Permissions),

  [Role.COMPANY_ADMIN]: [
    Permissions.ORG_MANAGE,
    Permissions.USER_MANAGE,
    Permissions.AUDIT_VIEW,
    Permissions.EMPLOYEE_VIEW,
    Permissions.EMPLOYEE_EDIT,
    Permissions.EMPLOYEE_CREATE,
    Permissions.SALARY_VIEW,
    Permissions.PROJECT_CREATE,
    Permissions.PROJECT_VIEW,
    Permissions.PROJECT_EDIT,
    Permissions.PROJECT_DELETE,
    Permissions.TASK_CREATE,
    Permissions.TASK_ASSIGN,
    Permissions.TASK_EDIT,
    Permissions.TASK_DELETE,
    Permissions.TASK_REVIEW,
    Permissions.TASK_STATUS_UPDATE,
    Permissions.TIME_TRACK,
    Permissions.TIMESHEET_APPROVE,
    Permissions.ATTENDANCE_VIEW,
    Permissions.ATTENDANCE_MANAGE,
    Permissions.LEAVE_REQUEST,
    Permissions.LEAVE_APPROVE,
    Permissions.KPI_CREATE,
    Permissions.KPI_EVALUATE,
    Permissions.PERFORMANCE_REVIEW,
    Permissions.GOALS_MANAGE,
    Permissions.GOALS_VIEW,
    Permissions.SKILLS_MANAGE,
    Permissions.DOCUMENT_UPLOAD,
    Permissions.DOCUMENT_VIEW,
    Permissions.DOCUMENT_CONFIDENTIAL_VIEW,
    Permissions.MEETING_MANAGE,
    Permissions.MEETING_VIEW,
    Permissions.WORKFLOW_MANAGE,
    Permissions.RISK_MANAGE,
    Permissions.REPORT_VIEW,
  ],

  [Role.HR_ADMIN]: [
    Permissions.EMPLOYEE_VIEW,
    Permissions.EMPLOYEE_EDIT,
    Permissions.EMPLOYEE_CREATE,
    Permissions.SALARY_VIEW,
    Permissions.ATTENDANCE_VIEW,
    Permissions.ATTENDANCE_MANAGE,
    Permissions.LEAVE_REQUEST,
    Permissions.LEAVE_APPROVE,
    Permissions.REPORT_VIEW,
    Permissions.KPI_CREATE,
    Permissions.KPI_EVALUATE,
    Permissions.PERFORMANCE_REVIEW,
    Permissions.GOALS_VIEW,
    Permissions.SKILLS_MANAGE,
    Permissions.DOCUMENT_UPLOAD,
    Permissions.DOCUMENT_VIEW,
    Permissions.DOCUMENT_CONFIDENTIAL_VIEW,
    Permissions.MEETING_VIEW,
  ],

  [Role.PROJECT_MANAGER]: [
    Permissions.EMPLOYEE_VIEW,
    Permissions.PROJECT_CREATE,
    Permissions.PROJECT_VIEW,
    Permissions.PROJECT_EDIT,
    Permissions.TASK_CREATE,
    Permissions.TASK_ASSIGN,
    Permissions.TASK_EDIT,
    Permissions.TASK_DELETE,
    Permissions.TASK_REVIEW,
    Permissions.TASK_STATUS_UPDATE,
    Permissions.TIME_TRACK,
    Permissions.TIMESHEET_APPROVE,
    Permissions.ATTENDANCE_VIEW,
    Permissions.LEAVE_REQUEST,
    Permissions.LEAVE_APPROVE,
    Permissions.KPI_CREATE,
    Permissions.KPI_EVALUATE,
    Permissions.PERFORMANCE_REVIEW,
    Permissions.GOALS_MANAGE,
    Permissions.GOALS_VIEW,
    Permissions.SKILLS_MANAGE,
    Permissions.DOCUMENT_UPLOAD,
    Permissions.DOCUMENT_VIEW,
    Permissions.MEETING_MANAGE,
    Permissions.MEETING_VIEW,
    Permissions.WORKFLOW_MANAGE,
    Permissions.RISK_MANAGE,
    Permissions.REPORT_VIEW,
  ],

  [Role.TEAM_LEAD]: [
    Permissions.EMPLOYEE_VIEW,
    Permissions.PROJECT_VIEW,
    Permissions.TASK_CREATE,
    Permissions.TASK_ASSIGN,
    Permissions.TASK_EDIT,
    Permissions.TASK_REVIEW,
    Permissions.TASK_STATUS_UPDATE,
    Permissions.TIME_TRACK,
    Permissions.TIMESHEET_APPROVE,
    Permissions.ATTENDANCE_VIEW,
    Permissions.LEAVE_REQUEST,
    Permissions.LEAVE_APPROVE,
    Permissions.KPI_EVALUATE,
    Permissions.PERFORMANCE_REVIEW,
    Permissions.GOALS_VIEW,
    Permissions.SKILLS_MANAGE,
    Permissions.DOCUMENT_VIEW,
    Permissions.MEETING_MANAGE,
    Permissions.MEETING_VIEW,
    Permissions.RISK_MANAGE,
    Permissions.REPORT_VIEW,
  ],

  [Role.EMPLOYEE]: [
    Permissions.EMPLOYEE_VIEW,
    Permissions.PROJECT_VIEW,
    Permissions.TASK_STATUS_UPDATE,
    Permissions.TIME_TRACK,
    Permissions.ATTENDANCE_VIEW,
    Permissions.LEAVE_REQUEST,
    Permissions.GOALS_VIEW,
    Permissions.DOCUMENT_VIEW,
    Permissions.MEETING_VIEW,
  ],

  [Role.INTERN]: [
    Permissions.EMPLOYEE_VIEW,
    Permissions.PROJECT_VIEW,
    Permissions.TASK_STATUS_UPDATE,
    Permissions.TIME_TRACK,
    Permissions.ATTENDANCE_VIEW,
    Permissions.LEAVE_REQUEST,
    Permissions.GOALS_VIEW,
    Permissions.DOCUMENT_VIEW,
    Permissions.MEETING_VIEW,
  ],

  [Role.CLIENT]: [
    Permissions.PROJECT_VIEW,
    Permissions.DOCUMENT_VIEW,
  ],
};

module.exports = {
  Permissions,
  DEFAULT_ROLE_PERMISSIONS,
};
