/**
 * ZeroCarbonix EWMS — Shared Enums (CommonJS + TS)
 */

const Role = {
  SUPER_ADMIN: 'SUPER_ADMIN',
  COMPANY_ADMIN: 'COMPANY_ADMIN',
  HR_ADMIN: 'HR_ADMIN',
  PROJECT_MANAGER: 'PROJECT_MANAGER',
  TEAM_LEAD: 'TEAM_LEAD',
  EMPLOYEE: 'EMPLOYEE',
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
};
