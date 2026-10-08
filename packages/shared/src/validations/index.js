const { z } = require('zod');
const {
  Role,
  TaskStatus,
  TaskPriority,
  EmploymentType,
  WorkMode,
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

module.exports = {
  LoginSchema,
  CreateEmployeeSchema,
  CreateTaskSchema,
  UpdateTaskStatusSchema,
  StartTimeSessionSchema,
  ClockAttendanceSchema,
};
