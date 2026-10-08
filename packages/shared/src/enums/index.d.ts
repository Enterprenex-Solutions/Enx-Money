export declare const Role: {
  readonly SUPER_ADMIN: 'SUPER_ADMIN';
  readonly COMPANY_ADMIN: 'COMPANY_ADMIN';
  readonly HR_ADMIN: 'HR_ADMIN';
  readonly PROJECT_MANAGER: 'PROJECT_MANAGER';
  readonly TEAM_LEAD: 'TEAM_LEAD';
  readonly EMPLOYEE: 'EMPLOYEE';
  readonly INTERN: 'INTERN';
  readonly CLIENT: 'CLIENT';
};
export type Role = typeof Role[keyof typeof Role];

export declare const TaskStatus: {
  readonly BACKLOG: 'BACKLOG';
  readonly ASSIGNED: 'ASSIGNED';
  readonly IN_PROGRESS: 'IN_PROGRESS';
  readonly BLOCKED: 'BLOCKED';
  readonly IN_REVIEW: 'IN_REVIEW';
  readonly CHANGES_REQUIRED: 'CHANGES_REQUIRED';
  readonly APPROVED: 'APPROVED';
  readonly COMPLETED: 'COMPLETED';
  readonly CANCELLED: 'CANCELLED';
};
export type TaskStatus = typeof TaskStatus[keyof typeof TaskStatus];

export declare const TaskPriority: {
  readonly LOW: 'LOW';
  readonly MEDIUM: 'MEDIUM';
  readonly HIGH: 'HIGH';
  readonly URGENT: 'URGENT';
};
export type TaskPriority = typeof TaskPriority[keyof typeof TaskPriority];

export declare const WorkloadBand: {
  readonly AVAILABLE: 'AVAILABLE';
  readonly HEALTHY: 'HEALTHY';
  readonly HIGH: 'HIGH';
  readonly OVERLOADED: 'OVERLOADED';
};
export type WorkloadBand = typeof WorkloadBand[keyof typeof WorkloadBand];

export declare const AttendanceStatus: {
  readonly PRESENT: 'PRESENT';
  readonly ABSENT: 'ABSENT';
  readonly LATE: 'LATE';
  readonly HALF_DAY: 'HALF_DAY';
  readonly ON_LEAVE: 'ON_LEAVE';
};
export type AttendanceStatus = typeof AttendanceStatus[keyof typeof AttendanceStatus];

export declare const EmploymentType: {
  readonly FULL_TIME: 'FULL_TIME';
  readonly PART_TIME: 'PART_TIME';
  readonly INTERN: 'INTERN';
  readonly CONTRACT: 'CONTRACT';
  readonly FREELANCER: 'FREELANCER';
};
export type EmploymentType = typeof EmploymentType[keyof typeof EmploymentType];

export declare const WorkMode: {
  readonly OFFICE: 'OFFICE';
  readonly REMOTE: 'REMOTE';
  readonly HYBRID: 'HYBRID';
};
export type WorkMode = typeof WorkMode[keyof typeof WorkMode];

export declare const LeaveType: {
  readonly CASUAL: 'CASUAL';
  readonly SICK: 'SICK';
  readonly EARNED: 'EARNED';
  readonly EMERGENCY: 'EMERGENCY';
  readonly UNPAID: 'UNPAID';
  readonly OTHER: 'OTHER';
};
export type LeaveType = typeof LeaveType[keyof typeof LeaveType];

export declare const LeaveStatus: {
  readonly PENDING: 'PENDING';
  readonly APPROVED: 'APPROVED';
  readonly REJECTED: 'REJECTED';
  readonly CLARIFICATION_REQUESTED: 'CLARIFICATION_REQUESTED';
};
export type LeaveStatus = typeof LeaveStatus[keyof typeof LeaveStatus];

export declare const ProjectStatus: {
  readonly PLANNED: 'PLANNED';
  readonly ACTIVE: 'ACTIVE';
  readonly ON_HOLD: 'ON_HOLD';
  readonly COMPLETED: 'COMPLETED';
  readonly CANCELLED: 'CANCELLED';
};
export type ProjectStatus = typeof ProjectStatus[keyof typeof ProjectStatus];

export declare const SessionType: {
  readonly WORK: 'WORK';
  readonly BREAK: 'BREAK';
};
export type SessionType = typeof SessionType[keyof typeof SessionType];

export declare const TimesheetStatus: {
  readonly DRAFT: 'DRAFT';
  readonly SUBMITTED: 'SUBMITTED';
  readonly APPROVED: 'APPROVED';
  readonly REJECTED: 'REJECTED';
};
export type TimesheetStatus = typeof TimesheetStatus[keyof typeof TimesheetStatus];

export declare const GoalStatus: {
  readonly NOT_STARTED: 'NOT_STARTED';
  readonly IN_PROGRESS: 'IN_PROGRESS';
  readonly ACHIEVED: 'ACHIEVED';
  readonly MISSED: 'MISSED';
};
export type GoalStatus = typeof GoalStatus[keyof typeof GoalStatus];

export declare const ReviewCycle: {
  readonly MONTHLY: 'MONTHLY';
  readonly QUARTERLY: 'QUARTERLY';
  readonly HALF_YEARLY: 'HALF_YEARLY';
  readonly YEARLY: 'YEARLY';
};
export type ReviewCycle = typeof ReviewCycle[keyof typeof ReviewCycle];

export declare const ReviewStatus: {
  readonly DRAFT: 'DRAFT';
  readonly SELF_SUBMITTED: 'SELF_SUBMITTED';
  readonly MANAGER_REVIEWED: 'MANAGER_REVIEWED';
  readonly COMPLETED: 'COMPLETED';
};
export type ReviewStatus = typeof ReviewStatus[keyof typeof ReviewStatus];

export declare const SkillLevel: {
  readonly BEGINNER: 'BEGINNER';
  readonly INTERMEDIATE: 'INTERMEDIATE';
  readonly ADVANCED: 'ADVANCED';
  readonly EXPERT: 'EXPERT';
};
export type SkillLevel = typeof SkillLevel[keyof typeof SkillLevel];

export declare const MeetingStatus: {
  readonly SCHEDULED: 'SCHEDULED';
  readonly IN_PROGRESS: 'IN_PROGRESS';
  readonly COMPLETED: 'COMPLETED';
  readonly CANCELLED: 'CANCELLED';
};
export type MeetingStatus = typeof MeetingStatus[keyof typeof MeetingStatus];

export declare const DocumentAccess: {
  readonly INTERNAL: 'INTERNAL';
  readonly CONFIDENTIAL: 'CONFIDENTIAL';
  readonly RESTRICTED: 'RESTRICTED';
  readonly PUBLIC: 'PUBLIC';
};
export type DocumentAccess = typeof DocumentAccess[keyof typeof DocumentAccess];

export declare const RiskSeverity: {
  readonly LOW: 'LOW';
  readonly MEDIUM: 'MEDIUM';
  readonly HIGH: 'HIGH';
  readonly CRITICAL: 'CRITICAL';
};
export type RiskSeverity = typeof RiskSeverity[keyof typeof RiskSeverity];

export declare const AutomationTrigger: {
  readonly TASK_OVERDUE: 'TASK_OVERDUE';
  readonly WORKLOAD_EXCEEDED: 'WORKLOAD_EXCEEDED';
  readonly TIMESHEET_DUE: 'TIMESHEET_DUE';
  readonly LEAVE_REQUESTED: 'LEAVE_REQUESTED';
};
export type AutomationTrigger = typeof AutomationTrigger[keyof typeof AutomationTrigger];
