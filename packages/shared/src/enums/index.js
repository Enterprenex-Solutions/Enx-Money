/**
 * ZeroCarbonix EWMS — Shared Enums (CommonJS + TS)
 */

const Role = {
  DIRECTOR: 'DIRECTOR',
  MANAGER: 'MANAGER',
  EMPLOYEE: 'EMPLOYEE',
  SUPER_ADMIN: 'SUPER_ADMIN',
  COMPANY_ADMIN: 'COMPANY_ADMIN',
  HR_ADMIN: 'HR_ADMIN',
  PROJECT_MANAGER: 'PROJECT_MANAGER',
  TEAM_LEAD: 'TEAM_LEAD',
  INTERN: 'INTERN',
  CLIENT: 'CLIENT',
};

const TaskStatus = {
  BACKLOG: 'BACKLOG',
  ASSIGNED: 'ASSIGNED',
  IN_PROGRESS: 'IN_PROGRESS',
  BLOCKED: 'BLOCKED',
  IN_REVIEW: 'IN_REVIEW',
  CHANGES_REQUIRED: 'CHANGES_REQUIRED',
  APPROVED: 'APPROVED',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
};

const TaskPriority = {
  LOW: 'LOW',
  MEDIUM: 'MEDIUM',
  HIGH: 'HIGH',
  URGENT: 'URGENT',
};

const WorkloadBand = {
  AVAILABLE: 'AVAILABLE',     // < 70%
  HEALTHY: 'HEALTHY',         // 70% - 90%
  HIGH: 'HIGH',               // 91% - 100%
  OVERLOADED: 'OVERLOADED',   // > 100%
};

const AttendanceStatus = {
  PRESENT: 'PRESENT',
  ABSENT: 'ABSENT',
  LATE: 'LATE',
  HALF_DAY: 'HALF_DAY',
  ON_LEAVE: 'ON_LEAVE',
};

const EmploymentType = {
  FULL_TIME: 'FULL_TIME',
  PART_TIME: 'PART_TIME',
  INTERN: 'INTERN',
  CONTRACT: 'CONTRACT',
  FREELANCER: 'FREELANCER',
};

const WorkMode = {
  OFFICE: 'OFFICE',
  REMOTE: 'REMOTE',
  HYBRID: 'HYBRID',
};

const LeaveType = {
  CASUAL: 'CASUAL',
  SICK: 'SICK',
  EARNED: 'EARNED',
  EMERGENCY: 'EMERGENCY',
  UNPAID: 'UNPAID',
  OTHER: 'OTHER',
};

const LeaveStatus = {
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
  CLARIFICATION_REQUESTED: 'CLARIFICATION_REQUESTED',
};

const ProjectStatus = {
  PLANNED: 'PLANNED',
  ACTIVE: 'ACTIVE',
  ON_HOLD: 'ON_HOLD',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
};

const SessionType = {
  WORK: 'WORK',
  BREAK: 'BREAK',
};

const TimesheetStatus = {
  DRAFT: 'DRAFT',
  SUBMITTED: 'SUBMITTED',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
};

const GoalStatus = {
  NOT_STARTED: 'NOT_STARTED',
  IN_PROGRESS: 'IN_PROGRESS',
  ACHIEVED: 'ACHIEVED',
  MISSED: 'MISSED',
};

const ReviewCycle = {
  MONTHLY: 'MONTHLY',
  QUARTERLY: 'QUARTERLY',
  HALF_YEARLY: 'HALF_YEARLY',
  YEARLY: 'YEARLY',
};

const ReviewStatus = {
  DRAFT: 'DRAFT',
  SELF_SUBMITTED: 'SELF_SUBMITTED',
  MANAGER_REVIEWED: 'MANAGER_REVIEWED',
  COMPLETED: 'COMPLETED',
};

const SkillLevel = {
  BEGINNER: 'BEGINNER',
  INTERMEDIATE: 'INTERMEDIATE',
  ADVANCED: 'ADVANCED',
  EXPERT: 'EXPERT',
};

const MeetingStatus = {
  SCHEDULED: 'SCHEDULED',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
};

const DocumentAccess = {
  INTERNAL: 'INTERNAL',
  CONFIDENTIAL: 'CONFIDENTIAL',
  RESTRICTED: 'RESTRICTED',
  PUBLIC: 'PUBLIC',
};

const RiskSeverity = {
  LOW: 'LOW',
  MEDIUM: 'MEDIUM',
  HIGH: 'HIGH',
  CRITICAL: 'CRITICAL',
};

const AutomationTrigger = {
  TASK_OVERDUE: 'TASK_OVERDUE',
  WORKLOAD_EXCEEDED: 'WORKLOAD_EXCEEDED',
  TIMESHEET_DUE: 'TIMESHEET_DUE',
  LEAVE_REQUESTED: 'LEAVE_REQUESTED',
};

module.exports = {
  Role,
  TaskStatus,
  TaskPriority,
  WorkloadBand,
  AttendanceStatus,
  EmploymentType,
  WorkMode,
  LeaveType,
  LeaveStatus,
  ProjectStatus,
  SessionType,
  TimesheetStatus,
  GoalStatus,
  ReviewCycle,
  ReviewStatus,
  SkillLevel,
  MeetingStatus,
  DocumentAccess,
  RiskSeverity,
  AutomationTrigger,
};
