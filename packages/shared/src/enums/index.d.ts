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
