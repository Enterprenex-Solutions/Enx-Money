const { z } = require('zod');
const {
  Role,
  TaskStatus,
  TaskPriority,
  EmploymentType,
  WorkMode,
  LeaveType,
  LeaveStatus,
  DocumentAccess,
  RiskSeverity,
} = require('../enums');

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const CreateEmployeeSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  role: z.nativeEnum(Role),
  departmentId: z.string().uuid().optional(),
  teamId: z.string().uuid().optional(),
  managerId: z.string().uuid().optional(),
  employmentType: z.nativeEnum(EmploymentType).default(EmploymentType.FULL_TIME),
  workMode: z.nativeEnum(WorkMode).default(WorkMode.HYBRID),
  weeklyCapacityHours: z.number().positive().default(40),
  salary: z.number().positive().optional(),
  bankAccount: z.string().optional(),
  taxId: z.string().optional(),
});

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(255),
  description: z.string().optional(),
  projectId: z.string().uuid(),
  assigneeId: z.string().uuid().optional(),
  priority: z.nativeEnum(TaskPriority).default(TaskPriority.MEDIUM),
  estimatedHours: z.number().positive(),
  deadline: z.string().datetime().optional(),
  dependsOnTaskIds: z.array(z.string().uuid()).default([]),
});

const UpdateTaskStatusSchema = z.object({
  status: z.nativeEnum(TaskStatus),
  reason: z.string().optional(),
});

const StartTimeSessionSchema = z.object({
  taskId: z.string().uuid(),
  notes: z.string().optional(),
});

const ClockAttendanceSchema = z.object({
  workMode: z.nativeEnum(WorkMode).default(WorkMode.HYBRID),
  notes: z.string().optional(),
});

// Phase 2 & 3 Schemas
const ApplyLeaveSchema = z.object({
  leaveType: z.nativeEnum(LeaveType),
  startDate: z.string(),
  endDate: z.string(),
  days: z.number().positive().default(1),
  reason: z.string().min(3),
});

const ReviewLeaveSchema = z.object({
  status: z.nativeEnum(LeaveStatus),
  reviewNote: z.string().optional(),
});

const SubmitTimesheetSchema = z.object({
  weekStartDate: z.string(),
  weekEndDate: z.string(),
  notes: z.string().optional(),
});

const CreateObjectiveSchema = z.object({
  title: z.string().min(3),
  description: z.string().optional(),
  level: z.enum(['COMPANY', 'DEPARTMENT', 'EMPLOYEE']).default('EMPLOYEE'),
  targetQuarter: z.string().default('Q4-2026'),
  keyResults: z.array(z.object({
    title: z.string().min(3),
    targetValue: z.number().positive().default(100),
    currentValue: z.number().default(0),
    unit: z.string().default('%'),
  })).default([]),
});

const CreateMeetingSchema = z.object({
  title: z.string().min(3),
  agenda: z.string().optional(),
  startTime: z.string(),
  endTime: z.string(),
  projectId: z.string().uuid().optional(),
  participantIds: z.array(z.string().uuid()).default([]),
});

const CreateActionItemSchema = z.object({
  description: z.string().min(3),
  assigneeId: z.string().uuid().optional(),
  dueDate: z.string().optional(),
});

const CreateDocumentSchema = z.object({
  title: z.string().min(2),
  category: z.string().default('General'),
  accessLevel: z.nativeEnum(DocumentAccess).default(DocumentAccess.INTERNAL),
  fileUrl: z.string().url().optional(),
  projectId: z.string().uuid().optional(),
});

const CreateRiskSchema = z.object({
  projectId: z.string().uuid(),
  title: z.string().min(3),
  severity: z.nativeEnum(RiskSeverity).default(RiskSeverity.MEDIUM),
  probability: z.enum(['LOW', 'MEDIUM', 'HIGH']).default('MEDIUM'),
  impact: z.string().optional(),
  mitigationPlan: z.string().optional(),
});

module.exports = {
  LoginSchema,
  CreateEmployeeSchema,
  CreateTaskSchema,
  UpdateTaskStatusSchema,
  StartTimeSessionSchema,
  ClockAttendanceSchema,
  ApplyLeaveSchema,
  ReviewLeaveSchema,
  SubmitTimesheetSchema,
  CreateObjectiveSchema,
  CreateMeetingSchema,
  CreateActionItemSchema,
  CreateDocumentSchema,
  CreateRiskSchema,
};
